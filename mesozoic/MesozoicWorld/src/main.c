#include <genesis.h>
#include "resources.h"
#include "rotation.h"


#include "ground.h"
#include "trunk.h"
#include "draw_tiles.h"

#define ROWS 224
#define SCROLL_CENTER -96
#define COLS 20
#define TRUNK_ROW_WIDTH 64
#define GROUND_COL_HEIGHT 10


#define TREE_COUNT 6
TREE_TRUNK trees[TREE_COUNT];
s16 sortedTreeIndex[TREE_COUNT];
fix16 treeX[20];

// scroll buffers
static s16 HscrollA[ROWS];
static s16 VscrollA[COLS];
static s16 VscrollBLower[COLS];
static s16 VscrollBUpper[COLS];
static s16 HscrollB[ROWS];
static s16 VscrollB[COLS];

/////////////////////////////////////////////////////////////////////
//  Menacer Lookup Values
//
static s16 xLookup[ 256 ];  // 256 full range for JOY_readJoypadX() 

// calculate screen position for menacer X values
static void calculateXLookup() {
    // T2
    // $70-$83   :  112-131   : Total hvals 20
    // $84-$B6; $E5-$FF; $00-$42  :  132-182; 229-255; 0-66   :  51; 27; 67  -> only 51+27+66 = 145 hvals
    // $43-$6F   : 67-111  : 45 hvals
    //  there's only 210 havls total with many offscreen
    //  The active area is 290 < 320 pixels.
    // since I'm going to bother with a calibration step  and offset I will use arbitray values
    //  in the lookup
    //
    //  My own experience has puts 84  the left edge of the monitor, so I'll start with 60
    s16 pos = -40;
    for( int i=60; i < 183; ++i ) {
        xLookup[i] =  pos;
        pos =  pos + 2;
    }
    for( int i=229; i < 256; ++i ) {
        xLookup[i] =  pos;
        pos = pos + 2;
    }
    for( int i=0; i < 60; ++i ) {
        xLookup[i] =  pos;
        pos = pos + 2;
    }

}


void setupTrees() {
    // 
    treeX[0] = FIX16(1.8);
    for( int i=1; i < 20; ++i  ){
        treeX[i] = treeX[i-1] + FIX16(0.35);
    }

    // setup Tree values
    trees[0].x = FIX16(380);
    trees[0].sx = FIX16(380);
    trees[0].t = FIX16(18);
    trees[0].st = FIX16(18);
    trees[0].dt = FIX16(1.0);
    trees[0].show = 1;
    trees[0].dir = -1;

    trees[1].x = FIX16(420);
    trees[1].sx = FIX16(420);
    trees[1].t = FIX16(14);
    trees[1].st = FIX16(14);
    trees[1].dt = FIX16(0.5);
    trees[1].show = 1;
    trees[1].dir = -1;

    trees[2].x = FIX16(430);
    trees[2].sx = FIX16(430);
    trees[2].t = FIX16(7);
    trees[2].st = FIX16(16);
    trees[2].dt = FIX16(0.5);
    trees[2].show = 1;
    trees[2].dir = -1;

    trees[3].x = FIX16(130);
    trees[3].sx = FIX16(130);
    trees[3].t = FIX16(3);
    trees[3].st = FIX16(11);
    trees[3].dt = FIX16(0.5);
    trees[3].show = 1;
    trees[3].dir = 1;

    trees[4].x = FIX16(70);
    trees[4].sx = FIX16(70);
    trees[4].t = FIX16(14);
    trees[4].st = FIX16(14);
    trees[4].dt = FIX16(0.4);
    trees[4].show = 1;
    trees[4].dir = 1;

    trees[5].x = FIX16(100);
    trees[5].sx = FIX16(100);
    trees[5].t = FIX16(7);
    trees[5].st = FIX16(14);
    trees[5].dt = FIX16(0.5);
    trees[5].show = 1;
    trees[5].dir = 1;
}


