#ifndef _TRACK_H_
#define _TRACK_H_

#include <genesis.h>

#define ROAD_START_LINE 144 
#define ZMAP_LENGTH 80 

// data for getting track position to lookup positions
// total positions used for lookups
#define POS_DATA_LEN 317 
// total length of all segment lengths from track editor
const fastfix16 total_road_length = FASTFIX16( 47.619141 );
//  step size used by script to calculate scrolling data along track
//  use with POS_DATA_LENGTH
const fastfix16 hscroll_data_step_size = FASTFIX16( 0.150000 );

// horizontal scrolling offsets for use with 
// VDP_setHorizontalScrollLine()
extern const s16 hscroll_offsets[];
// points to start of horizontal scrolling offsets 
extern const u16 pos_to_hscroll_offsets_index[];
// rate of change for background for current position.
extern const fix16 pos_to_bg_dx[];

// zmap 
extern const fastfix16 zmap[ZMAP_LENGTH];
// scale values for rows/Ys 
extern const fastfix16 scale_for_y[ZMAP_LENGTH];

#endif // _TRACK_H_
