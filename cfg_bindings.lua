function rename_frame(mplex)
  mod_query.query(mplex, notioncore.current():name() .. " > ", nil, function (mplex, v) 
    notioncore.current():set_name(v)
  end)
end

defbindings("WScreen", {
    submap(CALT.."O", {
        bdoc("Open first region demanding attention or previously active one."),
        kpress("O", "mod_menu.grabmenu(_, _sub, 'focuslist')"),
        -- Alternative without (cyclable) menu
        --kpress("O", "ioncore.goto_activity() or ioncore.goto_previous()"),

        --bdoc("Go to previous active object."),
        --kpress("O", "ioncore.goto_previous()"),

        --bdoc("Go to first object on activity/urgency list."),
        --kpress("I", "ioncore.goto_activity()"),

    }),

    kpress(CALT.."S", "WScreen.switch_prev(_)"),
    --kpress(CALT.."F", "WScreen.switch_next(_)"),
    kpress(CALT.."D", "WScreen.switch_next(_)"),
    kpress(CALT.."BackSpace", "ioncore.restart()"),

    kpress(CALT.."Left", "ioncore.goto_next(_chld, 'left')", "_chld:non-nil"),
    kpress(CALT.."Right", "ioncore.goto_next(_chld, 'right')", "_chld:non-nil"),
    kpress(CALT.."Up", "ioncore.goto_next(_chld, 'up')", "_chld:non-nil"),
    kpress(CALT.."Down", "ioncore.goto_next(_chld, 'down')", "_chld:non-nil"),


    bdoc("Create a new workspace of chosen default type."),
    kpress(CALT.."equal", "ioncore.create_ws(_)"),

    bdoc("Display the main menu."),
    kpress(CWIN.."F12", "mod_query.query_menu(_, _sub, 'mainmenu', 'Main menu:')"),
    mpress("Button3", "mod_menu.pmenu(_, _sub, 'mainmenu')"),

    bdoc("Display the window list menu."),
    mpress("Button2", "mod_menu.pmenu(_, _sub, 'windowlist')"),

    bdoc("Forward-circulate focus.", "->frame"),
    -- '_chld' used here stands to for an actual child window that may not
    -- be managed by the screen itself, unlike '_sub', that is likely to be
    -- the managing group of that window. The right/left directions are
    -- used instead of next/prev, because they work better in conjunction
    -- with tilings.
    kpress(CALT.."Tab", "ioncore.goto_next(_chld, 'right')",
           "_chld:non-nil"),

    bdoc("Backward-circulate focus.", "<-frame"),
    kpress(CWIN.."Tab", "ioncore.goto_next(_chld, 'left')",
           "_chld:non-nil"),

    bdoc("Raise focused object, if possible.", "raise"),
    kpress(CWIN.."R", "WRegion.rqorder(_chld, 'front')",
           "_chld:non-nil"),
})


-- Client window bindings
--
-- These bindings affect client windows directly.

defbindings("WClientWin", {
    bdoc("Nudge the client window. This might help with some "..
      "programs' resizing problems.", "nudge"),
    kpress_wait(CWIN.."L", "WClientWin.nudge(_)"),

    bdoc("Kill client owning the client window.", "kill"),
    kpress(CWIN.."4", "WClientWin.kill(_)"),

    bdoc("Send next key press to the client window. "..
         "Some programs may not allow this by default.", "quote"),
    kpress(CWIN.."Q", "WClientWin.quote_next(_)"),
})


-- Client window group bindings

defbindings("WGroupCW", {
    bdoc("Toggle client window group full-screen mode", "fullscr"),
    kpress_wait(CALT.."Return", "WGroup.set_fullscreen(_, 'toggle')"),
})


-- WMPlex context bindings
--
-- These bindings work in frames and on screens. The innermost of such
-- contexts/objects always gets to handle the key press.

defbindings("WMPlex", {
    bdoc("Close current object.", "close"),
    kpress_wait(CALT.."C", "WRegion.rqclose_propagate(_, _sub)"),

    bdoc("Detach (float) or reattach an object to its previous location.", "detach"),
    -- By using _chld instead of _sub, we can detach/reattach queries
    -- attached to a group. The detach code checks if the parameter
    -- (_chld) is a group 'bottom' and detaches the whole group in that
    -- case.
    -- kpress(CWIN.."D", "ioncore.detach(_chld, 'toggle')", "_chld:non-nil"),
})

-- Frames for transient windows ignore this bindmap

