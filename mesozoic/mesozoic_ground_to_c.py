from PIL import Image

img = Image.open("ground.png")

width, height = img.size

total_cols = int(width/8)
total_rows = int(height/8)

px = img.load()

# hard coded for now
cols = 6
rows = 10
print( "const u32 ground[%d][%d] =\n{"%( cols , 8 * rows ) ) 
for tileX in range( 0, cols ):
  print("    {")
  for tileY in range( total_rows - rows, total_rows ) :
    print("        // tile %d " % (tileY -  total_rows + rows )  )
    for y in range(0,8):
      print("        0x", end="")
      for x in range(0,8):
        print( f'{px[x + tileX * 8,y + tileY * 8 ]:x}', end="") 
      if tileY < rows - 1:
        print(",")
      elif y < 7:
        print(",")
      else:
        print(",")
  print("    },")
print("};")
