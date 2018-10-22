//
//  Inference.h
//  BlindAssist
//
//  Created by Giovanni Terlingen on 22/10/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Vision/Vision.h>

#import "blindassist.h"

struct Color {
    uint8_t r;
    uint8_t g;
    uint8_t b;
};

static struct Color colors[] = {
    {.r = 128, .g = 64,  .b = 128}, // road
    {.r = 244, .g = 35,  .b = 232}, // sidewalk
    {.r = 70,  .g = 70,  .b = 70 }, // building
    {.r = 102, .g = 102, .b = 156}, // wall
    {.r = 190, .g = 153, .b = 153}, // fence
    {.r = 153, .g = 153, .b = 153}, // pole
    {.r = 250, .g = 170, .b = 30 }, // traffic light
    {.r = 220, .g = 220, .b = 0  }, // traffic sign
    {.r = 107, .g = 142, .b = 35 }, // vegetation
    {.r = 152, .g = 251, .b = 152}, // terrain
    {.r = 70,  .g = 130, .b = 180}, // sky
    {.r = 220, .g = 20,  .b = 60 }, // person
    {.r = 255, .g = 0,   .b = 0  }, // rider
    {.r = 0,   .g = 0,   .b = 142}, // car
    {.r = 0,   .g = 0,   .b = 70 }, // truck
    {.r = 0,   .g = 60,  .b = 100}, // bus
    {.r = 0,   .g = 80,  .b = 100}, // train
    {.r = 0,   .g = 0,   .b = 230}, // motorcycle
    {.r = 119, .g = 11,  .b = 32 }  // bycycle
};

@interface Inference : NSObject

+(int) handlePrediction:(VNRequest*)request :(UIImageView*)predictionView :(scene_information*)information;

@end
