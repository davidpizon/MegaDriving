#include <genesis.h>
#include "resources.h"

#include "grass.h"
#include "track.h"
#include "track_map.h"


#define VERTICAL_REZ 224  // number of lines in the screen.

// A is 512 wide, so no need to offset it
#define SCROLL_CENTER_A -96
// OTOH back ground B is 512 wide  (512-320)/2 = -96
#define SCROLL_CENTER_B -96

fastfix16 zmap[ZMAP_LENGTH];

#define SKY_HEIGHT 144

/*
http://www.extentofthejam.com/pseudo/A

Perspective-style Steering
It's much less interesting looking to have a game in which when you steer, it
only moves the car sprite. So, instead of moving the player's car sprite, you
keep it in the center of the screen and move the road-- more importantly, you
move the position of the center-line at the front (bottom) of the screen. Now,    <<< centerLine
you want to assume that the player is going to be looking at the road always, so
make the road end at the center of the screen. You'll need an angle-of-road             <<< angleOfRoad
variable for this. So, calculate the difference between the center of the screen
and the position of the front of the road, and divide by the height of the
road's graphic. That will give you the amount to move the center of the road
each line.
*/
fix16 centerLine = FIX16(160); // center line at the front (bottom) of the screen
fix16 angleOfRoad[ZMAP_LENGTH];
s16 turning = 0;
fix16 steeringDir = FIX16(0);
extern fastfix16 perspective_step_from_centerline[];


// speed the 'vehicle' moves through the road
fastfix16 speed = FASTFIX16(0.00);

// Horizontal scrolling values
s16 HscrollA[ZMAP_LENGTH];
s16 HscrollB[VERTICAL_REZ];

// position variables.
u16 pos = 0;
u16 map_pos = 0;
//fastfix16 position = FASTFIX16(0); // keep track fo the segment position onscreen
fix16 background_position = FIX16(SCROLL_CENTER_B); // handle background X position


// Sprites
struct CP_SPRITE
{
  Sprite *sprite;
  fix16 pos_x;
  fix16 pos_y;
  fix16 zpos; // track position along the road. start it at the farthest on background - 12.5
  u8 update_y;
};
struct CP_SPRITE carSprite;


void updateScrolling()
{
    // scroll the road
    u16 offset = pos_to_hscroll_offsets_index[pos];
    //memcpy( HscrollA, hscroll_offsets + offset, 158 );
    // loop through scroll data and add on the perspective steer
    #pragma GCC unroll 80
    for (u16 y = 0; y < ZMAP_LENGTH; y++ )
    {
        //HscrollA[y] = hscroll_offsets[offset+y] + SCROLL_CENTER_A + F16_toInt( angleOfRoad[y] );  // TODO: can probably bake-in scroll center 
        HscrollA[y] = hscroll_offsets[offset+y] + F16_toInt( angleOfRoad[y] );  // SCROLL_CENTER_A is baked in by godot script
    }

    // scroll the background
    background_position = background_position +  pos_to_bg_dx[pos];
    s16 bgs = F16_toInt( background_position );

    //#pragma unroll
    #pragma GCC unroll 20
    for (u16 y = 48; y < SKY_HEIGHT; y++ )
    {
        HscrollB[y] = bgs;
    }
}
 

static void joypadHandler(u16 joypadId, u16 changed, u16 state)
{
    if (joypadId == JOY_1)
    {
        if (state & BUTTON_LEFT)
        {
            turning = -1; // turn left
        }
        else if (state & BUTTON_RIGHT)
        {
            turning = 1; // turn right
        }
        else
        {
            turning = 0; // not turning.
        }
    }

}

