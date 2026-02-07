#!/usr/bin/env python
from PIL import Image
import sys
import os,    argparse, logging

#
# python3 scale_sprites.py -i sprite.png 
#

def main(args, loglevel): 
    logging.basicConfig(format="%(levelname)s: %(message)s", level=loglevel)

    input_filename = args.input_image
    output_filename = args.output_image
    output_basename = output_filename.rsplit(".",1)[0]

    logging.info("WORKING ON:" + input_filename );
    logging.info("Write to:" + output_filename + " base: " + output_basename );
    zmap=[]
    zmap_length = args.zmap_length
    scale=[]
    y_world = args.y_world
    screen_height = args.screen_height
    player_y_base = args.player_y_base
    

    frames = args.frames
    num_sizes = args.num_sizes
    
    scaled_images=[]

    # calculate zmap and scaling
    base_z = round ( screen_height - player_y_base )
    for i in range( 0, zmap_length ) :
        # the triangle
        #   y_screen/dist = y_world/z_world    dist is dist to screen
        #   y_screen = (y_world*dist)/z_world 
        # Lou goes on and says dist=1  (arbitrary)
        #   y_screen = (y_world)/z_world 
        # **but this puts the center  of the view at the upper corner of the screen**
        #
        # to center on the display, shift  by half the resolution (y_resooution/2)
        #
        #     y_screen = (y_world)/z_world + ( y_resolution/2)
        #     y_screen - ( y_resolution/2 ) = y_world/z_world
        #     Z = Y_world / (Y_screen - (height_screen / 2))
        #
        #  In my particular case, screen center isn't really the 
        #  center of the display, I want the vanishing point to be at the "top"
        # of z so really  zmap length is my height/2.0
        # var z = y_world / ( float(  i) - (float(height)/2.0) )  
        z  = y_world / float( i - zmap_length )
        zmap.append( z )
    for i in range( 0, zmap_length ) :
        scale.append(  zmap[base_z]/ zmap[i] ) 

    for i in range( 0, zmap_length ) :
        logging.debug( f'i: {i} z: {zmap[i]} s: {scale[i]}' )

 
    with Image.open(input_filename) as img:
        img_width, img_height = img.size
        img_pal = img.getpalette()

        frame_width = img_width / frames
        print( img_width, img_height, frame_width )
        
        # calc  different scales (starting at base to just below road line in image)
        scale_step = (zmap_length - base_z ) / num_sizes
        ind = float( base_z)

        # create an output image
        out_img = Image.new('P', ( img_width, num_sizes * img_height ) )
        out_img.putpalette( img_pal )    
        out_row = 1
        while ind < zmap_length-1:
            i = round(ind)
            logging.debug(f'i: {i} ' )
            logging.debug(f'   scale: { scale[round(ind)]}')
            # scale the temp images
            for f in range( 0, frames ): 
                # get partial
                frame_img = img.crop( ( f * frame_width, 0, (f+1) * frame_width, img_height )  ) # left, upper, right, lower  
                smol = frame_img.resize( ( round(frame_width * scale[i]), round(img_height * scale[i]) ), Image.Resampling.NEAREST )
                smol_width, smol_height = smol.size
                smol.save( f'{output_basename}_s{round(ind)}_f{f}.png')
                # position with upper left corner of smol image in outimage
                out_img.paste( smol, ( int ( f*frame_width + (frame_width-smol_width)/2) ,  int(out_row* img_height  - smol.height )  ) ) # upper left corner 


            ind += scale_step
            out_row += 1
        out_img.save( output_filename)


if __name__ == '__main__':
    parser = argparse.ArgumentParser( 
    description = "Create C array from PNG",
    fromfile_prefix_chars = '@' )
    # parameter list
    parser.add_argument(
            "-v",
            "--verbose",
            help="increase output verbosity",
            action="store_true")

    parser.add_argument( "-i",
            "--input_image",
            default = 'sprite.png',
            help = "input image filename",
            metavar = "ARG")

    parser.add_argument( "-o",
            "--output_image",
            default = 'sprite_out.png',
            help = "output image filename",
            metavar = "ARG")

    parser.add_argument( "-s",
            "--screen_height",
            default = 224,
            type=int,        
            help = "screen height",
            metavar = "ARG")

    parser.add_argument( "-z",
            "--zmap_length",
            default = 80,
            type=int,        
            help = "number of entries in z-map",
            metavar = "ARG")

    parser.add_argument( "-y",
            "--y_world",
            default = -15,
            type=int,        
            help = "from lou",
            metavar = "ARG")

    parser.add_argument( "-p",
            "--player_y_base",
            default = 218,
            type=int,        
            help = "lowest (largest) y row taken by player (determines 1.0 scale in Z)",
            metavar = "ARG")

    parser.add_argument( "-r",
            "--roadside_offset",
            default = 28,
            type=int,
            help = "output image filename",
            metavar = "ARG")

    parser.add_argument( "-f",
            "--frames",
            default = 1,
            type=int,
            help = "number of animation frames for ORIGINAL sprite. Assumes horizontal layout",
            metavar = "ARG")

    parser.add_argument( "-n",
            "--num_sizes",
            default = 10,
            type=int,
            help = "number of scale sizes to generate",
            metavar = "ARG")

    args = parser.parse_args()

    # Setup logging
    if args.verbose:
        loglevel = logging.DEBUG
    else:
        loglevel = logging.WARNING

    main(args, loglevel)
