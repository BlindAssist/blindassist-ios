//
//  blindassist.h
//  BlindAssist
//
//  Created by Giovanni Terlingen on 31-07-18.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#ifndef blindassist_h
#define blindassist_h

#include <stdint.h>

#define SUCCESS 0

enum walk_positions {
    LEFT,
    RIGHT,
    FRONT,
    NONE
};

struct scene_information {
    
    /**
     * Defines the position where a user can walk.
     */
    enum walk_positions walk_position;
    
    /**
     * Defines wether there were poles detected in the environment.
     */
    int poles_detected;
    
    /**
     * Defines if there are obstacles in front.
     */
    int vehicle_detected;
    int bikes_detected;
};

typedef struct scene_information scene_information;

int analyse_frame(uint8_t *classes, int height, int width);

int poll_results(scene_information *information);

#endif /* blindassist_h */
