-- check /usr/include/X11/keysymdef.h
function rename_frame(mplex)
  mod_query.query(mplex, notioncore.current():name() .. " > ", nil, function (mplex, v) 
    notioncore.current():set_name(v)
  end)
end

function clipcycle(dir)
  ioncore.exec("copyq "..dir)
  ioncore.exec('copyq popup clipboard "$(copyq clipboard)" 1000')
end

defbindings("WScreen", {
    kpress("Print",  "notioncore.exec_on(_, 'exec flameshot gui')"),
    kpress(WIN.."B", "mod_menu.menu(_, _sub, 'focuslist')"),
    bdoc("Switch to previous object (workspace, full screen client window) "..
         "within current screen.", "<-ws"),

    bdoc("Query for command line to execute.", "run"),
    kpress(WIN.."G", "mod_query.query_exec(_)"),
    kpress(WIN.."asciitilde", "WScreen.switch_prev(_)"),
    bdoc("ACPI suspend.", "run"),
    kpress(WIN.."F11", "notioncore.exec_on(_, 'sudo systemctl suspend')"),

    bdoc("Go to a specific client"),
    kpress(WIN.."space", "mod_query.query_gotoclient(_)"),

    bdoc("Query for Lua code to execute.", "lua"),
    kpress(WIN.."J", "mod_query.query_lua(_)"),

    bdoc("Query for workspace to go to or create a new one.", "+ws"),
    kpress(WIN.."9", "mod_query.query_workspace(_)"),

    bdoc("Query for a client window to go to.", "go"),

    kpress(WIN.."S", "WScreen.switch_prev(_)"),
    kpress(WIN.."D", "WScreen.switch_next(_)"),
    kpress(CALT.."BackSpace", "ioncore.restart()"),

    kpress(WIN.."Left", "ioncore.goto_next(_chld, 'left')", "_chld:non-nil"),
    kpress(WIN.."Right", "ioncore.goto_next(_chld, 'right')", "_chld:non-nil"),
    kpress(WIN.."Up", "ioncore.goto_next(_chld, 'up')", "_chld:non-nil"),
    kpress(WIN.."Down", "ioncore.goto_next(_chld, 'down')", "_chld:non-nil"),

    bdoc("Create a new workspace of chosen default type."),
    kpress(WIN.."equal", "ioncore.create_ws(_)"),

    bdoc("Display the main menu."),
    kpress(WIN.."F12", "mod_query.query_menu(_, _sub, 'mainmenu', 'Main menu:')"),
    mpress("Button3", "mod_menu.pmenu(_, _sub, 'mainmenu')"),

    bdoc("Display the window list menu."),
    mpress("Button2", "mod_menu.pmenu(_, _sub, 'windowlist')"),

    bdoc("Clip peek."),
    kpress(WIN.."F", "notioncore.exec_on(_, '/home/chris/bin/clip-peek')"),
    kpress(CWIN.."F", "notioncore.exec_on(_, '/home/chris/bin/clip-swap')"),
    kpress(SWIN.."F", "notioncore.exec_on(_, '/home/chris/bin/clip-paste')"),

    bdoc("Cycle through clipboard"),
    kpress(WIN.."bracketleft", "clipcycle('previous')"),
    kpress(WIN.."bracketright", "clipcycle('next')"),
    bdoc("Forward-circulate focus.", "->frame"),
    -- '_chld' used here stands to for an actual child window that may not
    -- be managed by the screen itself, unlike '_sub', that is likely to be
    -- the managing group of that window. The right/left directions are
    -- used instead of next/prev, because they work better in conjunction
    -- with tilings.
    -- kpress(CALT.."Tab", "ioncore.goto_next(_chld, 'right')", "_chld:non-nil"),
    kpress(CALT.."Tab", "ioncore.goto_activity() or ioncore.goto_previous(1)"),

    bdoc("Backward-circulate focus.", "<-frame"),
    kpress(CWIN.."Tab", "ioncore.goto_next(_chld, 'left')",
           "_chld:non-nil"),
    kpress(WIN.."Tab", "ioncore.goto_hop(1, 1)"), --ioncore.goto_next(_chld, 'right')", "_chld:non-nil"),
    kpress(CALT.."Tab", "ioncore.goto_next(_chld, 'right')", "_chld:non-nil"),

    bdoc("Backward-circulate focus.", "<-frame"),
    kpress(WIN.."W", "ioncore.goto_next(_chld, 'left')", "_chld:non-nil"),

    bdoc("Raise focused object, if possible.", "raise"),
    kpress(CALT.."R", "WRegion.rqorder(_chld, 'front')",
           "_chld:non-nil"),
})

-- Client window bindings
--
-- These bindings affect client windows directly.
defbindings("WClientWin", {
    bdoc("Nudge the client window. This might help with some "..
      "programs' resizing problems.", "nudge"),
    kpress_wait(WIN.."L", "WClientWin.nudge(_)"),

    bdoc("Kill client owning the client window.", "kill"),
    kpress(WIN.."C", "WClientWin.kill(_)"),
    kpress(CWIN.."C", "WClientWin.kill(_)"),

    bdoc("Send next key press to the client window. "..
         "Some programs may not allow this by default.", "quote"),
})

-- Client window group bindings
defbindings("WGroupCW", {
    bdoc("Toggle client window group full-screen mode", "fullscr"),
    kpress_wait(WIN.."Return", "WGroup.set_fullscreen(_, 'toggle')"),
})

