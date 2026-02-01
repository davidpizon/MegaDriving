# Create Road Image
`warp.py`

```bash
python3 warp_road_texture.py  -s road2_160x128.png -o road2.png -r 24 -F 6 -m 64
```

# Create Grass Patern for cycling.
```bash
python3 grass_gen.py -f 6 -o grass_6.png -y -300   
python3 grass_gen.py -f 5 -o grass_5.png -y -300
python3 grass_gen.py -f 4 -o grass_4.png -y -300
```

# Create Grass Image
converts grass patterns into C arrays for cycling.
```bash
 python3 tile_image_to_c.py  -i grass_4.png -o grass_5.c -n grass
 python3 tile_image_to_c.py  -i grass_5.png -o grass_5.c -n grass
 python3 tile_image_to_c.py  -i grass_5.png -o grass_4.c -n grass
```
