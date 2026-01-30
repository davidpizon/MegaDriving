# TODO LIST

* AUTO REDRAW WHEN CHANGING CURVE AND LENGTH : DONE~ish (needs testing)
* RESET/CLEAR DRAWING AREA  (with warning) : DONE
* mouse wheel zoom : DONE  
* pan with mouse drag : DONE~ish



* Generate Lanes for  roadside object and cars behavior.
  * Recall scrolling use `SCROLL_CENTER` (for total image width) plus the calcualted X
```c
    // image is 512x224.  Screen is 320, we want to move halfway
    //  512/2  - 320 /2
    #define SCROLL_CENTER -96

    HscrollA[cdp] = SCROLL_CENTER + F32_toInt(current_x);
```
    but sprites are relative to actual screen coordinates. So I use 160 
    + current X as centerline.
```c
     trees[i].pos_y = current_drawing_pos - FIX32(75);
     if (i % 2 == 0)
     {
         trees[i].pos_x = FIX32(160) + current_x + roadOffsetLeft[bgY];
     }
     else
     {
         trees[i].pos_x = FIX32(160) + current_x + roadOffsetRight[bgY];
     
```
  * relative to outside of track ( should be offset from track center line?)
    Since sprites are not centered. width and height will factor in.
```c
    fix32 rightFromCenter = FIX32(-22); // tree width is 56 ..   half of 56 is 28
    fix32 leftFromCenter = FIX32(-34);  // tree width is 56 ..   half of 56 is 28
    fix32 step = FIX32(1.794);
    for (int i = 224 - ZMAP_LENGTH; i < 224; i++)
    {
        roadOffsetRight[i] = rightFromCenter;
        rightFromCenter = rightFromCenter + step;
        roadOffsetLeft[i] = leftFromCenter;
        leftFromCenter = leftFromCenter - step;
        KLog_F2(" i: ", FIX32(i), "  road offset: ", roadOffsetRight[i]);
    }
```
  * 50% (middle) then +/- 16.66 and +/-33.33 for 5 lanes? too much? maybe just 3 lanes?

* Generate `zmap` 
* Generate `y_to_scale` (for sprite sizing)
  * no hills, so sprite zoom should be easy to base on Zmap

> The scaling factor would just be the inverse of the distance, adjusted so
> that the value is 1 on the line which the player's car graphic spends the
> most time. This can then be used to scale sprites which are on a given line,
> or to find what the width of the road is. 



* add road-side objects
  * place along segments? label segment as a type and 
    have game generate them?

* Output DX per segment 

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

