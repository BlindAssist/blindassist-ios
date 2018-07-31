//
//  blindassist.c
//  BlindAssist
//
//  Created by Giovanni Terlingen on 31-07-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#include <stdio.h>

#include "blindassist.h"

/*
 * This code is responsible for analyzing predicted frames and generate a suitable
 * explaination of them for the blind user.
 */

/**
 * Contains the human readable names of classes. Ordered by index.
 */
static char* class_names[] = {
    "road",
    "sidewalk",
    "building",
    "wall",
    "fence",
    "pole",
    "traffic light",
    "traffic sign",
    "vegetation",
    "terrain",
    "sky",
    "person",
    "rider",
    "car",
    "truck",
    "bus",
    "train",
    "motorcycle",
    "bicycle"
};

enum classes {
    ROAD,
    SIDEWALK,
    BUILDING,
    WALL,
    FENCE,
    POLE,
    TRAFFIC_LIGHT,
    TRAFFIC_SIGN,
    VEGETATION,
    TERRAIN,
    SKY,
    PERSON,
    RIDER,
    CAR,
    TRUCK,
    BUS,
    TRAIN,
    MOTORCYCLE,
    BICYCLE
};

/**
 * The minimal percent of sidewalk/terrain a half frame needs to contain to consider as 'safe' to walk
 **/
static const int MINIMAL_PERCENT = 10;

/**
 * The amount of frames which needs to be analyzed to predict a result
 **/
static const int FRAMES_TO_ANALYZE = 30;

/**
 * Defines scores for the best position to walk.
 */
unsigned left_walk_score = 0;
unsigned right_walk_score = 0;

/**
 * The amount of frames which are currently analyzed.
 * Gets reset after a result has been predicted
 */
int current_analyzed_frames = 0;

/**
 * Analyses a frame and pushes it to the results.
 *
 * @param classes an array with size (h * w) of the segmented image, each pixel defines a class
 * @param height the height of the segmented image
 * @param width the width of the segmented image
 * @return 0 on success, or negative on failure
 */
int analyse_frame(uint8_t *classes, int height, int width) {
    
    unsigned local_left_walk_score = 0;
    unsigned local_right_walk_score = 0;
    
    // Loop through each pixel and get the class
    for (unsigned i = 0; i < height * width; i++) {
        int isLeft = i % height <= width / 2;
        int class = classes[i];
        // sidewalk or terrain (safe to walk on)
        if (class == SIDEWALK || class == TERRAIN) {
            isLeft ? local_left_walk_score++ : local_right_walk_score++;
        }
    }
    
    if (local_left_walk_score > local_right_walk_score) {
        float percent = (local_left_walk_score / ((height * width) / 2.0f)) * 100.0f;
        if (percent >= MINIMAL_PERCENT) {
            // It's safe to walk here
            left_walk_score++;
        }
    } else {
        float percent = (local_right_walk_score / ((height * width) / 2.0f)) * 100.0f;
        if (percent >= MINIMAL_PERCENT) {
            // It's safe to walk here
            right_walk_score++;
        }
    }
    
    current_analyzed_frames++;
    
    return 0;
}

/**
 * Generates a human readable (and speakable) sentence of the analyzed frames
 *
 * @return a string on success, or NULL when there is no result available (yet).
 */
char* get_results_sentence(void) {
    
    char* result = NULL;
    
    if (current_analyzed_frames >= FRAMES_TO_ANALYZE) {
        if (left_walk_score > 0 || right_walk_score > 0) {
            if (left_walk_score > right_walk_score) {
                result = "You can walk on the left\n";
            } else {
                result = "You can walk on the right\n";
            }
        }
        // reset values
        current_analyzed_frames = 0;
        left_walk_score = 0;
        right_walk_score = 0;
    }
    
    return result;
}