-- WMPlex context bindings
--
-- These bindings work in frames and on screens. The innermost of such
-- contexts/objects always gets to handle the key press.
defbindings("WMPlex", {
    bdoc("Close current object.", "close"),
    kpress_wait(WIN.."C", "WRegion.rqclose_propagate(_, _sub)"),

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
    kpress("XF86MonBrightnessDown", "notioncore.exec_on(_, 'exec brightnessctl set 5-')"),
    kpress("XF86MonBrightnessUp", "notioncore.exec_on(_, 'exec brightnessctl set 5+')"),
    
    kpress(WIN.."T", "WRegion.set_tagged(_sub, 'toggle')", "_sub:non-nil"),
    kpress(WIN.."Q", "notioncore.exec_on(_, 'exec alacritty')"),
    kpress(WIN.."V", "notioncore.exec_on(_, 'exec /home/chris/code/llm-magic/llm-magic')"),

    bdoc("Clear all tags.", "-tags"),
    kpress(CWIN.."T", "ioncore.clear_tags()"),

    bdoc("Query for workspace to go to or create a new one.", "+ws"),
    kpress(WIN.."9", "mod_query.query_workspace(_)"),

    bdoc("Query for a client window to go to.", "go"),

    bdoc("Display context menu.", "ctx"),
    kpress(WIN.."M", "mod_menu.menu(_, _sub, 'ctxmenu')"),
    bdoc("Query for context menu.", "qctx"),
    kpress(CWIN.."M", "mod_query.query_menu(_, _sub, 'ctxmenu', 'Context menu:')"),

}) 

-- WFrame context bindings
--
-- These bindings are common to all types of frames. Some additional
-- frame bindings are found in some modules' configuration files.

defbindings("WFrame", {
    bdoc("Maximize the frame horizontally.", "hmax"),
    kpress(CALT.."H", "WFrame.maximize_horiz(_)"),
    bdoc("Maximize the frame vertically.", "vmax"),
    kpress(CALT.."V", "WFrame.maximize_vert(_)"),
    kpress(WIN.."1", "realmaximize(_)"),

    bdoc("Display context menu."),
    mpress("Button3", "mod_menu.pmenu(_, _sub, 'ctxmenu')"),

    bdoc("Rename", "rename"),
    kpress(WIN.."N",   "rename_frame(_)"),

    bdoc("Begin move/resize mode.", "resize"),
    kpress(WIN.."R", "WFrame.begin_kbresize(_)"),

    bdoc("Switch the frame to display the object indicated by the tab."),
    mclick("Button1@tab", "WFrame.p_switch_tab(_)"),
    mpress("Button2", "mod_menu.pmenu(_, _sub, 'windowlist')"),

    bdoc("Resize the frame."),
    mdrag("Button1@border", "WFrame.p_resize(_)"),
    mdrag(WIN.."Button3", "WFrame.p_resize(_)"),

    bdoc("Move the frame."),
    mdrag(WIN.."Button1", "WFrame.p_move(_)"),

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
    kpress(WIN.."Y", "ioncore.tagged_attach(_)"),
    submap(WIN.."K", {
        kpress("A", "ioncore.tagged_attach(_)"),
    }),


    bdoc("Move current tab to the right within the frame.", "tab->"),
    kpress(WIN.."comma", "WFrame.dec_index(_, _sub)", "_sub:non-nil"),
    bdoc("Move current tab to the left within the frame.", "tab<-"),
    kpress(WIN.."period", "WFrame.inc_index(_, _sub)", "_sub:non-nil"),

    bdoc("Switch to tab 0 in this frame.", "tab 0"),
    kpress(WIN.."F1", "WFrame.switch_nth(_, 0)"),
    bdoc("Switch to tab 1 in this frame.", "tab 1"),
    kpress(WIN.."F2", "WFrame.switch_nth(_, 1)"),
    bdoc("Switch to tab 2 in this frame.", "tab 2"),
    kpress(WIN.."F3", "WFrame.switch_nth(_, 2)"),
    bdoc("Switch to tab 3 in this frame.", "tab 3"),
    kpress(WIN.."F4", "WFrame.switch_nth(_, 3)"),
    bdoc("Switch to tab 4 in this frame.", "tab 4"),
    kpress(WIN.."F5", "WFrame.switch_nth(_, 4)"),

    kpress(WIN.."W", "WFrame.switch_prev(_)"),
    kpress(WIN.."E", "WFrame.switch_next(_)"),
})

-- Bindings for floating frames
defbindings("WFrame.floating", {
    bdoc("Toggle shade mode"),
    mdblclick("Button1@tab", "WFrame.set_shaded(_, 'toggle')"),

    bdoc("Raise the frame."),
    mpress("Button1@tab", "WRegion.rqorder(_, 'front')"),
    mpress("Button1@border", "WRegion.rqorder(_, 'front')"),
    mclick(WIN.."Button1", "WRegion.rqorder(_, 'front')"),

    --bdoc("Lower the frame."),
    --mclick(CALT.."Button3", "WRegion.rqorder(_, 'back')"),

    mdrag("Button1@tab", "WFrame.p_move(_)"),
})


-- WMoveresMode context bindings
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
    menuentry("Next",          "WScreen.switch_next(_)"),
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
})


-- Context menu for groups (workspaces, client windows)
defctxmenu("WGroup", "Group", {
    menuentry("Toggle tag",     "WRegion.set_tagged(_, 'toggle')"),
    menuentry("De/reattach",    "ioncore.detach(_, 'toggle')"),
    menuentry("Next",           "WScreen.switch_next(_:manager())"),
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

ioncore.get_hook("clientwin_unmapped_hook"):add(
  function() print("unmapped!") end
  )