//  get draw order for trees
void sort3tree(s16 s) {
    s16 a = s;
    s16 b = s+1;
    s16 c = s+2;
    if( trees[a].t < trees[b].t) {
        if( trees[a].t < trees[c].t ) {
            if( trees[b].t < trees[c].t ) {
                sortedTreeIndex[s] = a;
                sortedTreeIndex[s+1] = b;
                sortedTreeIndex[s+2] = c;
            } else {
                sortedTreeIndex[s] = a;
                sortedTreeIndex[s+1] = c;
                sortedTreeIndex[s+2] = b;
            }
        } else {
            sortedTreeIndex[s] = c;
            sortedTreeIndex[s+1] = a;
            sortedTreeIndex[s+2] = b;
        }
    }else{
        if( trees[a].t > trees[c].t ) {
            if( trees[b].t > trees[c].t ) {
                sortedTreeIndex[s] = c;
                sortedTreeIndex[s+1] = b;
                sortedTreeIndex[s+2] = a;
            } else {
                sortedTreeIndex[s] = b;
                sortedTreeIndex[s+1] = c;
                sortedTreeIndex[s+2] = a;
            }
        } else {
            sortedTreeIndex[s] = b;
            sortedTreeIndex[s+1] = a;
            sortedTreeIndex[s+2] = c;
        }
    }

}

void updateTrees() {
    for( int i=0; i < TREE_COUNT; ++i ) {
        // update values
        if( trees[i].dir > 0 ) {
            trees[i].x = trees[i].x + treeX[F16_toInt( trees[i].t)];
        }else{
            trees[i].x = trees[i].x - treeX[F16_toInt( trees[i].t)];
        }
        trees[i].t = trees[i].t - trees[i].dt;
        if( F16_toInt( trees[i].t ) < 0 ) {
            trees[i].x = trees[i].sx;
            trees[i].t = trees[i].st;
        }
    }

    // figure out sort order for trees
    sort3tree(0);
    sort3tree(3);
}

