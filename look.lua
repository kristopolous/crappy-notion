if not gr.select_engine("de") then
    return
end

de.reset()

active_bg = "#52527A"
neutral = "#29293D"
darker = "#15151E"
white = "#ffffff"
bright = "#A3A3C2"
black = "#000000"

de.defstyle("*", {
    background_colour = darker,
    foreground_colour = bright,

    shadow_pixels = 0,
    spacing = 2,
    highlight_pixels = 0,
    padding_pixels = 5,
    border_style = "elevated",
    border_sides = "all",

    font = "xft:Cantarell:size=10",
    text_align = "center",
})


de.defstyle("input", {
    text_align = "left",
    foreground_colour = white,
    font = "xft:Cantarell:size=12",

    de.substyle("*-selection", {
        background_colour = active_bg,
        foreground_colour = white
    }),

    de.substyle("*-cursor", {
        background_colour = active_bg,
        foreground_colour = white,
    }),
})


de.defstyle("input-menu", {
    padding_pixels = 0,
})


de.defstyle("frame", {
    background_colour = black,
    transparent_background = false,
    padding_pixels = 3,
    border_sides = "all",

    de.substyle("active", {
        background_colour = active_bg
    }),

    de.substyle("quasiactive", {
        padding_colour = "#901010",
    }),
})

de.defstyle("frame-tiled", {
    padding_pixels = 1,
})

de.defstyle("frame-tiled-alt", {
    bar = "none",
})

-- Frame-floating, the border around a floating window.
de.defstyle("frame-floating", {
    bar = "shaped",
    de.substyle("active", {
        padding_colour = active_bg
    }),
    padding_pixels = 2
})

de.defstyle("frame-transient", {
    bar = "none",
    padding_pixels = 1,
})

de.defstyle("actnotify", {
    background_colour = "#901010",
    foreground_colour = "#eeeeee",
})


de.defstyle("tab", {
    font = "xft:Cantarell:style=Bold:size=8",

    de.substyle("active-selected", {
        background_colour = active_bg,
        foreground_colour = white,
    }),

    de.substyle("inactive-selected", {
        background_colour = neutral,
        foreground_colour = bright,
    }),
})

-- "frame" is a window.
de.defstyle("tab-frame", {
    -- TODO: some kind of amend option. It should not be necessary to
    -- duplicate this definition for both tab-frame and tab-menuentry,
    -- or for each style, nor use more complex hacks to communicate
    -- this stuff otherwise.
    de.substyle("*-*-*-unselected-activity", {
        background_colour = neutral,
        foreground_colour = bright,
    }),

    de.substyle("*-*-*-selected-activity", {
        background_colour = "#b03030",
        foreground_colour = white,
    }),

    de.substyle("*-*-*-tabnumber", {
        background_colour = "black",
        foreground_colour = "green",
    }),
})

de.defstyle("tab-frame-tiled", {
    font = "xft:Cantarell:size=8",
    spacing = 1,
    de.substyle("active-selected", {
        foreground_colour = white,
        background_colour = active_bg,
    }),
})

de.defstyle("tab-menuentry", {
    text_align = "left",

    -- drop down menu background color.
    de.substyle("inactive-selected", {
        foreground_colour = white,
        background_colour = "purple",
    }),

    de.substyle("*-*-*-unselected-activity", {
        highlight_colour = "#c04040",
        background_colour = "#F01010",
        foreground_colour = "#eeeeee",
    }),

    de.substyle("*-*-*-selected-activity", {
        highlight_colour = "#c04040",
        background_colour = active_bg,
        foreground_colour = white,
    }),
})


-- Refresh objects' brushes.
gr.refresh()
