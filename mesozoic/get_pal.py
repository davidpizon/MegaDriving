from PIL import Image, ImageDraw
import math


#img = Image.new( mode="P", size = (width,height))
#img.putpalette([
#  0,0,0,  # 0
#  63,0,0, # red 1
#  127,0,0,
#  190,0,0,
#  255,0,0,
#  0,0,63,   # blue 5
#  0,0,127,
#  0,0,190,
#  0,0,255,
#  0,63,0,   # green 9
#  0,127,0,
#  0,190,0,
#  0,255,0,
#  0,63,63,   #  13
#  0,127,127,
#  0,190,190
#
#  ])
#dImage = ImageDraw.Draw( img )


img = Image.open("trunk_tiles_2.png")
pal = img.getpalette()
# combine sets of 3 to 24-bit number
for c in range(0, int(len(pal)/3)):
  val = (pal[c*3]<<16) + (pal[c*3+1]<< 8) + (pal[c*3+2] )
  print("palette[%d] = RGB24_TO_VDPCOLOR(0x%06x)" %( c,val))



