//
//  ViewController.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 27-03-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import <CoreML/CoreML.h>

#import "cityscapes.h"
#import "ViewController.h"

#include "blindassist.h"

static const NSTimeInterval GravityCheckInterval = 5.0;

BOOL IsFacingHorizon = true;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTts:[[AVSpeechSynthesizer alloc] init]];
    [self speak:@"Initializing application"];
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = GravityCheckInterval;
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMDeviceMotion *motionData, NSError *error) {
                                        [self handleGravity:motionData.gravity];
                                    }];
    
    VNCoreMLModel *model = [VNCoreMLModel modelForMLModel: [[[cityscapes alloc] init] model] error:nil];
    [self setRequest:[[VNCoreMLRequest alloc] initWithModel:model completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        [self handlePrediction:request :error];
    }]];
    [self request].imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop;
    
    [self speak:@"Finished loading, detecting environment"];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            [self permissions:granted];
        }
    }];
}

-(void)permissions:(BOOL)granted {
    if (granted && [self session] == nil) {
        [self setupSession];
    }
}

-(void)setupSession {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)];
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session addInput:input];
    [session addOutput:output];
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self cameraPreview] addCaptureVideoPreviewLayer:previewLayer];
    });
    
    [self setSession:session];
    [[self session] startRunning];
}

-(void)deviceOrientationDidChange {
    for (AVCaptureOutput *output in [self session].outputs) {
        for (AVCaptureConnection *connection in output.connections) {
            connection.videoOrientation = [Utils getVideoOrientation];
        }
    }
}

-(void)handlePrediction:(VNRequest*)request :(NSError*)error {
    NSArray *results = [request.results copy];
    MLMultiArray *multiArray = ((VNCoreMLFeatureValueObservation*)(results[0])).featureValue.multiArrayValue;
    
    // Shape of MLMultiArray is sequence: channels, height and width
    int channels = multiArray.shape[0].intValue;
    int height = multiArray.shape[1].intValue;
    int width = multiArray.shape[2].intValue;
    
    // Holds the temporary maxima, and its index (only works if less than 256 channels!)
    double *tmax = (double*) malloc(width * height * sizeof(double));
    uint8_t *tchan = (uint8_t*) malloc(width * height);
    
    double *pointer = (double*) multiArray.dataPointer;
    
    int cStride = multiArray.strides[0].intValue;
    int hStride = multiArray.strides[1].intValue;
    int wStride = multiArray.strides[2].intValue;
    
    // Just copy the first channel as starting point
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
            tmax[w + h * width] = pointer[h * hStride + w * wStride];
            tchan[w + h * width] = 0; // first channel
        }
    }
    
    // We skip first channel on purpose.
    for (int c = 1; c < channels; c++) {
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                double sample = pointer[h * hStride + w * wStride + c * cStride];
                if (sample > tmax[w + h * width]) {
                    tmax[w + h * width] = sample;
                    tchan[w + h * width] = c;
                }
            }
        }
    }
    
    // Now free the maximum buffer, useless
    free(tmax);
    
    // Holds the segmented image
    uint8_t *bytes = (uint8_t*) malloc(width * height * 4);
    
    // Calculate image color
    for (int i = 0; i < height * width; i++) {
        struct Color rgba = colors[tchan[i]];
        bytes[i * 4 + 0] = (rgba.r);
        bytes[i * 4 + 1] = (rgba.g);
        bytes[i * 4 + 2] = (rgba.b);
        bytes[i * 4 + 3] = (255 / 2); // semi transparent
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bytes, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast);
    CFRelease(colorSpace);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:0 orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self predictionView] setImage:image];
    });
    
    free(bytes);
    
    if (IsFacingHorizon) {
        // predict results for this frame
        analyse_frame(tchan, height, width);
        
        scene_information information = {};
        int result = poll_results(&information);
        
        if (result == SUCCESS) {
            if (information.walk_position == FRONT) {
                [self speak:@"You can walk in front of you."];
            } else if (information.walk_position == LEFT) {
                [self speak:@"Walk left."];
            } else if (information.walk_position == RIGHT) {
                [self speak:@"Walk right."];
            }
            if (information.obstacles > 0) {
                [self speak:@"Warning: poles detected."];
            }
        }
    }
    
    // Free t buffer
    free(tchan);
}

-(void)speak:(NSString*) string  {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:string];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
    [[self tts] speakUtterance:utterance];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [self deviceOrientationDidChange];
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!pixelBuffer) {
        return;
    }
    
    NSMutableDictionary<VNImageOption, id> *requestOptions = [NSMutableDictionary dictionary];
    CFTypeRef cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil);
    requestOptions[VNImageOptionCameraIntrinsics] = (__bridge id)(cameraIntrinsicData);
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer options:requestOptions];
    
    [handler performRequests:@[[self request]] error:nil];
}

-(void)handleGravity:(CMAcceleration)gravity
{
    IsFacingHorizon = gravity.y <= -0.97f && gravity.y <= 1.0f;
    
    if (!IsFacingHorizon) {
        // TODO: Make some beep for this
        [self speak:@"Warning: camera is not facing the horizon."];
    }
}

@end
