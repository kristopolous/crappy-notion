--
-- look_newviolet for Notion's default drawing engine.
-- Based on look_cleanviolet
--

if not gr.select_engine("de") then
    return
end

de.reset()

de.defstyle("*", {
    highlight_colour = "#111111",
    shadow_colour = "#333333",
    background_colour = "#2A2A2A",
    foreground_colour = "#999999",
    
    shadow_pixels = 2,
    highlight_pixels = 0,
    padding_pixels = 2,
    spacing = 1,
    border_style = "ridge",
    border_sides = "all",
    
    font = "-*-helvetica-medium-r-normal-*-14-*-*-*-*-*-*-*",
    text_align = "center",
})


de.defstyle("tab", {
    font = "-*-helvetica-medium-r-normal-*-14-*-*-*-*-*-*-*",

    de.substyle("active-selected", {
        highlight_colour = "#222244",
        shadow_colour = "#222244",
        background_colour = "#6C135D",
        foreground_colour = "#eeeeff",
    }),

    de.substyle("inactive-selected", {
        highlight_colour = "#111133",
        shadow_colour = "#333333",
        background_colour = "#463944",
        foreground_colour = "#ffffff"
    }),
})


de.defstyle("input", {
    text_align = "left",
    highlight_colour = "#eeeeff",
    shadow_colour = "#eeeeff",

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


dopath("lookcommon_clean_stdisp")
dopath("lookcommon_clean_tab")

-- Refresh objects' brushes.
gr.refresh()
