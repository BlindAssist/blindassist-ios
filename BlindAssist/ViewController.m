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
#import "Utils.h"

@implementation ViewController

int currentChannelMapWidth;
int currentChannelMapHeight;
uint8_t *currentChannelMap;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setTts:[[AVSpeechSynthesizer alloc] init]];
    [self speak:@"Initializing application"];
    
    self.cameraPreview.delegate = self;
    self.cameraPreview.showsStatistics = YES;
    //self.cameraPreview.debugOptions = ARSCNDebugOptionShowFeaturePoints;
    
    SCNScene *scene = [SCNScene scene];
    self.cameraPreview.scene = scene;
    
    VNCoreMLModel *model = [VNCoreMLModel modelForMLModel: [[[cityscapes alloc] init] model] error:nil];
    [self setRequest:[[VNCoreMLRequest alloc] initWithModel:model completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        [self handlePrediction:request :error];
    }]];
    [self request].imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop;
    
    [self speak:@"Finished loading, detecting environment"];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:(BOOL)animated];
    
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    configuration.planeDetection = ARPlaneDetectionNone;
    
    [self.cameraPreview.session runWithConfiguration:configuration];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:(BOOL)animated];
    [self.cameraPreview.session pause];
}

-(void)handlePrediction:(VNRequest*)request :(NSError*)error {
    NSArray *results = [request.results copy];
    MLMultiArray *multiArray = ((VNCoreMLFeatureValueObservation*)(results[0])).featureValue.multiArrayValue;
    
    // Shape of MLMultiArray is sequence: channels, height and width
    int channels = multiArray.shape[0].intValue;
    int height = multiArray.shape[1].intValue;
    int width = multiArray.shape[2].intValue;
    
    currentChannelMapWidth= width;
    currentChannelMapHeight = height;
    
    // Holds the temporary maxima, and its index (only works if less than 256 channels!)
    double *tmax = (double*) malloc(width * height * sizeof(double));
    
    if (currentChannelMap == nil) {
        currentChannelMap = (uint8_t*) malloc(width * height);
    }
    
    double *pointer = (double*) multiArray.dataPointer;
    
    int cStride = multiArray.strides[0].intValue;
    int hStride = multiArray.strides[1].intValue;
    int wStride = multiArray.strides[2].intValue;
    
    // Just copy the first channel as starting point
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
            tmax[w + h * width] = pointer[h * hStride + w * wStride];
            currentChannelMap[w + h * width] = 0; // first channel
        }
    }
    
    // We skip first channel on purpose.
    for (int c = 1; c < channels; c++) {
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
                double sample = pointer[h * hStride + w * wStride + c * cStride];
                if (sample > tmax[w + h * width]) {
                    tmax[w + h * width] = sample;
                    currentChannelMap[w + h * width] = c;
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
        struct Color rgba = colors[currentChannelMap[i]];
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
    
    // Free t buffer
    //free(tchan);
}

-(void)speak:(NSString*) string  {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:string];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
    utterance.rate = AVSpeechUtteranceMaximumSpeechRate * 0.60;
    [[self tts] speakUtterance:utterance];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)captureOutput {
    ARFrame *frame = self.cameraPreview.session.currentFrame;
    CVPixelBufferRef pixelBuffer = frame.capturedImage;
    
    CGImagePropertyOrientation deviceOrientation = [Utils getOrientation];
    NSMutableDictionary<VNImageOption, id> *requestOptions = [NSMutableDictionary dictionary];
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer orientation:deviceOrientation options:requestOptions];
    
    [handler performRequests:@[[self request]] error:nil];
}

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time {
    [self captureOutput];
    
    ARFrame *frame = self.cameraPreview.session.currentFrame;
    ARPointCloud *cloud = frame.rawFeaturePoints;
    SCNNode *root = self.cameraPreview.scene.rootNode;
    NSArray<SCNNode *> *nodes = root.childNodes;
    
    for (int i = 0; i < cloud.count; i++) {
        BOOL addNode = YES;
        
        // Check if node was already added
        for (int j = 0; j < nodes.count; j++) {
            SCNNode *currentNode = nodes[j];
            SCNVector3 cloudPosition = SCNVector3FromFloat3(cloud.points[i]);
            if (SCNVector3EqualToVector3(currentNode.position, cloudPosition)) {
                // Node already found at location, skip adding
                addNode = NO;
                break;
            }
        }
        
        if (!addNode) {
            continue;
        }
        
        SCNSphere *sphere = [[SCNSphere alloc] init];
        sphere.radius = 0.001f;
       
        SCNNode *node = [SCNNode nodeWithGeometry:sphere];
        node.position = SCNVector3FromFloat3(cloud.points[i]);
       
        // Determine the class
        SCNVector3 projectedPoint = [renderer projectPoint:node.position];
        float sceneWidth = self.cameraPreview.bounds.size.width;
        float sceneHeight = self.cameraPreview.bounds.size.height;
        
        // Map the coordinates of the point to the segmented image
        float scaleFactorX = sceneWidth / currentChannelMapWidth;
        float scaleFactorY = sceneHeight / currentChannelMapHeight;
        
        int x = projectedPoint.x * scaleFactorX;
        int y = projectedPoint.y * scaleFactorY;
        
        printf("Found channel %d\n", currentChannelMap[x * y]);
        int class = currentChannelMap[x * y];
        struct Color rgba = colors[class];
        
        // Update the color
        sphere.firstMaterial.diffuse.contents = [UIColor colorWithRed:rgba.r green:rgba.g blue:rgba.b alpha:255];
        
        [self.cameraPreview.scene.rootNode addChildNode:node];
        
        // Remove rendudant nodes
        while (self.cameraPreview.scene.rootNode.childNodes.count > 100) {
            SCNNode *nodeToDelete = self.cameraPreview.scene.rootNode.childNodes[0];
            [nodeToDelete removeFromParentNode];
            printf("Node removed\n");
        }
    }
}

@end
