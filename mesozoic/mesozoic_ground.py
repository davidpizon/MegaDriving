from PIL import Image, ImageDraw
import math


#  Jurasic seems to use 9 colors for in cycling
width = 64 
height = 200 # height of image
tileWidth = 8

img = Image.new( mode="P", size = (width,height))
img.putpalette([
  0,0,0,  # 0
  63,0,0, # red 1
  127,0,0,
  190,0,0,
  255,0,0,
  0,0,63,   # blue 5
  0,0,127,
  0,0,190,
  0,0,255,
  0,63,0,   # green 9
  0,127,0,
  0,190,0,
  0,255,0,
  0,63,63,   #  13
  0,127,127,
  0,190,190

  ])
dImage = ImageDraw.Draw( img )

worldY =  -250

# 96 pixel high ground

# using Z estimate from Lou's page draw initial ground patter
start = 0 
end = 80 
lowZ = worldY/ (start - height/2)
highZ = worldY/ (end - height/2)

sections = 7 
sectionZ = ( highZ - lowZ ) / sections
moveCount = 6
moveZ = -sectionZ  / moveCount
print( "sectionZ ", sectionZ )
lastZ = lowZ
lastImgY = height - 1
color = 1
for move in range( 0, moveCount, 1 ):
  lastZ = lowZ
  lastImgY = height - 1
  color = 1
  print ( "move: ", move )
  for y in range( start, end, 1 ):
    #z = int( (1+(y-159)/15.9)  * 47/ (y - 160))
    z = worldY/ (y - height/2)
    
    if z - lastZ - (moveZ * move) >= sectionZ:
      imgY = height - y - 1
      if imgY != lastImgY:
        thickness = round((12/z)  * (12/z ) -1)
        print( imgY, lastImgY, move * tileWidth, thickness)
        if  move == 0:
          dImage.rectangle( ((0,lastImgY -1), ( moveCount * tileWidth-1, imgY-1 )), fill=color) 
            
        dImage.rectangle( ((move * tileWidth,imgY), (( move+1) * tileWidth-1, imgY + thickness  )), fill=15) 
 
      lastZ += sectionZ
      lastImgY = imgY  
      color += 1
      if color > 8:
        color = 1

#dImage.line( ((0,lastImgY), ( tileWidth-1, lastImgY)), fill=color) 
img.save("mesozoic_land.png")

# start making shift versions

# make shifted patterns
shiftImg = img.copy()

strip = img.crop( (0,0, 1, height) )

offsetX = 0
# vshift of 1 or two
for move in range( 0, moveCount, 1 ):
  strip = img.crop( (offsetX,0, offsetX + 1, height) )
  offsetY = 0 
  for i in range(0, tileWidth,1 ):
    if i == 4:
      offsetY +=1
    shiftImg.paste( strip, ( offsetX +i, offsetY, offsetX+i+1, height + offsetY ) ); 

  offsetX += tileWidth
  
shiftImg.save("mesozoic_land_shift_1.png")


# vshift 3 or 4 
offsetX = 0
# vshift of 1 or two
for move in range( 0, moveCount, 1 ):
  strip = img.crop( (offsetX,0, offsetX + 1, height) )
  offsetY = -1
  for i in range(0, tileWidth,1 ):
    if i == 1 or i == 5:
      offsetY +=1
    shiftImg.paste( strip, ( offsetX +i, offsetY, offsetX+i+1, height + offsetY ) ); 

  offsetX += tileWidth
  
shiftImg.save("mesozoic_land_shift_2.png")


# vshift 4 or 5 
offsetX = 0
# vshift of 1 or two
for move in range( 0, moveCount, 1 ):
  strip = img.crop( (offsetX,0, offsetX + 1, height) )
  offsetY = -2
  for i in range(0, tileWidth,1 ):
    if i == 2 or i == 4 or i == 6:
      offsetY +=1
    shiftImg.paste( strip, ( offsetX +i, offsetY, offsetX+i+1, height + offsetY ) ); 

  offsetX += tileWidth
  
shiftImg.save("mesozoic_land_shift_3.png")



# vshift 5 or 6 
offsetX = 0
# vshift of 1 or two
for move in range( 0, moveCount, 1 ):
  strip = img.crop( (offsetX,0, offsetX + 1, height) )
  offsetY = -3
  for i in range(0, tileWidth,1 ):
    if i == 2 or i == 3 or i == 5 or i == 6:
      offsetY +=1
    shiftImg.paste( strip, ( offsetX +i, offsetY, offsetX+i+1, height + offsetY ) ); 

  offsetX += tileWidth
  
shiftImg.save("mesozoic_land_shift_4.png")


# vshift 7 or 8 
offsetX = 0
# vshift of 1 or two
for move in range( 0, moveCount, 1 ):
  strip = img.crop( (offsetX,0, offsetX + 1, height) )
  offsetY = -4
  for i in range(0, tileWidth,1 ):
    offsetY +=1
    shiftImg.paste( strip, ( offsetX +i, offsetY, offsetX+i+1, height + offsetY ) ); 

  offsetX += tileWidth
  
shiftImg.save("mesozoic_land_shift_5.png")