defbindings("WMPlex.toplevel", {
    bdoc("Toggle tag of current object.", "tag"),
    kpress(CALT.."T", "WRegion.set_tagged(_sub, 'toggle')", "_sub:non-nil"),
    kpress(CALT.."Q", "notioncore.exec_on(_, XTERM or 'exec xterm -bg rgb:0/0/0 -fg white')"),

    bdoc("Clear all tags.", "-tags"),
    kpress(CWIN.."T", "ioncore.clear_tags()"),

    bdoc("Query for command line to execute.", "run"),
    kpress(CALT.."G", "mod_query.query_exec(_)"),

    bdoc("Query for Lua code to execute.", "lua"),
    kpress(CALT.."J", "mod_query.query_lua(_)"),

    bdoc("Query for keybinding.", "qkb"),
    kpress(CALT.."slash", "mod_query.query_binding(_, _sub)"),

    bdoc("Query for workspace to go to or create a new one.", "+ws"),
    kpress(CWIN.."9", "mod_query.query_workspace(_)"),

    bdoc("Query for a client window to go to.", "go"),
    kpress(CALT.."space", "mod_query.query_gotoclient(_)"),

    bdoc("Display context menu.", "ctx"),
    kpress(CALT.."M", "mod_menu.menu(_, _sub, 'ctxmenu')"),
    bdoc("Query for context menu.", "qctx"),
    kpress(CWIN.."M", "mod_query.query_menu(_, _sub, 'ctxmenu', 'Context menu:')"),

}) 

-- WFrame context bindings
--
-- These bindings are common to all types of frames. Some additional
-- frame bindings are found in some modules' configuration files.

defbindings("WFrame", {
    kpress(CALT.."2", "realmaximize(_)"),

    bdoc("Display context menu."),
    mpress("Button3", "mod_menu.pmenu(_, _sub, 'ctxmenu')"),

    bdoc("Begin move/resize mode.", "resize"),
    kpress(CALT.."R", "WFrame.begin_kbresize(_)"),

    bdoc("Switch the frame to display the object indicated by the tab."),
    mclick("Button1@tab", "WFrame.p_switch_tab(_)"),
    mpress("Button2", "mod_menu.pmenu(_, _sub, 'windowlist')"),

    bdoc("Resize the frame."),
    mdrag("Button1@border", "WFrame.p_resize(_)"),
    mdrag(CALT.."Button3", "WFrame.p_resize(_)"),

    bdoc("Move the frame."),
    mdrag(CALT.."Button1", "WFrame.p_move(_)"),

    bdoc("Move objects between frames by dragging and dropping the tab."),
    mdrag("Button1@tab", "WFrame.p_tabdrag(_)"),
    mdrag("Button2@tab", "WFrame.p_tabdrag(_)"),
})

-- Frames for transient windows ignore this bindmap

defbindings("WFrame.toplevel", {
    bdoc("Attach tagged objects to this frame.", "nick"),
    kpress(CALT.."N", "ioncore.tagged_attach(_)"),
    bdoc("Query for a client window to attach ('nick').", "qnick"),
    kpress(CWIN.."N", "mod_query.query_attachclient(_)"),
    submap(CALT.."K", {
        kpress("A", "ioncore.tagged_attach(_)"),
    }),

    bdoc("Switch to tab 0 in this frame.", "tab 0"),
    kpress(CALT.."A", "WFrame.switch_nth(_, 0)"),
    bdoc("Switch to tab 1 in this frame.", "tab 1"),
    kpress(CALT.."F", "WFrame.switch_nth(_, 3)"),

    bdoc("Move current tab to the right within the frame.", "tab->"),
    kpress(CALT.."comma", "WFrame.dec_index(_, _sub)", "_sub:non-nil"),
    bdoc("Move current tab to the left within the frame.", "tab<-"),
    kpress(CALT.."period", "WFrame.inc_index(_, _sub)", "_sub:non-nil"),

    kpress(CALT.."1", "WFrame.switch_prev(_)"),
    kpress(CALT.."W", "WFrame.switch_prev(_)"),
    kpress(CALT.."E", "WFrame.switch_next(_)"),
})

-- Bindings for floating frames

defbindings("WFrame.floating", {
    bdoc("Toggle shade mode"),
    mdblclick("Button1@tab", "WFrame.set_shaded(_, 'toggle')"),

    bdoc("Raise the frame."),
    mpress("Button1@tab", "WRegion.rqorder(_, 'front')"),
    mpress("Button1@border", "WRegion.rqorder(_, 'front')"),
    mclick(CALT.."Button1", "WRegion.rqorder(_, 'front')"),

    --bdoc("Lower the frame."),
    --mclick(CALT.."Button3", "WRegion.rqorder(_, 'back')"),

    bdoc("Move the frame."),
    mdrag("Button1@tab", "WFrame.p_move(_)"),
})


-- WMoveresMode context bindings
--
-- These bindings are available keyboard move/resize mode. The mode
-- is activated on frames with the command begin_kbresize (bound to
-- CALT.."R" above by default).

