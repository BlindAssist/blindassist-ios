//
//  ViewController.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 27-03-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import <CoreML/CoreML.h>
#import "cityscapes.h"

#include "ViewController.h"

#define CHANNELS 19 // Cityscapes dataset has 19 classes
#define FRAMES_TO_CHECK 30 // Defines how much frames needs to be scanned to speak out a result

// Holds scores
unsigned long *scores[2];
// Calculates scanned frames
unsigned frame = 0;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTts:[[AVSpeechSynthesizer alloc] init]];
    [self speak:@"Initializing application"];
    
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
    unsigned channels = multiArray.shape[0].intValue;
    unsigned height = multiArray.shape[1].intValue;
    unsigned width = multiArray.shape[2].intValue;
    
    // Holds the temporary maxima, and its index (only works if less than 256 channels!)
    double *tmax = (double*) malloc(width * height * sizeof(double));
    uint8_t *tchan = (uint8_t*) malloc(width * height);
    
    double *pointer = (double*) multiArray.dataPointer;
    
    unsigned cStride = multiArray.strides[0].intValue;
    unsigned hStride = multiArray.strides[1].intValue;
    unsigned wStride = multiArray.strides[2].intValue;
    
    // Just copy the first channel as starting point
    for (unsigned h = 0; h < height; h++) {
        for (unsigned w = 0; w < width; w++) {
            tmax[w + h * width] = pointer[h * hStride + w * wStride];
            tchan[w + h * width] = 0; // first channel
        }
    }
    
    // We skip first channel on purpose.
    for (unsigned c = 1; c < channels; c++) {
        for (unsigned h = 0; h < height; h++) {
            for (unsigned w = 0; w < width; w++) {
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
    uint8_t *bytes = (uint8_t*)malloc(width*height*4);
    
    if (*scores == NULL) {
        // 0 and 1 stands for left and right. We increment each score for each channel.
        scores[0] = (unsigned long *)malloc(CHANNELS * sizeof(unsigned long));
        scores[1] = (unsigned long *)malloc(CHANNELS * sizeof(unsigned long));
    }
    
    // Calculate image color
    for (unsigned i = 0; i < height * width; i++) {
        BOOL isRight = (i % height) > width / 2;
        scores[isRight][tchan[i]] += 1;
        
        struct Color rgba = colors[tchan[i]];
        bytes[i * 4 + 0] = (rgba.r);
        bytes[i * 4 + 1] = (rgba.g);
        bytes[i * 4 + 2] = (rgba.b);
        bytes[i * 4 + 3] = (255 / 2); // semi transparent
    }
    
    // Scanned the frame, update count
    frame++;
    
    if (frame >= FRAMES_TO_CHECK) {
        
        unsigned highestClassLeft = 0;
        unsigned long highestClassScoreLeft = 0;
        
        // Calculate the highest results for left
        for (unsigned i = 0; i < CHANNELS; i++) {
            if (scores[0][i] > highestClassScoreLeft) {
                highestClassScoreLeft = scores[0][i];
                highestClassLeft = i;
            }
        }
        
        unsigned highestClassRight = 0;
        unsigned long highestClassScoreRight = 0;
        
        // Calculate the highest results for right
        for (unsigned i = 0; i < CHANNELS; i++) {
            if (scores[1][i] > highestClassScoreRight) {
                highestClassScoreRight = scores[1][i];
                highestClassRight = i;
            }
        }
        
        free(*scores);
        *scores = NULL;
        
        // Speak the results out loud
        [self speak:@"Left"];
        [self speak:[NSString stringWithUTF8String:classNames[highestClassLeft]]];
        
        [self speak:@"Right"];
        [self speak:[NSString stringWithUTF8String:classNames[highestClassRight]]];
        
        frame = 0;
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

@end
