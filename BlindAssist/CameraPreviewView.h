//
//  CameraPreviewView.h
//  BlindAssist
//
//  Created by Giovanni Terlingen on 27-03-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#ifndef BLINDASSIST_CAMERA_PREVIEW_VIEW_H
#define BLINDASSIST_CAMERA_PREVIEW_VIEW_H

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface CameraPreviewView : UIView

@property (weak) AVCaptureVideoPreviewLayer *previewLayer;

- (void)awakeFromNib;

- (void)addCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer*) previewLayer;

- (void)layoutSubviews;

- (void)orientationChanged:(NSNotification*) notification;

@end

#endif // BLINDASSIST_CAMERA_PREVIEW_VIEW_H
