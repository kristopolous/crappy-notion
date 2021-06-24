
if not gr.select_engine("de") then
    return
end

de.reset()

de.defstyle("*", {
    highlight_colour = "#111111",
    shadow_colour = "#333333",
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


de.defstyle("tab", {
    font = "xft:Cantarell:style=Bold:size=8",

    de.substyle("active-selected", {
        highlight_colour = "#555555",
        shadow_colour = "#555555",
        background_colour = "#444455",
        foreground_colour = "#eeeeee",
    }),

    de.substyle("inactive-selected", {
        highlight_colour = "#111111",
        shadow_colour = "#333333",
        background_colour = "#333333",
        foreground_colour = "#aaaaaa",
    }),
})


de.defstyle("input", {
    text_align = "left",
    foreground_color = "#ff00ff",
    highlight_colour = "#222228",
    shadow_colour = "#222228",

    de.substyle("*-selection", {
        background_colour = "#666699",
        foreground_colour = "#000000",
    }),

    de.substyle("*-cursor", {
        background_colour = "#000000",
        foreground_colour = "#b8b8c8",
    }),
})


de.defstyle("input-menu", {
    highlight_pixels = 0,
    shadow_pixels = 0,
    padding_pixels = 0,
})


de.defstyle("frame", {
    background_colour = "#000000",
    transparent_background = false,
    shadow_pixels = 1,
    highlight_pixels = 1,
    padding_pixels = 2,
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

de.defstyle("frame-floating", {
    bar = "shaped",
    padding_pixels = 0,
})

de.defstyle("frame-transient", {
    bar = "none",
    padding_pixels = 1,
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


dopath("lookcommon_clean_tab")

-- Refresh objects' brushes.
gr.refresh()
