//
//  CameraPreviewView.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 27-03-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "CameraPreviewView.h"

@implementation CameraPreviewView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Observe device rotation
     [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(orientationChanged:)
      name:UIDeviceOrientationDidChangeNotification
      object:[UIDevice currentDevice]];
}

// Insert layer at index 0
- (void)addCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer*) previewLayer {
    [_previewLayer removeFromSuperlayer];
    [[self layer] insertSublayer:previewLayer atIndex:0];
    _previewLayer = previewLayer;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _previewLayer.frame = [super bounds];
}

// Change video orientation to always display video in correct orientation
- (void)orientationChanged:(NSNotification*) notification {
    _previewLayer.connection.videoOrientation = [self getVideoOrientation];
}

- (AVCaptureVideoOrientation) getVideoOrientation {
    AVCaptureVideoOrientation orientation;
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    return orientation;
}

@end
