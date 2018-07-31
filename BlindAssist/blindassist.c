//
//  blindassist.c
//  BlindAssist
//
//  Created by Giovanni Terlingen on 31-07-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

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
    "bycycle"
};

/**
 * Analyses a frame and pushes it to the results.
 *
 * @param channels an array with size (h * w) of the segmented image
 * @param height the height of the segmented image
 * @param width the width of the segmented image
 * @return 0 on success, or negative on failure
 */
int analyse_frame(uint8_t *channels, int height, int width) {
    return 0;
}

/**
 * Generates a human readable (and speakable) sentence of the analyzed frames
 *
 * @return a string on success, or NULL when there is no result available (yet).
 */
char* get_results_sentence(void) {
    return NULL;
}
