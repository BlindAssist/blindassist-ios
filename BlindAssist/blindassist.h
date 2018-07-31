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

int analyse_frame(uint8_t *channels, int height, int width);

char* get_results_sentence(void);

#endif /* blindassist_h */
