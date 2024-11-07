--
-- Notion tiling module configuration file
--

-- Bindings for the tilings. 

defbindings("WTiling", {
    bdoc("Split current frame vertically."),
    kpress(META.."C", "WTiling.split_at(_, _sub, 'bottom', true)"),
    
    bdoc("Go to frame above/below/right/left of current frame."),
    kpress(META.."P", "ioncore.goto_next(_sub, 'up', {no_ascend=_})"),
    kpress(META.."N", "ioncore.goto_next(_sub, 'down', {no_ascend=_})"),
    kpress(META.."1", "ioncore.goto_next(_sub, 'left')"),

    kpress(WIN.."C",      "WRegion.rqclose(_)"),
    kpress(MPV..'minus', "WTiling.split_at(_, _sub, 'bottom', true)"),
    kpress(WIN..'5', "WTiling.split_at(_, _sub, 'left', true)"),
    kpress(MPV..'backslash', "WTiling.split_at(_, _sub, 'right', true)"),

    kpress(META..'minus', "WTiling.split_at(_, _sub, 'bottom', true)"),
    kpress(META..'backslash', "WTiling.split_at(_, _sub, 'right', true)"),

    bdoc("Forward-circulate focus.", "->frame"),
    kpress(META.."Tab", "WFrame.switch_next(_)"),

    bdoc("Backward-circulate focus.", "<-frame"),
    kpress(ALTMETA.."Tab", "WFrame.switch_prev(_)"),
    bdoc("flip frame", "<-frame"),
    kpress(WIN.."K", "WTiling.flip_at(_, _sub)"),

    submap(META.."K", {
        kpress("Tab", "ioncore.goto_next(_sub, 'left')"),
        
        bdoc("Split current frame horizontally."),
        kpress("M", "WTiling.split_at(_, _sub, 'bottom', true)"),
        
        bdoc("Destroy current frame."),
        kpress("X", "WTiling.unsplit_at(_, _sub)"),
    }),
})


-- Frame bindings.
--defbindings("WFrame.floating", {
--    bdoc("Tile frame, if no tiling exists on the workspace", "tile"),
--    kpress(ALTMETA.."B", "mod_tiling.mkbottom(_)"),
--})


-- Context menu for tiled workspaces.

defctxmenu("WTiling", "Tiling", {
    menuentry("Into rows", 
              "WTiling.split_at(_, _sub, 'bottom', true)"),
    menuentry("Into columns", 
              "WTiling.split_at(_, _sub, 'right', true)"),
    
    menuentry("Flip", "WTiling.flip_at(_, _sub)"),
    menuentry("Transpose", "WTiling.transpose_at(_, _sub)"),
    
    menuentry("Untile", "mod_tiling.untile(_)"),
    
    menuentry("Destroy frame", 
              "WTiling.unsplit_at(_, _sub)"),

    submenu("Float split", {
        menuentry("At left", 
                  "WTiling.set_floating_at(_, _sub, 'toggle', 'left')"),
        menuentry("At right", 
                  "WTiling.set_floating_at(_, _sub, 'toggle', 'right')"),
        menuentry("Above",
                  "WTiling.set_floating_at(_, _sub, 'toggle', 'up')"),
        menuentry("Below",
                  "WTiling.set_floating_at(_, _sub, 'toggle', 'down')"),
    }),

    submenu("At root", {
        menuentry("Into rows", 
                  "WTiling.split_top(_, 'bottom')"),
        menuentry("Into columns", 
                  "WTiling.split_top(_, 'right')"),
        menuentry("Flip", "WTiling.flip_at(_)"),
        menuentry("Transpose", "WTiling.transpose_at(_)"),
    }),
})


-- Extra context menu extra entries for floatframes. 

defctxmenu("WFrame.floating", "Floating frame", {
    append=true,
    -- menuentry("New tiling", "mod_tiling.mkbottom(_)"),
})