defbindings("WMoveresMode", {
    bdoc("Cancel the resize mode."),
    kpress("AnyModifier+Escape","WMoveresMode.cancel(_)"),

    bdoc("End the resize mode."),
    kpress("AnyModifier+Return","WMoveresMode.finish(_)"),

    bdoc("Grow in specified direction."),
    kpress("Left",  "WMoveresMode.resize(_, 1, 0, 0, 0)"),
    kpress("Right", "WMoveresMode.resize(_, 0, 1, 0, 0)"),
    kpress("Up",    "WMoveresMode.resize(_, 0, 0, 1, 0)"),
    kpress("Down",  "WMoveresMode.resize(_, 0, 0, 0, 1)"),
    kpress("F",     "WMoveresMode.resize(_, 1, 0, 0, 0)"),
    kpress("B",     "WMoveresMode.resize(_, 0, 1, 0, 0)"),
    kpress("P",     "WMoveresMode.resize(_, 0, 0, 1, 0)"),
    kpress("N",     "WMoveresMode.resize(_, 0, 0, 0, 1)"),

    bdoc("Shrink in specified direction."),
    kpress("Shift+Left",  "WMoveresMode.resize(_,-1, 0, 0, 0)"),
    kpress("Shift+Right", "WMoveresMode.resize(_, 0,-1, 0, 0)"),
    kpress("Shift+Up",    "WMoveresMode.resize(_, 0, 0,-1, 0)"),
    kpress("Shift+Down",  "WMoveresMode.resize(_, 0, 0, 0,-1)"),
    kpress("Shift+F",     "WMoveresMode.resize(_,-1, 0, 0, 0)"),
    kpress("Shift+B",     "WMoveresMode.resize(_, 0,-1, 0, 0)"),
    kpress("Shift+P",     "WMoveresMode.resize(_, 0, 0,-1, 0)"),
    kpress("Shift+N",     "WMoveresMode.resize(_, 0, 0, 0,-1)"),

    bdoc("Move in specified direction."),
    kpress(CALT.."Left",  "WMoveresMode.move(_,-1, 0)"),
    kpress(CALT.."Right", "WMoveresMode.move(_, 1, 0)"),
    kpress(CALT.."Up",    "WMoveresMode.move(_, 0,-1)"),
    kpress(CALT.."Down",  "WMoveresMode.move(_, 0, 1)"),
    kpress(CALT.."F",     "WMoveresMode.move(_,-1, 0)"),
    kpress(CALT.."B",     "WMoveresMode.move(_, 1, 0)"),
    kpress(CALT.."P",     "WMoveresMode.move(_, 0,-1)"),
    kpress(CALT.."N",     "WMoveresMode.move(_, 0, 1)"),
})

-- Main menu
defmenu("mainmenu", {
    menuentry("Run...",         "mod_query.query_exec(_)"),
    menuentry("Terminal",       "mod_query.exec_on_merr(_, XTERM or 'xterm')"),
    submenu("Windows",          "windowlist"),
    submenu("Session",          "sessionmenu"),
})


-- Session control menu
defmenu("sessionmenu", {
    menuentry("Save",           "ioncore.snapshot()"),
    menuentry("Restart",        "ioncore.restart()"),
    menuentry("Exit",           "ioncore.shutdown()"),
})


-- Context menu (frame actions etc.)
defctxmenu("WFrame", "Frame", {
    -- Note: this propagates the close to any subwindows; it does not
    -- destroy the frame itself, unless empty. An entry to destroy tiled
    -- frames is configured in cfg_tiling.lua.
    menuentry("Close",          "WRegion.rqclose_propagate(_, _sub)"),
    menuentry("Rename",         "rename_frame(_)"),
    -- Low-priority entries
    menuentry("Attach tagged", "ioncore.tagged_attach(_)", { priority = 0 }),
    menuentry("Clear tags",    "ioncore.clear_tags()", { priority = 0 }),
    menuentry("Window info",   "mod_query.show_tree(_, _sub)", { priority = 0 }),
    submenu("Misc",          "miscmenu"),
})

defmenu("miscmenu", {
    menuentry("Key binding",    "mod_query.query_binding(_, _sub)"),
    menuentry("Run",        "mod_query.query_exec(_)"),
    menuentry("Lua",        "mod_query.query_lua(_)"),
})

-- Context menu for groups (workspaces, client windows)
defctxmenu("WGroup", "Group", {
    menuentry("Toggle tag",     "WRegion.set_tagged(_, 'toggle')"),
    menuentry("De/reattach",    "ioncore.detach(_, 'toggle')"),
})


-- Context menu for workspaces
defctxmenu("WGroupWS", "Workspace", {
    menuentry("Close",          "WRegion.rqclose(_)"),
    menuentry("Attach tagged",  "ioncore.tagged_attach(_)"),
})


-- Context menu for client windows
defctxmenu("WClientWin", "Client window", {
    menuentry("Kill",           "WClientWin.kill(_)"),
})
