#ifndef _TRACK_H_
#define _TRACK_H_

#include <genesis.h>

#define ROAD_START_LINE 144 
#define ZMAP_LENGTH 80 

#define POS_DATA_LEN 383 
const fastfix16 total_road_length = FASTFIX16( 19.190000 );
const fastfix16 data_step_size = FASTFIX16( 0.050000 );

extern s16 scroll_data[];
extern u16 pos_to_scroll_data_offset[];
extern fastfix16 pos_to_bg_dx[];

#endif // _TRACK_H_
