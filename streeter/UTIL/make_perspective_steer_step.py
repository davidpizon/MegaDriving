#!/usr/bin/env python
#

import os, argparse, logging





def main( args, loglevel ):
    logging.basicConfig(format="%(levelname)s: %(message)s", level=loglevel)
    
    logging.debug("Arguments:")
    logging.debug(args)

    zmap_length = args.zmap_length
    center_line = args.center_line
    width = args.width
    max_center_line = int( center_line + width/2 )
    min_center_line = int( center_line - width/2 )
    logging.info("Start at: %d end: %d", min_center_line, max_center_line )

    outfilename = args.output_filename

    logging.info("Try to open " + outfilename )
    with open( outfilename, 'w' ) as outfile:
        logging.debug("openED " + outfilename )

        outfile.write("#include <genesis.h>\n\n")
        outfile.write("// assumes centerline limited from -4 to 323, use +4 as the offset int\n")
        outfile.write("const fix16 perspective_step_from_centerline[] = {\n")
        
        for center in range( min_center_line, max_center_line ):
            step = ( center - center_line ) / zmap_length
            logging.debug(" center: %d step: %f", center, step )
            outfile.write(f"FIX16( {step:.4f} ), // {center}\n")
        outfile.write("\n};")
    



if __name__ == '__main__':
    parser = argparse.ArgumentParser( description = "Generates perspective steering lookup.",
                                    epilog = "As an alternative to the commandline, params can be placed in a file, one per line, and specified on the commandline like '%(prog)s @params.conf'.",
                                    fromfile_prefix_chars = '@' )
    # TODO Specify your real parameters here.
    parser.add_argument( "-v",
                        "--verbose",
                        help="Print debug messages",
                        action="store_true")
  
    parser.add_argument( "-z",
                        "--zmap_length",
                        default=80,
                        type=int,
                        help = "Total lines for road",
                        metavar = "ARG")

    parser.add_argument( "-c",
                        "--center_line",
                        default=160,
                        type=int,
                        help = "Center of road image/plane",
                        metavar = "ARG")

    parser.add_argument( "-w",
                        "--width",
                        default=328,
                        type=int,
                        help = "range  step size",
                        metavar = "ARG")

    parser.add_argument( "-o",
                        "--output_filename",
                        default="perspective_steer.c",
                        help = "Output filename",
                        metavar = "ARG")


    args = parser.parse_args()
    
    # Setup logging
    if args.verbose:
        loglevel = logging.DEBUG
    else:
        loglevel = logging.INFO
    
    main(args, loglevel)


