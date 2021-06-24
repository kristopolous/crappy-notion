### My [notion configuration](https://github.com/raboof/notion)

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
