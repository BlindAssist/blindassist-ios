//
//  Utils.h
//  BlindAssist
//
//  Created by Giovanni Terlingen on 03-04-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#ifndef BLINDASSIST_UTILS_H
#define BLINDASSIST_UTILS_H

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject

+(AVCaptureVideoOrientation) getVideoOrientation;

@end

#endif // BLINDASSIST_UTILS_H