void updatePlayer() {
    // handle turning
    if (turning == 1)
    {
        steeringDir = steeringDir + FIX16(0.3);
        if (steeringDir > FIX16(16))
        {
            steeringDir = FIX16(16);
        }
    }
    else if (turning == -1)
    {
        steeringDir = steeringDir - FIX16(0.3);
        if (steeringDir < FIX16(-16))
        {
            steeringDir = FIX16(-16);
        }
    }
    else
    {
        // pull back to center
        if (steeringDir < FIX16(0.0))
        {
            steeringDir = steeringDir + FIX16(0.15);
            if (steeringDir > FIX16(0.0))
            {
                steeringDir = FIX16(0.0);
            }
        }
        else if (steeringDir > FIX16(0.0))
        {
            steeringDir = steeringDir - FIX16(0.15);
            if (steeringDir < FIX16(0.0))
            {
                steeringDir = FIX16(0.0);
            }
        }
    }


    // set frame based on steeringDir as long as we're moving forward.
    // LEFT
    if (steeringDir < FIX16(-12.00))
    {
        SPR_setAnim(carSprite.sprite, 3);
        SPR_setHFlip(carSprite.sprite,0);
    }
    else if (steeringDir < FIX16(-6.0))
    {
        SPR_setAnim(carSprite.sprite, 2);
        SPR_setHFlip(carSprite.sprite,0);
    }
    else if (steeringDir < FIX16(-0.02))
    {
        SPR_setAnim(carSprite.sprite, 1);
				SPR_setHFlip(carSprite.sprite,0);
    }
		// RIGHT
    else if (steeringDir > FIX16(12.0))
    {
        SPR_setAnim(carSprite.sprite, 3);
        SPR_setHFlip(carSprite.sprite,1);
    }
    else if (steeringDir > FIX16(6.0))
    {
        SPR_setAnim(carSprite.sprite, 2);
        SPR_setHFlip(carSprite.sprite,1);
    }
    else if (steeringDir > FIX16(0.02))
    {
        SPR_setAnim(carSprite.sprite, 1);
        SPR_setHFlip(carSprite.sprite,1);

    }
    else
    {
        // centered
        SPR_setAnim(carSprite.sprite, 0);
        SPR_setHFlip(carSprite.sprite,0);
    }


    // start shifting the road based on speed, steeringDir and road DX


    // >> So, instead of moving the player's car sprite, you keep it in the center of the
    // >> screen and move the road-- more importantly, **YOU MOVE THE POSITION OF THE
    // >> CENTER-LINE AT THE FRONT (BOTTOM) OF THE SCREEN**. Now, you want to assume that
    // >> the player is going to be looking at the road always, SO MAKE THE ROAD END AT
    // >> THE CENTER OF THE SCREEN. You'll need an angle-of-road variable for this. So,
    // >> CALCULATE THE DIFFERENCE BETWEEN THE CENTER OF THE SCREEN AND THE POSITION OF
    // >> THE FRONT (BOTTOM) OF THE ROAD, and DIVIDE BY THE HEIGHT OF THE ROAD'S GRAPHIC. That
    // >> will give you the amount to move the center of the road each line.


    // >>  variable for this. So, calculate the difference between the center of the screen
    // >>  and the position of the front of the road, and divide by the height of the
    // >>  road's graphic. That will give you the amount to move the center of the road
    // >>  each line.
    if (turning != 0)
    {
        //KLog_F1("steeringDir: ", steeringDir);
        centerLine = centerLine - steeringDir;

				// Limit how far the car can move to the side
				if (centerLine > FIX16(323))
				{
					centerLine = FIX16(323);
				}
				else if (centerLine < FIX16(-4))
				{
					centerLine = FIX16(-4);
				}

				// update angleOfRoad for perspective steering.
				//        fastfix32 step = FF32_div((centerLine - FASTFIX32(160)), // calc diff between center and position at front
				//                FASTFIX32(ZMAP_LENGTH));              // divide by the height of the road graphic. (DIV overflow with FF32)
				//
				fix16 step = perspective_step_from_centerline[ F16_toInt(centerLine) + 4 ];   //work around division overflow with LUT.

				fix16 current = FASTFIX16(0);
				#pragma GCC unroll 80
				for (u16 i =0; i < ZMAP_LENGTH; ++i ) 
				{
					angleOfRoad[i] = current;
					current = current + step;
				}
		}

}

