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
    background_colour = "#111111",
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
    font = "-*-helvetica-medium-r-normal-*-12-*-*-*-*-*-*-*",
    
    de.substyle("active-selected", {
        highlight_colour = "#555555",
        shadow_colour = "#555555",
        background_colour = "#555555",
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
    highlight_colour = "#eeeeff",
    shadow_colour = "#eeeeff",
    
    de.substyle("*-selection", {
        background_colour = "#111111",
        foreground_colour = "#555555",
    }),

    de.substyle("*-cursor", {
        background_colour = "#000000",
        foreground_colour = "#b8b8b8",
    }),
})


de.defstyle("input-menu", {
    highlight_pixels = 0,
    shadow_pixels = 0,
    padding_pixels = 0,
})


de.defstyle("frame", {
    shadow_pixels = 1,
    highlight_pixels = 1,
    padding_pixels = 0,
    border_sides = "all",
})


dopath("lookcommon_clean")


-- Refresh objects' brushes.
gr.refresh()
