//
//  Inference.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 22/10/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

/**
 * We keep this class in Objective-C, since performance is critical,
 * the same exact code was tested on Swift and was significantly
 * slower compared to this implementation.
 */

#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>

#import "Inference.h"

@implementation Inference

+(int) handlePrediction:(VNRequest*)request :(UIImageView*)predictionView :(scene_information*) information {
    NSArray *results = [request.results copy];
    MLMultiArray *multiArray = ((VNCoreMLFeatureValueObservation*)(results[0])).featureValue.multiArrayValue;
    
    // Shape of MLMultiArray is sequence: channels, height and width
    int channels = multiArray.shape[0].intValue;
    int height = multiArray.shape[1].intValue;
    int width = multiArray.shape[2].intValue;
    
    // Holds the temporary maxima, and its index (only works if less than 256 channels!)
    double *tmax = (double*) malloc(width * height * sizeof(double));
    uint8_t *tchan = (uint8_t*) malloc(width * height);
    
    double *pointer = (double*) multiArray.dataPointer;
    
    int cStride = multiArray.strides[0].intValue;
    int hStride = multiArray.strides[1].intValue;
    int wStride = multiArray.strides[2].intValue;
    
    // Just copy the first channel as starting point
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
            tmax[w + h * width] = pointer[h * hStride + w * wStride];
            tchan[w + h * width] = 0; // first channel
        }
    }
    
    // We skip first channel on purpose.
    for (int c = 1; c < channels; c++) {
        for (int h = 0; h < height; h++) {
            for (int w = 0; w < width; w++) {
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
    uint8_t *bytes = (uint8_t*) malloc(width * height * 4);
    
    // Calculate image color
    for (int i = 0; i < height * width; i++) {
        struct Color rgba = colors[tchan[i]];
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
        [predictionView setImage:image];
    });
    
    free(bytes);
    
    // predict results for this frame
    analyse_frame(tchan, height, width);
    
    free(tchan);
    
    return poll_results(information);
}

@end
