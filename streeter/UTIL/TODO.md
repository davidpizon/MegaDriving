# TODO LIST

* AUTO REDRAW WHEN CHANGING CURVE AND LENGTH : DONE~ish (needs testing)
* RESET/CLEAR DRAWING AREA  (with warning) : DONE
* mouse wheel zoom : DONE  
* pan with mouse drag : DONE~ish



* Generate Lanes for  roadside object and cars behavior.
  * relative to outside of track ( should be offset from track center line?)
  * 50% (middle) then +/- 16.66 and +/-33.33 for 5 lanes? too much? maybe just 3 lanes?

* Generate `ZScale_map` (for sprite sizing)
  * no hills, so sprite zoom should be easy to base on Z 

* Output DX per segment ( or per position but that's 
 


* add road-side objects
  * place along segments? label segment as a type and 
    have game generate them?

* Reduce number generated LUTs by
  * eliminating ones that look basically the same (by what criteria???, total pixels off? max pixel deviation?)
  * limit some of the freedom for segment curve/lenght ( probably a good idea for 8-bit support )

* 8-Bit computer export files ( Atari800/XL/XE, Commodore 64 )


* CLEAN-UP
  * Copy/Paste is the worst form of code reuse. Find common code and try to
    put into functions.
  * dead code all over from ideas that didn't pan out.
  

## Not likely to happen but might if this tool gets used by (significantly) more than just me.
* Hills ( not for Streeter, but possible Lou's version )
* Undo/Redo command pattern ( probably needs significant  refactor)
* Curve the closing segment when you press 'Close' button
* Save preferences
* better looking mini-maps?
  * experiment with adding soft/fuzzy spots to track instead of hard on/off.
    Threshold at end to get center and sides?
  * fill holes on track.png ( morpho cloe/open? Median filter?)

