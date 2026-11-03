### My [notion configuration](https://github.com/raboof/notion)

Pure Lua on top of stock notion, no C fork.

## Features

 * **WIN+arrows**: spatial focus. Goes to the nearest window in that direction by top-left position.
   * Floating: windows stacked at the same spot are walked one by one, and it wraps at the screen edge. Left/right undo each other.
   * Tiled: moves to the neighbouring frame and stops at the edge.
 * **WIN+P**: floating move mode. Arrows snap the top-left to a 6x6 screen grid (0/6 ... 5/6).
 * **WIN+R**: resize mode.
   * Floating: arrows snap the right/bottom edge to the same 6x6 grid (right/down grow, left/up shrink).
   * Tiled: arrows move the divider 50px.
 * **WIN+I**: floating move mode, 50px per arrow press.
 * **WIN+1**: maximize the frame to the screen.

In the modes: Return, Escape or the same WIN+key exits. The mode stays on the window it started on, and sloppy mouse focus is paused so windows passing under the pointer don't steal it.

## Documentation addendum

 * "bar" can be 
   * inside: entire width of window, takes padding into consideration
   * outside: entire width of window, DOES NOT takes padding into consideration
   * shaped: only the width needed for the title
   * none: hidden

 * shadow_pixels/highlight_pixels : these are bottom/right, top/left and don't really form proper shadows or highlights. Along with padding this are part of the actionable frame around a window

 * "padding_color" is mostly a lie, you want to override "background_color" to change that.


## Background
From 2000-2014, I used twm as my window manager. Yes, twm.  I had a [perl script](https://github.com/kristopolous/alttab) to do window management and querying.

Refer to /usr/include/X11/keysymdef.h for keycodes
