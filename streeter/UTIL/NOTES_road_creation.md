# Create Road Image
`warp.py`

```bash
python3 warp_road_texture.py  -s road2_160x128.png -o road2.png -r 24 -F 6 -m 64
```
`-F` frames to generate
`-m` how far to move the road image while generating frames. SHould be the height of 
   the repeating texture

# Create Grass Patern for cycling.
```bash
python3 grass_gen.py -f 6 -o grass_6.png -y -300   
python3 grass_gen.py -f 5 -o grass_5.png -y -300
python3 grass_gen.py -f 4 -o grass_4.png -y -300
```

* `-f` : frames. 
* `-y` : `Y_world` Just change it to get different results

*IMP* Colors were selected to be easily discernable. You likely need to 
edit the image before using it in a program.

# Create Grass Image
converts grass patterns into C arrays for cycling.
```bash
 python3 tile_image_to_c.py  -i grass_4.png -o grass_5.c -n grass
 python3 tile_image_to_c.py  -i grass_5.png -o grass_5.c -n grass
 python3 tile_image_to_c.py  -i grass_5.png -o grass_4.c -n grass
```

can be used like this (YMMV):
1. setup the tiles in plane B
```c
    //////////////////////////////////////////////////////////////////////
    // Load the grass into VRAM with VDP_loadTileData
    s16 grassIndex = roadIndex + road_images.tileset->numTile;
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
                TILE_ATTR_FULL(PAL2,      // Palette
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
```

2. Update by copying grass data into VDP memory
```c
        memcpy(grassColumn, grass[frame],  sizeof(grassColumn ));
        VDP_loadTileData((const u32 *)grassColumn, // tile data pointer
                grassIndex,              // index
                10,                     // number of tiles to load
                DMA_QUEUE              // transfer method
                );
```
