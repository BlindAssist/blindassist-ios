//
//  Utils.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 03-04-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Utils.h"

@implementation Utils

+(CGImagePropertyOrientation) getOrientation {
    CGImagePropertyOrientation orientation;
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            orientation = kCGImagePropertyOrientationRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = kCGImagePropertyOrientationLeft;
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientation = kCGImagePropertyOrientationUp;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = kCGImagePropertyOrientationDown;
            break;
        default:
            orientation = kCGImagePropertyOrientationRight;
            break;
    }
    return orientation;
}

@end