int main(bool arg) 
{
    // go big
    VDP_setPlaneSize(64,64,TRUE);

    // Setup color for low level tiles (didn't use image in rescomp).
    u16 palette0[16];
    palette0[0] = RGB24_TO_VDPCOLOR(0x002400);
    palette0[1] = RGB24_TO_VDPCOLOR(0x242424);
    palette0[2] = RGB24_TO_VDPCOLOR(0x482400);
    palette0[3] = RGB24_TO_VDPCOLOR(0xb6b648);
    palette0[4] = RGB24_TO_VDPCOLOR(0x240000);
    palette0[5] = RGB24_TO_VDPCOLOR(0x916d24);
    palette0[6] = RGB24_TO_VDPCOLOR(0x002400);
    palette0[7] = RGB24_TO_VDPCOLOR(0x244800);
    palette0[8] = RGB24_TO_VDPCOLOR(0x002424);
    palette0[9] = RGB24_TO_VDPCOLOR(0x000000);
    palette0[10] = RGB24_TO_VDPCOLOR(0x000000);
    palette0[11] = RGB24_TO_VDPCOLOR(0x482400);
    palette0[12] = RGB24_TO_VDPCOLOR(0x916d24);
    palette0[13] = RGB24_TO_VDPCOLOR(0x919191);
    palette0[14] = RGB24_TO_VDPCOLOR(0x484848);
    palette0[15] = RGB24_TO_VDPCOLOR(0x240000);
    PAL_setColors( 0, palette0, 16, CPU);


    // Setup color cycling palette for backgorund B. Just use first 10 colors
    PAL_setPalette(PAL1, bg_b_pal.data, CPU);
    u16 palette1[9]; 
    memcpy(&palette1[0], bg_b_pal.data, 18 );
    palette1[0] = palette1[1];

    // other palett
    PAL_setPalette( PAL2, blackout_pal.data, CPU);
    PAL_setPalette( PAL3, dino_pal.data, CPU);

    // set scrolling mode to TILE for horizontal.
    VDP_setScrollingMode(HSCROLL_LINE, VSCROLL_COLUMN);
    // init scroll buffers
    memset( HscrollA, 0, sizeof(HscrollA ) );
    memset( VscrollA, 0, sizeof(VscrollA ) );
    memset( HscrollB, 0, sizeof(HscrollB ) );
    memset( VscrollB, 0, sizeof(VscrollB ) );
    memset( VscrollBUpper, 0, sizeof(VscrollBUpper ) );
    memset( VscrollBLower, 0, sizeof(VscrollBLower ) );
    for (int i = 0; i < ROWS; ++i)
    {
        HscrollA[i] = SCROLL_CENTER;
        HscrollB[i] = SCROLL_CENTER;
    }
    s16 vscroll = 32;
    for( int i=0; i < COLS; ++i ) {
        VscrollB[i] = vscroll;
        VscrollBUpper[i] = vscroll;
        VscrollBLower[i] = vscroll;
    }

    VDP_setHorizontalScrollLine(BG_A, 0, HscrollA, ROWS, DMA_QUEUE);
    VDP_setVerticalScrollTile(BG_A, 0, VscrollA, COLS, DMA_QUEUE);

    //////////////////////////////////////////////////////////////////////
    // Setup row of tiles for tree trunk tiles.
    // First allocate enough space for  64 tiles 
    s16 rowIndex = TILE_USER_INDEX; 
    u32 rowTiles[TRUNK_ROW_WIDTH * 8];
    memset( rowTiles,0, sizeof(rowTiles) );
    // Load the tile into VRAM with VDP_loadTileData
    VDP_loadTileData( (const u32 *)rowTiles, // tile data pointer
            rowIndex,                            // index 
            TRUNK_ROW_WIDTH,                     // number of tiles to load
            DMA_QUEUE                            // transfer method
            ); 

    // set 23 rows of Background A to use the tiles we loaded into VRAM
    // updating rowTiles will affect all rows set here.
    for( u16 y=0; y< 23; ++y ) {
        VDP_fillTileMapRectInc( BG_A,
                TILE_ATTR_FULL( PAL0,// Palette
                    1,                // Priority
                    0,                // Flip Vertical
                    0,                // Flip Horizontal
                    rowIndex),        // tile index
                0,  // x
                y,  // y
                TRUNK_ROW_WIDTH,  // width
                1  // height
                ); 
    }


    //////////////////////////////////////////////////////////////////////
    //  Setup a column of tiles for ground tiles
    s16 colIndex = rowIndex + TRUNK_ROW_WIDTH;
    u32 colTiles[GROUND_COL_HEIGHT * 8];
    memset( colTiles,0, sizeof(colTiles) );
    memcpy( colTiles, ground[0], sizeof( colTiles ) ); // copy the column data into ram
    VDP_loadTileData( (const u32 *)colTiles, // tile data pointer
            colIndex,   // index 
            GROUND_COL_HEIGHT,   // number of tiles to load
            DMA_QUEUE    // transfer method
            ); 

    for( u16 x=11; x< 55; ++x ) {
        // make a column out of it.
        VDP_fillTileMapRectInc( BG_A,
                TILE_ATTR_FULL( PAL2,// Palette
                    1,                // Priority
                    0,                // Flip Vertical
                    0,                // FLip Horizontal
                    colIndex),         // tile index
                x,  // x
                23,  // y
                1,  // width
                GROUND_COL_HEIGHT  // height
                ); 
    }


    //////////////////////////////////////////////////////////////////////
    // load in background B from RESCOMP.
    s16 indexB = colIndex + GROUND_COL_HEIGHT; 
    VDP_loadTileSet( bg_b.tileset, indexB, DMA_QUEUE_COPY);
    VDP_drawImageEx(BG_B, &bg_b, TILE_ATTR_FULL(PAL1, FALSE, FALSE, FALSE, indexB), 0, 0, FALSE, TRUE);


    //////////////////////////////////////////////////////////////////////
    // Setup Sprites
    SPR_init();

    // crosshairs
    Sprite *crosshairsSprite = NULL;
    s16 crosshairsPosX =152.0;
    s16 crosshairsPosY =104.0;
    crosshairsSprite = SPR_addSprite( &crosshairs,  // Sprite defined in resources
            crosshairsPosX,// starting X position
            crosshairsPosY,// starting Y position
            TILE_ATTR( PAL3,           // specify palette
                1,            // Tile priority ( with background)
                FALSE,        // flip the sprite vertically?
                FALSE         // flip the sprite horizontally
                ));

    // setup sprites to hide the hardware scrolling bug.
    for( int i = 0; i < 7; ++i ) {
        SPR_addSprite( &blackout,  // Sprite defined in resources
                0,// starting X position
                i* 32,// starting Y position
                TILE_ATTR( PAL2,           // specify palette
                    1,            // Tile priority ( with background)
                    FALSE,        // flip the sprite vertically?
                    FALSE         // flip the sprite horizontally
                    ));
    }
    // throw in the angry dinosaur.
    Sprite* dinoSprite = SPR_addSprite(& dino,
            100, // X 
            40, // Y
            TILE_ATTR( PAL3, 
                0,     // priority
                FALSE, // flip V
                FALSE // flip H
                ));

    //////////////////////////////////////////////////////////////////////
    // setup light gun
    bool menacerFound = FALSE;
    u8 portType = JOY_getPortType(PORT_2);
    if( portType == PORT_TYPE_MENACER) {
        calculateXLookup();
        JOY_setSupport(PORT_2, JOY_SUPPORT_MENACER);
        menacerFound = TRUE;
    }


    // timer to delay some processing.
    s16 tick = 0;  
    // rotation variables
    s16 currAngle = 5;
    s16 currAngleOffsetCol = 0;
    s16 currAngleOffsetRow = 0;
    s16 stepDir = 1;


    // ground tiles
    s16 groundColFrame = 0;

    setupTrees();
    while(1)
    {
        tick++;
        if( tick == 2) {
            // update the tree positions.
            tick = 0;
            memset( rowTiles,0, sizeof(rowTiles) );
            updateTrees();
            for( s16 t=0; t <TREE_COUNT; ++t ) {
                s16 st = sortedTreeIndex[t];
                s16 trunkSet = F16_toInt(trees[st].t);
                draw_tiles( &rowTiles[0], &trunkTileSet[0] + trunkArrayOffsets[trunkSet ] ,
                        F16_toInt(trees[st].x), // - halfWidthPixel[trunkSet],
                        lastTilePixels[trunkSet],
                        numTiles[trunkSet]);
            }

            // load tile data into VRAM 
            VDP_loadTileData( (const u32 *)rowTiles, // tile data pointer
                    rowIndex,                            // index 
                    TRUNK_ROW_WIDTH,   // number of tiles to load
                    DMA_QUEUE    // transfer method
                    ); 

        }

        // update the col data
        memcpy(colTiles, ground[groundColFrame],  sizeof(colTiles ));
        groundColFrame--;
        if( groundColFrame < 0 ) {
            groundColFrame = 5;
        }
        VDP_loadTileData( (const u32 *)colTiles, // tile data pointer
                colIndex,   // index 
                GROUND_COL_HEIGHT,   // number of tiles to load
                DMA_QUEUE    // transfer method
                ); 


        // BRAVELY RUN AWAY
        vscroll -= 4;
        if( vscroll < 24) {
            vscroll = 48;
            PAL_setColors(17, palette1, 8, DMA_QUEUE);
        } else if ( vscroll == 36 ) {
            PAL_setColors(17, palette1+1, 8, DMA_QUEUE);
        }

        if( tick == 1 ) {

            currAngle += stepDir;
            if( currAngle >= _SCROLL_COUNT) {
                stepDir = -1;
                currAngle = _SCROLL_COUNT - 1;
            }  else if( currAngle < 0 ) {
                stepDir = 1;
                currAngle = 0;
            }

            // copy 
            currAngleOffsetCol = currAngle * _COLS_A;  
            currAngleOffsetRow = currAngle * _ROWS_A; 
            for( u16 i=0; i < COLS; ++i ) {
                VscrollA[i] = _vScroll[ currAngleOffsetCol + i] + 24;
            }
            for( u16 i=0; i < _ROWS_A; ++i ) {
                HscrollB[i] = _hScroll[ currAngleOffsetRow + i] + SCROLL_CENTER;
                HscrollA[i] = HscrollB[i];
            }
        }
        for( u16 i=0; i < COLS; ++i ) {
            VscrollBUpper[i] = _vScroll[ currAngleOffsetCol + i] + vscroll;
        }


        // handle menacer 
        if( menacerFound ) {
            s16 xVal = JOY_readJoypadX(JOY_2);
            s16 yVal = JOY_readJoypadY(JOY_2);
            crosshairsPosX = xLookup[xVal] - 8;
            crosshairsPosY = yVal - 8;

            SPR_setPosition(crosshairsSprite, crosshairsPosX, crosshairsPosY);
        }
        SPR_update();


        // set scroll values
        VDP_setHorizontalScrollLine(BG_B, 0, HscrollB, ROWS, DMA_QUEUE);
        VDP_setHorizontalScrollLine(BG_A, 0, HscrollA, ROWS, DMA_QUEUE);
        VDP_setVerticalScrollTile(BG_B, 0, VscrollBUpper, COLS, DMA_QUEUE);
        VDP_setVerticalScrollTile(BG_A, 0, VscrollA, COLS, DMA_QUEUE);

        // let SGDK do its thing.
        VDP_waitVSync();
        SYS_doVBlankProcess();
    }

    return 0;
}

