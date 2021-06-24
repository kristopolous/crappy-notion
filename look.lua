if not gr.select_engine("de") then
    return
end

de.reset()

active_bg = "#444455"
neutral = "#444444"
white = "#ffffff"

de.defstyle("*", {
    highlight_colour = "#111111",
    shadow_colour = "#000000",
    background_colour = "#111111",
    foreground_colour = "#aaaaaa",

    shadow_pixels = 0,
    spacing = 2,
    highlight_pixels = 0,
    padding_pixels = 5,
    border_style = "elevated",
    border_sides = "all",

    font = "xft:Cantarell:size=10",
    text_align = "center",
})

de.defstyle("stdisp", {
    shadow_pixels = 0,
    highlight_pixels = 0,
    text_align = "left",
    background_colour = "#000000",
    foreground_colour = "grey",

    de.substyle("important", {
        foreground_colour = "green",
    }),

    de.substyle("critical", {
        foreground_colour = "red",
    }),
})


de.defstyle("input", {
    text_align = "left",
    foreground_color = "#ff00ff",
    highlight_colour = "#222228",
    shadow_colour = "#000000",
    padding = 2,

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
    foreground_color = "#ff00ff",
    highlight_pixels = 0,
    shadow_pixels = 0,
    padding_pixels = 0,
})


de.defstyle("frame", {
    background_colour = "#000000",
    transparent_background = false,
    shadow_pixels = 0,
    highlight_pixels = 0,
    padding_pixels = 10,
    border_sides = "all",
    de.substyle("quasiactive", {
        -- Something detached from the frame is active
        padding_colour = "#901010",
    }),
})

de.defstyle("frame-tiled", {
    shadow_pixels = 0,
    highlight_pixels = 0,
    padding_pixels = 1,
})

de.defstyle("frame-tiled-alt", {
    bar = "none",
})

-- Frame-floating, the border around a floating window.
de.defstyle("frame-floating", {
    bar = "shaped",
    background_colour = neutral,
    padding_pixels = 1,
})

de.defstyle("frame-transient", {
    bar = "none",
    padding_pixels = 1,
})

de.defstyle("actnotify", {
    shadow_colour = "#c04040",
    highlight_colour = "#c04040",
    background_colour = "#901010",
    foreground_colour = "#eeeeee",
})


de.defstyle("tab", {
    font = "xft:Cantarell:style=Bold:size=8",

    de.substyle("active-selected", {
        highlight_colour = "#555555",
        shadow_colour = "#555555",
        background_colour = active_bg,
        foreground_colour = "#eeeeee",
    }),

    de.substyle("inactive-selected", {
        highlight_colour = "#111111",
        shadow_colour = "#333333",
        background_colour = "#333333",
        foreground_colour = "#aaaaaa",
    }),
})

-- "frame" is a window.
de.defstyle("tab-frame", {
    -- TODO: some kind of amend option. It should not be necessary to
    -- duplicate this definition for both tab-frame and tab-menuentry,
    -- or for each style, nor use more complex hacks to communicate
    -- this stuff otherwise.
    de.substyle("*-*-*-unselected-activity", {
        shadow_colour = "#c04040",
        highlight_colour = "#c04040",
        background_colour = "#901010",
        foreground_colour = "#eeeeee",
    }),


    de.substyle("*-*-*-selected-activity", {
        shadow_colour = "#c04040",
        highlight_colour = "#c04040",
        background_colour = "#b03030",
        foreground_colour = "#ffffff",
    }),

    de.substyle("*-*-*-tabnumber", {
        background_colour = "black",
        foreground_colour = "green",
    }),
})

de.defstyle("tab-frame-tiled", {
    font = "xft:Cantarell:size=7",
    spacing = 1,
    de.substyle("active-selected", {
        foreground_colour = white,
        background_colour = active_bg,
      }),
})

de.defstyle("tab-menuentry", {
    text_align = "left",

    de.substyle("*-*-*-unselected-activity", {
        shadow_colour = "#c04040",
        highlight_colour = "#c04040",
        background_colour = "#901010",
        foreground_colour = "#eeeeee",
    }),

    de.substyle("*-*-*-selected-activity", {
        shadow_colour = "#c04040",
        highlight_colour = "#c04040",
        background_colour = "#b03030",
        --background_colour = "#ff00ff",
        foreground_colour = "#ffffff",
    }),
})

de.defstyle("tab-menuentry-big", {
    padding_pixels = 7,
})


-- Refresh objects' brushes.
gr.refresh()
