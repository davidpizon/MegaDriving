import os,  argparse, logging
from PIL import Image, ImageDraw
import math


def main(args): 
    tile_width = 8
    frames = args.frames
    output_filename = args.output_filename

    width = frames * tile_width
    height = args.screen_height
    y_world = args.y_world
    
    img = Image.new( mode="P", size = (width,height))
    # colors that I can easily inspect.
    img.putpalette([
        0,0,0,    # 0
        63,0,0, # red 1
        127,0,0,
        190,0,0,
        255,0,0,
        0,0,63,     # blue 5
        0,0,127,
        0,0,190,
        0,0,255,
        0,63,0,     # green 9
        0,127,0,
        0,190,0,
        0,255,0,
        0,63,63,     #    13
        0,127,127,
        0,190,190
    
        ])
    work_image = ImageDraw.Draw( img )
    

    ##############################################################
    # http://www.extentofthejam.com/pseudo/
    # Z = Y_world / (Y_screen - (height_screen / 2))    
    # using Z estimate from Lou's page draw initial ground patter
    start = 0 
    end = 80 
    low_z = y_world/ (start - height/2)
    high_z = y_world/ (end - height/2)
    
    sections = 7 
    section_z = ( high_z - low_z ) / sections
    move_count = 6
    move_z = -section_z / move_count
    print( "section_z ", section_z )
    last_z = low_z
    last_img_y = height - 1
    color = 1
    for move in range( 0, move_count, 1 ):
        last_z = low_z
        last_img_y = height - 1
        color = 1
        print ( "move: ", move )
        for y in range( start, end, 1 ):
            z = y_world/ (y - height/2)
            
            if z - last_z - (move_z * move) >= section_z:
                img_y = height - y - 1
                if img_y != last_img_y:
                    thickness = round((12/z) * (12/z ) -1)
                    print( img_y, last_img_y, move * tile_width, thickness)
                    if move == 0:
                        work_image.rectangle( ((0,last_img_y -1), ( move_count * tile_width-1, img_y-1 )), fill=color) 
                            
                    work_image.rectangle( ((move * tile_width,img_y), (( move+1) * tile_width-1, img_y + thickness )), fill=15) 
     
                last_z += section_z
                last_img_y = img_y
                color += 1
                if color > 8:
                    color = 1
    
    #work_image.line( ((0,last_img_y), ( tile_width-1, last_img_y)), fill=color) 
    img.save(output_filename)

if __name__ == '__main__':
    parser = argparse.ArgumentParser( 
    description = "Create grass image for streeter.",
    fromfile_prefix_chars = '@' )
    # parameter list
    parser.add_argument( "-o",
        "--output_filename",
        default = "grass.png",
        help = "Output filename",
        metavar = "ARG")
 
    parser.add_argument( "-f",
        "--frames",
        default = 6,
        type = int,
        help = "How many frames to generate",
        metavar = "ARG")
 
    parser.add_argument( "-r",
        "--rows",
        default = 80,
        type = int,
        help = "Total height of grass",
        metavar = "ARG")
 
    parser.add_argument( "-y",
        "--y_world",
        default = -250,
        type = int,
        help = "Y world (see lou's)",
        metavar = "ARG")

    parser.add_argument( "-H",
        "--screen_height",
        default = 224,
        type = int,
        help = "Screen Height",
        metavar = "ARG")


    args = parser.parse_args()

    args = parser.parse_args()
 
    args = parser.parse_args()
 
 
    main(args)


