//
//  ViewController.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 27-03-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#include "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self predictionView].transform = CGAffineTransformScale([self predictionView].transform, -1, 1);
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
    
    // Shape of MLMultiArray is sequence length, batch, channels, height and width
    uint8_t channels = multiArray.shape[2].intValue;
    uint8_t height = multiArray.shape[3].intValue;
    uint8_t width = multiArray.shape[4].intValue;
    
    // Holds the segmented image
    uint8_t bytes [height * width * 4];
    
    double *pointer = (double*) multiArray.dataPointer;
    
    uint32_t cStride = multiArray.strides[2].intValue;
    uint16_t hStride = multiArray.strides[3].intValue;
    uint8_t wStride = multiArray.strides[4].intValue;
    
    for (uint16_t h = 0; h < height; h++) {
        for (uint16_t w = 0; w < width; w++) {
            uint8_t highestClass = 0;
            double highest = -DBL_MAX;
            for (uint8_t c = 0; c < channels; c++) {
                uint32_t offset = c * cStride + h * hStride + w * wStride;
                double score = pointer[offset];
                if (score > highest) {
                    highestClass = c;
                    highest = score;
                }
            }
            uint32_t offset = h * width * 4 + w * 4;
            struct Color rgba = colors[highestClass];
            bytes[offset + 0] = (rgba.r);
            bytes[offset + 1] = (rgba.g);
            bytes[offset + 2] = (rgba.b);
            bytes[offset + 3] = (255 / 2); // semi transparent
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bytes, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast);
    CFRelease(colorSpace);
    //free(bytes);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:0 orientation:UIImageOrientationUpMirrored];
    CGImageRelease(cgImage);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self predictionView] setImage:image];
    });
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
