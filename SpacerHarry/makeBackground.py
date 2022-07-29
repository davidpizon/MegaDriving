from PIL import Image, ImageDraw


width = 512
midpint = width / 2
bottomStripWidth = 32

bottomLeftStart =  ( width - bottomStripWidth * width ) / 2;
height = 224
step = 32

img = Image.new( mode="RGB", size = (width,height), color = "darkgreen" )
dImage = ImageDraw.Draw( img )


for x in range( 0, width,2 ):
    shape = [ (x, 0), ( bottomLeftStart + x*bottomStripWidth, 223 ), (bottomLeftStart +  x*bottomStripWidth + bottomStripWidth, 223), (x,0 ) ]
    dImage.polygon( shape, fill = "green" , outline="green")



img.save("test.png")



