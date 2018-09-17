//
//  ViewController.mm
//  BlindAssist
//
//  Created by Giovanni Terlingen on 27-03-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import <CoreML/CoreML.h>

#import "cityscapes.h"
#import "ViewController.h"
#import "Utils.h"

#include <queue>
#include <mutex>

// These values need to match the model's dimensions
const int input_width = 384;
const int input_height = 384;
const int output_channels = 19;

@implementation ViewController

// Used for queuing segmentation results for rendering
std::vector<uint8_t*> queue;
std::mutex queue_mutex;

// Current 3d scene view's dimensions
int scene_width;
int scene_height;

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

- (void)viewDidAppear:(BOOL)animated {
    scene_width = self.cameraPreview.bounds.size.width;
    scene_height = self.cameraPreview.bounds.size.height;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:(BOOL)animated];
    [self.cameraPreview.session pause];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        scene_width = self.cameraPreview.bounds.size.width;
        scene_height = self.cameraPreview.bounds.size.height;
    }];
}

-(void)handlePrediction:(VNRequest*)request :(NSError*)error {
    NSArray *results = [request.results copy];
    MLMultiArray *multiArray = ((VNCoreMLFeatureValueObservation*)(results[0])).featureValue.multiArrayValue;
    
    // Holds the temporary maxima, and its index (only works if less than 256 channels!)
    double *tmax = (double*) malloc(input_width * input_height * sizeof(double));
    uint8_t* tchan = (uint8_t*) malloc(input_width * input_height);
    
    double *pointer = (double*) multiArray.dataPointer;
    
    int cStride = multiArray.strides[0].intValue;
    int hStride = multiArray.strides[1].intValue;
    int wStride = multiArray.strides[2].intValue;
    
    // Just copy the first channel as starting point
    for (int h = 0; h < input_height; h++) {
        for (int w = 0; w < input_width; w++) {
            tmax[w + h * input_width] = pointer[h * hStride + w * wStride];
            tchan[w + h * input_width] = 0; // first channel
        }
    }
    
    // We skip first channel on purpose.
    for (int c = 1; c < output_channels; c++) {
        for (int h = 0; h < input_height; h++) {
            for (int w = 0; w < input_width; w++) {
                double sample = pointer[h * hStride + w * wStride + c * cStride];
                if (sample > tmax[w + h * input_width]) {
                    tmax[w + h * input_width] = sample;
                    tchan[w + h * input_width] = c;
                }
            }
        }
    }
    
    // Now free the maximum buffer, useless
    free(tmax);
    
    /**
    // Holds the segmented image
    uint8_t *bytes = (uint8_t*) malloc(width * height * 4);
    
    // Calculate image color
    for (int i = 0; i < height * width; i++) {
        struct Color rgb = colors[tchan[i]];
        bytes[i * 4 + 0] = (rgb.r);
        bytes[i * 4 + 1] = (rgb.g);
        bytes[i * 4 + 2] = (rgb.b);
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
    **/
    
    std::lock_guard<std::mutex> lock(queue_mutex);
    queue.insert(queue.begin(), tchan);
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
        
        float size = 0.1f;
        SCNBox *box = [SCNBox boxWithWidth:size height:size length:size chamferRadius:0.0f];
        
        SCNNode *node = [SCNNode nodeWithGeometry:box];
        node.position = SCNVector3FromFloat3(cloud.points[i]);
       
        // Determine the class
        SCNVector3 projectedPoint = [renderer projectPoint:node.position];

        // Map the coordinates of the point to the segmented image
        float scaleFactorX = (float) input_width / (float) scene_width;
        float scaleFactorY = (float) input_height / (float) scene_height;
        
        int x = projectedPoint.x * scaleFactorX;
        int y = projectedPoint.y * scaleFactorY;
        
        std::lock_guard<std::mutex> lock(queue_mutex);
        if (queue.empty()) {
            return;
        }
        
        int index = x + y * input_width;
        if (index <= 0 || index >= input_width * input_height) {
            return;
        }
        
        uint8_t* tchan = (uint8_t*) queue.front();
        int c = tchan[index];
        
        struct Color rgb = colors[c];
        
        // Update the color
        box.firstMaterial.diffuse.contents = [UIColor colorWithRed:rgb.r/255.0f green:rgb.g/255.0f blue:rgb.b/255.0f alpha:1.0f];
        
        [self.cameraPreview.scene.rootNode addChildNode:node];
        
        /**
        // Remove rendudant nodes
        while (self.cameraPreview.scene.rootNode.childNodes.count > 256) {
            SCNNode *nodeToDelete = self.cameraPreview.scene.rootNode.childNodes[0];
            [nodeToDelete removeFromParentNode];
        }
        **/

        queue.pop_back();
    }
}

@end
