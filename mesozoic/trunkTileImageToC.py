from PIL import Image

img = Image.open("trunk_tiles_2.png")

width, height = img.size

cols = int(width/8)
rows = int(height/8)

print("#ifndef _TRUNK_H");
print("#define _TRUNK_H");
print("// orig image was %d columns wide %d rows tall.   pixel width %d"%(cols,rows,width))

px = img.load()


maxPixels = []
lastTilePixels = []

trunkSet = 0
arrayOffset = 0
arrayOffsets = []
numTiles = []

print( "const u32 trunkTileSet[] =\n{")
for tileY in range( 0, rows ) :
  # find number of populated tiles in current row
  populatedCols = 0
  maxPixel = 0
  # old way
  #for tileX in range( 0, cols ):
  #  # scan the entire tile for pixels, some are sparse.
  #  for tileX in range( 0, cols ):
  #  currentTile = px[ tileX * 8, tileY * 8] 
  #  if currentTile != 0:
  #      populatedCols += 1
  for x in range( 0, width ):
    for y in range( tileY*8 ,tileY*8 + 8 ):
      currentPixel = px[ x, y ]
      if currentPixel > 0 and x > maxPixel:
        maxPixel = x

  populatedCols = int(maxPixel / 8) + 1
  maxPixels.append(maxPixel)
  lastTilePixels.append(maxPixel - int( maxPixel/8) * 8 )

  #print( "const u32 trunkSet%d[%d] =\n{"%( tileY, 8 * populatedCols ) ) 
  print( "// - trunkset: %d, maxpixel: %d populatedCols: %d" %( trunkSet, maxPixel, populatedCols ))
  print( "//      arrayOffset: %d" % arrayOffset );
  arrayOffsets.append(arrayOffset)
  numTiles.append(populatedCols)
  trunkSet +=1
  arrayOffset += populatedCols * 8 
  for tileX in range( 0, populatedCols ):
    for y in range(0,8):
      print("0x", end="")
      for x in range(0,8):
        print( f'{px[x + tileX * 8,y + tileY * 8 ]:x}', end="") 
      if tileX < populatedCols - 1:
        print(",")
      elif y < 7:
        print(",")
      else:
        print(",")

print("};\n")


print("const s16 halfWidthPixel[] = {")
first = True 
for pix in maxPixels:
  if first is True:
    first = False
  else:
    print(",")
  print( int(pix/2), end="" )
print("\n};\n")


print("const s16 lastTilePixels[] = {")
first = True
for pix in lastTilePixels:
  if first is True:
    first = False
  else:
    print(",")
  print( pix, end="" )
print("\n};\n")



#print( "const u32 trunkArrayOffsets[%d] =\n{"%( len(arrayOffsets) ) ) 
print( "const u16 trunkArrayOffsets[] =\n{")
c = 0
for offset in arrayOffsets:
  print(offset, end="")
  if c < len(arrayOffsets) -1:
    print(",")
  c = c + 1
print("\n};\n")


print( "const u16 numTiles[] =\n{")
c = 0
for num in numTiles:
  print(num, end="")
  if c < len(numTiles) -1:
    print(",")
  c = c + 1
print("\n};\n")

print("#endif // _TRUNK_H");
