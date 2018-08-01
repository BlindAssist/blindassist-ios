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
static const int MINIMAL_WALKABLE_PERCENT = 10;

/**
 * The minimal percent of poles a frame needs to contain to be considered as dangerous
 **/
static const int MINIMAL_POLE_PERCENT = 5;


/**
 * The amount of frames which needs to be analyzed to predict a result
 **/
static const int FRAMES_TO_ANALYZE = 30;

/**
 * Defines scores for the best position to walk.
 */
int left_walk_score = 0;
int right_walk_score = 0;

int obstacle_score = 0;

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
    
    int local_left_walk_score = 0;
    int local_right_walk_score = 0;
    int local_obstacle_score = 0;
    
    // Loop through each pixel and get the class
    for (int i = 0; i < height * width; i++) {
        int isLeft = i % height <= width / 2;
        int class = classes[i];
        // sidewalk or terrain (safe to walk on)
        if (class == SIDEWALK || class == TERRAIN) {
            isLeft ? local_left_walk_score++ : local_right_walk_score++;
        } else if (class == POLE) {
            local_obstacle_score++;
        }
    }
    
    if (local_left_walk_score > local_right_walk_score) {
        float percent = (local_left_walk_score / ((height * width) / 2.0f)) * 100.0f;
        if (percent >= MINIMAL_WALKABLE_PERCENT) {
            // It's safe to walk here
            left_walk_score++;
        }
    } else {
        float percent = (local_right_walk_score / ((height * width) / 2.0f)) * 100.0f;
        if (percent >= MINIMAL_WALKABLE_PERCENT) {
            // It's safe to walk here
            right_walk_score++;
        }
    }
    
    float percent = (local_obstacle_score / ((float)(height * width))) * 100.0f;
    if (percent > MINIMAL_POLE_PERCENT) {
        // There is clearly an obstacle detected
        obstacle_score++;
    }
    
    current_analyzed_frames++;
    
    return SUCCESS;
}

/**
 * Generates a scene information of the analyzed frames
 */
int poll_results(scene_information *information) {
    
    if (current_analyzed_frames >= FRAMES_TO_ANALYZE) {
        if (left_walk_score > 0 || right_walk_score > 0) {
            if (left_walk_score > right_walk_score) {
                information->walk_position = LEFT;
            } else {
                information->walk_position = RIGHT;
            }
        } else {
            information->walk_position = NONE;
        }
        if (obstacle_score > 0) {
            information->obstacles = 1;
        }
        
        // reset values
        current_analyzed_frames = 0;
        left_walk_score = 0;
        right_walk_score = 0;
        obstacle_score = 0;
        
        return SUCCESS;
    }
    
    return -1;
}
