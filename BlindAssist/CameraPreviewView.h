//
//  CameraPreviewView.h
//  BlindAssist
//
//  Created by Giovanni Terlingen on 27-03-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CameraPreviewView : UIView

@property (weak) AVCaptureVideoPreviewLayer *previewLayer;

- (void)awakeFromNib;

- (void)addCaptureVideoPreviewLayer:(AVCaptureVideoPreviewLayer*) previewLayer;

- (void)layoutSubviews;

- (void)orientationChanged:(NSNotification*) notification;

- (AVCaptureVideoOrientation)getVideoOrientation;

@end