int main(bool arg)
{


    //////////////////////////////////////////////////////////////
    // VDP basic setup
    VDP_setBackgroundColor(16);
    VDP_setScreenWidth320();

    //////////////////////////////////////////////////////////////
    // initialize scrolling values to the center of the image.
    VDP_setScrollingMode(HSCROLL_LINE, VSCROLL_PLANE);
    for (int i = 0; i < ZMAP_LENGTH; i++)
    {
        HscrollA[i] = SCROLL_CENTER_A;
        angleOfRoad[i] = FASTFIX16( 0.000 );
    }
    for (int i = 0; i < 40; i++)
    {
        HscrollB[i] = 0;
    }
    for (int i = 48; i < VERTICAL_REZ; i++)
    {
        HscrollB[i] = SCROLL_CENTER_B;
    }



    //////////////////////////////////////////////////////////////////////
    // setup palettes
    PAL_setPalette( PAL0, road_images_pal.data, CPU );
    PAL_setPalette( PAL1, car_pal.data, CPU);
    PAL_setPalette( PAL2, power_pal.data, CPU);



    //////////////////////////////////////////////////////////////////////
    // setup road
    int ind = TILE_USER_INDEX;
    int roadIndex = ind;
    // Load the plane tiles into VRAM
    VDP_loadTileSet(road_images.tileset, ind, CPU);


    // setup the tiles
    VDP_setTileMapEx(BG_A, road_images.tilemap, TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, roadIndex),
            12,               // Plane X destination
            18 ,             // plane Y destination
            12,               // Region X start position
            0,               // Region Y start position
            40, // width  (went with 64 becasue default width is 64.  Viewable screen is 40)
            10,             // height
            CPU);

    //////////////////////////////////////////////////////////////////////
    // setup sky
    s16 skyIndex = roadIndex + road_images.tileset->numTile;
    VDP_drawImageEx(BG_B, &bg, TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, skyIndex), 0, 0, FALSE, TRUE);
 
    //////////////////////////////////////////////////////////////////////
    // Load the grass into VRAM with VDP_loadTileData
    s16 grassIndex = skyIndex + bg.tileset->numTile;
    u32 grassColumn[80]; // 10 rows in the column * 8 rows per tile is 80 elements.
    memset(grassColumn, 0, sizeof(grassColumn));
    memcpy(grassColumn, grass, sizeof(grassColumn) ); //sizeof(grassColumn)); // copy the column data into ram
    VDP_loadTileData((const u32 *)grassColumn,       // tile data pointer
            grassIndex,                    // index
            10,                          // number of tiles to load
            DMA_QUEUE                    // transfer method
            );

    for (u16 x = 0; x < 40; ++x)
    {
        // make a column out of it.
        VDP_fillTileMapRectInc(BG_B,
                TILE_ATTR_FULL(PAL0,      // Palette
                    0,         // Priority
                    0,         // Flip Vertical
                    0,         // FLip Horizontal
                    grassIndex), // tile index
                x,                        // x
                18,                       // y
                1,                        // width
                10                         // height (10 tiles)
                );
    }

    //s16 offset = 1;
    s16 frame = 0;
    s16 frame_offset = 0;
    s16 delay = 0;



    //////////////////////////////////////////////////////////////
    // Setup Sprites
    SPR_init();
    carSprite.sprite = NULL;
    carSprite.pos_x = FIX16(132.0); 
    carSprite.pos_y = FIX16(186.0);
    carSprite.sprite = SPR_addSprite(&car, // Sprite name defined in resources
            F16_toInt(carSprite.pos_x), // starting X position
            F16_toInt(carSprite.pos_y), // starting Y position
            TILE_ATTR(PAL1,              // specify palette
                1,                 // Tile priority ( with background)
                FALSE,             // flip the sprite vertically?
                FALSE              // flip the sprite horizontally
                ));
    SPR_setAnim(carSprite.sprite, 3);
    SPR_setHFlip(carSprite.sprite, 1);


    Sprite *marker_sprite = SPR_addSprite(&markers,   // Sprite name defined in resources
            -32, 
            -32,
            TILE_ATTR(PAL1,              // specify palette
                1,                 // Tile priority ( with background)
                FALSE,             // flip the sprite vertically?
                FALSE              // flip the sprite horizontally
                ));
    SPR_setFrame(marker_sprite, 0);

    // set speed through z
    // speed = FASTFIX16(-0.1);


    // Asynchronous joystick handler.
    JOY_init();
    JOY_setEventHandler(joypadHandler);

    while(TRUE) {

        updatePlayer();
          
        ///////////////////////////////////////////////////////
        // update scrolling values
        updateScrolling();


        ///////////////////////////////////////////////////////
        // update the grass col data
        memcpy(grassColumn, grass[frame],  sizeof(grassColumn ));
        VDP_loadTileData((const u32 *)grassColumn, // tile data pointer
                grassIndex,              // index
                10,                     // number of tiles to load
                DMA_QUEUE              // transfer method
                );
        delay +=1;
        if( delay > 2 ) {
            delay = 0;
            frame += 1;
            frame_offset += 10;
            if (frame > 5)
            {
                frame = 0;
                frame_offset = 0;
            }
            pos++;
            map_pos += 2;
            SPR_setPosition(marker_sprite, map_path[ map_pos]-4, map_path[ map_pos+1]-4);
        }
        if( pos >= POS_DATA_LEN ) {
            pos = 0;
            map_pos = 0;
        }


        // Draw car at now position
        SPR_setPosition(carSprite.sprite, F16_toInt(carSprite.pos_x), F16_toInt(carSprite.pos_y));
        SPR_update();


        ///////////////////////////////////////////////////////
        // Handle forward motion
        // naive approach? blast the entire rect, does look ok.
        VDP_setTileMapEx(BG_A, road_images.tilemap, TILE_ATTR_FULL(PAL0, FALSE, FALSE, FALSE, roadIndex),
                12,               // Plane X destination
                18,//27,             // plane Y destination
                12,               // Region X start position
                frame_offset,
                40, // width  (went with 64 becasue default width is 64.  Viewable screen is 40)
                10, // 1,             // height
                DMA_QUEUE);

        // curve the road with horizontal scrolling.
        VDP_setHorizontalScrollLine(BG_A, ROAD_START_LINE, HscrollA, ZMAP_LENGTH, DMA_QUEUE); // TODO: scroll the bottom 80 lines instead of the entire VERTICAL_REZ
        VDP_setHorizontalScrollLine(BG_B, 0, HscrollB, SKY_HEIGHT, DMA_QUEUE);
        SYS_doVBlankProcess();
    }

}

