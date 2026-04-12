#ifndef _PLACE_TILES_H_
#define _PLACE_TILES_H_

#include <genesis.h>

typedef struct 
{
  fix16 x;
  fix16 sx;
  fix16 t;
  fix16 dt;
  fix16 st;
  s16 show;
  s16 dir;
} TREE_TRUNK;


/*
 * dest is start of output buffer in bytes
 * 
 * source is start of input buffer in bytes
 *
 * lastTilePixel : Sega Tiles are 8 pixels wide, but 4 bits make a pixel
 *  so a byte is two pixels wide. Last Tile Pixel tells us where the last 
 *  nonzero pixel is: 
 *    Pixel 0 or 1 will copy first two pixels of a tile ( byte)
 *    Pixel 2 or 3 will copy first 4 pixels ( 2 bytes )
 *    Pixel 5 or 6 will copy first 6 pixels ( 3 bytes )
 *    Pixel 7 or 8 will copy all 8 pixels of a tile (all bytes)
 * 
 * tiles : is the number of 8-pixel width tiles to move
 *
 *
 * */

void draw_tiles(u32* dest, const u32* source, s16 startPixel, s16 lastTilePixel, s16 tiles );

#endif  // _PLACE_TILES_H_
