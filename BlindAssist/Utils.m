//
//  Utils.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 03-04-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#include "Utils.h"
#import <UIKit/UIKit.h>

@implementation Utils

+(AVCaptureVideoOrientation) getVideoOrientation {
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
