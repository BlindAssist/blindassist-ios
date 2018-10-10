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
 * 
 * This code will retrieve segmented images using analyse_frame,
 * everytime this method is called, a calculation will be done for the best walkable
 * position for the blind user. 
 * 
 * There are also checks performed to detect obstacles such as poles within the scene.
 * 
 * Before a predicition is made, several frames are analysed to guarantee a better
 * understanding of scene.
 * 
 * This code is using ratios. Each part of a frame needs to contain a certain
 * amount of class pixels to make sure it represents the actual object in real life.
 * 
 * After calculation is done, a client can retrieve the results using poll_results.
 */

/**
 * The name of classes ordered by their index
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
 * The minimal amount of sidewalk/terrain a frame needs to contain to
 * consider as 'safe' to walk
 **/
static const float MINIMAL_WALKABLE_RATIO = 0.1f;

/**
 * The minimal amount of poles a frame needs to contain to be considered as dangerous
 **/
static const float MINIMAL_POLE_RATIO = 0.05f;

/**
 * The minimal amount of a vehicle the frame needs to contain
 * to be considered as dangerous
 **/
static const float MINIMAL_VEHICLE_RATIO = 0.4f;

/**
 * The minimal amount of a bike the frame needs to contain to
 * be considered as dangerous
 **/
static const float MINIMAL_BIKE_RATIO = 0.2f;

/**
 * The amount of frames which needs to be analyzed before predicting a result
 **/
static const int FRAMES_TO_ANALYZE = 5;

/**
 * Defines scores for the best position to walk.
 */
int left_walk_score = 0;
int right_walk_score = 0;
int center_walk_score = 0;

/**
 * These values will increment once a car/bike is detected in the
 * a frame. They must cover a certain part of the frame
 * to consider it as dangerous.
 */
int vehicles_score = 0;
int bikes_score = 0;

/**
 * Will increment if poles are detected in the environment.
 */
int poles_score = 0;

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
    int local_center_walk_score = 0;
    
    int local_vehicle_score = 0;
    int local_bike_score = 0;
    
    int local_obstacle_score = 0;
    
    // Loop through each pixel and get the class
    for (int i = 0; i < height * width; i++) {
        int w = i % height;
        int isLeft = w <= width / 2;
        int isCenter = w >= width / 3 && w <= (width / 3) * 2;
        
        int class = classes[i];
        // sidewalk or terrain (safe to walk on)
        if (class == SIDEWALK || class == TERRAIN) {
            if (isCenter) {
                local_center_walk_score++;
            }
            isLeft ? local_left_walk_score++ : local_right_walk_score++;
        } else if (class == POLE) {
            local_obstacle_score++;
        } else if (class == CAR || class == TRUCK) {
            // TODO: WHAT TO DO WITH A BUS OR TRAIN?
            local_vehicle_score++;
        } else if (class == BICYCLE || class == MOTORCYCLE) {
            local_bike_score++;
        }
    }
    
    // We divide h * w by 2 in the following calculations.
    // This is due left/right/center detection.
    
    if (local_left_walk_score > local_right_walk_score) {
        float leftWalkRatio = (local_left_walk_score / ((height * width) / 2.0f));
        if (leftWalkRatio >= MINIMAL_WALKABLE_RATIO) {
            // It's safe to walk here
            left_walk_score++;
        }
    } else {
        float rightWalkRatio = (local_right_walk_score / ((height * width) / 2.0f));
        if (rightWalkRatio >= MINIMAL_WALKABLE_RATIO) {
            // It's safe to walk here
            right_walk_score++;
        }
    }
    
    float centerWalkRatio = (local_center_walk_score / ((height * width) / 2.0f));
    if (centerWalkRatio >= MINIMAL_WALKABLE_RATIO) {
        // It's safe to walk here
        center_walk_score++;
    }
    
    float poleRatio = (local_obstacle_score / ((float)(height * width)));
    if (poleRatio > MINIMAL_POLE_RATIO) {
        // There are clearly poles detected
        poles_score++;
    }
    
    float vehiclesRatio = (local_vehicle_score / ((float)(height * width)));
    if (vehiclesRatio > MINIMAL_VEHICLE_RATIO) {
        // There is clearly a car in the front detected
        vehicles_score++;
    }
    
    float bikeRatio = (local_bike_score / ((float)(height * width)));
    if (bikeRatio > MINIMAL_BIKE_RATIO) {
        // There are some bikes in front of the user
        bikes_score++;
    }
    
    current_analyzed_frames++;
    
    return SUCCESS;
}

/**
 * Generates a scene information of the analyzed frames
 */
int poll_results(scene_information *information) {
    
    if (current_analyzed_frames >= FRAMES_TO_ANALYZE) {
        if (center_walk_score > 0) {
            information->walk_position = FRONT;
        } else if (left_walk_score > 0 || right_walk_score > 0) {
            if (left_walk_score > right_walk_score) {
                information->walk_position = LEFT;
            } else {
                information->walk_position = RIGHT;
            }
        } else {
            information->walk_position = NONE;
        }
        if (poles_score > 0) {
            information->poles_detected = 1;
        }
        if (vehicles_score > 0) {
            information->vehicle_detected = 1;
        }
        if (bikes_score > 0) {
            information->bikes_detected = 1;
        }
        
        // reset values
        current_analyzed_frames = 0;
        left_walk_score = 0;
        right_walk_score = 0;
        center_walk_score = 0;
        
        vehicles_score = 0;
        bikes_score = 0;
        poles_score = 0;
        
        return SUCCESS;
    }
    
    return -1;
}
