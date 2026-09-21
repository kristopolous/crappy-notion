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

-- Spatial focus in direction dir, purely by screen location (top-left).
-- Binding context for a WScreen keybinding:
--   _chld = _sub = the workspace (WGroupWS), whose geom is (0,0).
-- The currently focused frame is sub:current() (a WFrame managed by the
-- workspace). Its siblings are sub:managed_i.
-- For each direction we consider only frames strictly on that side of the
-- focused frame's top-left (e.g. "right" means g.x > cg.x), then among them
-- take the one with the smallest distance (closest). Exact same-position
-- frames are ignored (no location difference), so there is no loop and no
-- other bookkeeping. Navigating between separated frames is reversible: the
-- closest frame one way is the closest frame back.
function spatial_goto(_chld, _sub, dir)
  local ws = _sub
  local ref = ws:current()    -- WFrame (floating) or WTiling (tiled ws)
  local mgr, frame
  if ref ~= nil and obj_typename(ref) == "WTiling" then
    -- tiled: iterate the leaf frames managed by the tiling container
    mgr = ref
    frame = ref:current() or ref
  else
    -- floating: frames are managed directly by the workspace
    mgr = ws
    frame = ref
  end
  if frame == nil then return nil end

  -- the tiling also manages its status display; only actual frames navigate
  local function isframe(m)
    return (mgr == ws) or (obj_typename(m) == "WFrame")
  end

  local cg = frame:geom()     -- focused frame's top-left

  local log = io.open("/tmp/spatial2.log", "a")
  if log then
    log:write(string.format("dir=%s frame=%s geom=%d,%d mgr=%s\n",
      dir, tostring(frame), cg.x, cg.y, tostring(mgr)))
  end

  -- stack pass: frames sharing the focused frame's exact top-left form a
  -- stack. Co-located frames have no spatial order, so any arrow cycles the
  -- stack instead (right/down = next, left/up = previous) -- reach every
  -- window even when they all sit at e.g. (0,0).
  local stack = {}
  mgr:managed_i(function(f)
    if not isframe(f) then return true end
    local g = f:geom()
    if g.x == cg.x and g.y == cg.y then stack[#stack + 1] = f end
    return true
  end)

  local best
  local stacked = false
  if #stack > 1 then
    stacked = true
    local step = (dir == "right" or dir == "down") and 1 or -1
    for i, f in ipairs(stack) do
      if f == frame then
        local j = ((i - 1 + step) % #stack) + 1
        best = stack[j]
        if log then
          log:write(string.format("  STACK#%d -> %s\n",
            #stack, tostring(best)))
        end
        break
      end
    end
  else
    local bestd, bestperp
    local function pick(f, g, d, perp)
      if best == nil or d < bestd or (d == bestd and perp < bestperp) then
        best, bestd, bestperp = f, d, perp
        if log then
          log:write(string.format("  cand=%s geom=%d,%d d=%d\n",
            tostring(f), g.x, g.y, d))
        end
      end
    end

    -- natural pass: frames strictly ahead in the direction of travel
    mgr:managed_i(function(f)
      if not isframe(f) then return true end
      local g = f:geom()
      if f ~= frame and not (g.x == cg.x and g.y == cg.y) then
        local d, perp
        if     dir=="right" and g.x >  cg.x then d, perp = g.x - cg.x, math.abs(g.y - cg.y)
        elseif dir=="left"  and g.x <  cg.x then d, perp = cg.x - g.x, math.abs(g.y - cg.y)
        elseif dir=="down"  and g.y >  cg.y then d, perp = g.y - cg.y, math.abs(g.x - cg.x)
        elseif dir=="up"    and g.y <  cg.y then d, perp = cg.y - g.y, math.abs(g.x - cg.x)
        end
        if d then pick(f, g, d, perp) end
      end
      return true
    end)

    -- wrap pass: nothing ahead, so cross the axis seam -- cycle around to the
    -- far edge (top<->bottom, left<->right). Treat the plane like a torus:
    -- the wrapped target is the frame furthest opposite along the axis
    -- (smallest x for right, largest x for left, smallest y for down, largest
    -- y for up), then tie-break by perpendicular distance from the focus.
    if best == nil then
      mgr:managed_i(function(f)
        if not isframe(f) then return true end
        local g = f:geom()
        if f ~= frame and not (g.x == cg.x and g.y == cg.y) then
          local w, perp
          if     dir=="right" and g.x <  cg.x then w, perp =    g.x, math.abs(g.y - cg.y)
          elseif dir=="left"  and g.x >  cg.x then w, perp =   -g.x, math.abs(g.y - cg.y)
          elseif dir=="down"  and g.y <  cg.y then w, perp =    g.y, math.abs(g.x - cg.x)
          elseif dir=="up"    and g.y >  cg.y then w, perp =   -g.y, math.abs(g.x - cg.x)
          end
          if w then pick(f, g, w, perp) end
        end
        return true
      end)
    end
  end

  if log then
    log:write(string.format("  best=%s\n", best and tostring(best) or "NONE"))
    log:close()
  end

  if best then
    if spatial_goto_notify then
      local tgt = best:current():current()
      spatial_goto_notify(dir, frame, tgt, best)
    end
    best:goto_focus()
    if stacked then best:rqorder("front") end
  end
end

-- Jump `count` steps through the focus history (inactive client windows).
-- direction > 0 walks forward, < 0 walks backward. Pure-Lua replacement for
-- the fork's ioncore.goto_hop.
function goto_hop(count, direction)
  local hist = {}
  ioncore.focushistory_i(function(reg)
    if not reg:is_active() then hist[#hist + 1] = reg end
    return true
  end)
  if direction < 0 then
    local rev = {}
    for i = #hist, 1, -1 do rev[#rev + 1] = hist[i] end
    hist = rev
  end
  if #hist == 0 then return nil end
  local target = hist[count] or hist[#hist]
  if target then target:goto_focus() end
  return target
end

-- Move the focused frame by an exact number of pixels (dx, dy). Works on the
-- focused floating frame via rqgeom. Pure-Lua replacement for
-- WMoveresMode.nudge (which only existed inside the C modal move mode).
function nudge_frame(dx, dy)
  local c = notioncore.current()
  if not c then return end
  local f = c
  while f and not tostring(f):find("WFrame") do f = f:parent() end
  if not f then return end
  local g = f:geom()
  f:rqgeom({x = g.x + dx, y = g.y + dy})
end

-- Pure-Lua move-only mode, replacing WFrame.begin_kbmove. WIN+I toggles the
-- mode; while it is on, the arrow keys move the focused floating frame by
-- 50px each press. Escape or WIN+I turns it off. The arrow bindings are added
-- to / removed from the WFrame bindmap dynamically so keys are only grabbed
-- while the mode is active (terminals keep their arrows otherwise).
local fr_move_active = false
function begin_frame_move_mode()
  fr_move_active = not fr_move_active
  if fr_move_active then
    defbindings("WFrame", {
        kpress("Left",   "nudge_frame(-50, 0)"),
        kpress("Right",  "nudge_frame(50, 0)"),
        kpress("Up",     "nudge_frame(0, -50)"),
        kpress("Down",   "nudge_frame(0, 50)"),
        kpress("Escape", "begin_frame_move_mode()"),
    })
    ioncore.warn("MOVE MODE ON (arrows move frame; WIN+I/Escape off)")
  else
    for _, k in ipairs({"Left", "Right", "Up", "Down", "Escape"}) do
      defbindings("WFrame", { kpress(k, nil) })
    end
    ioncore.warn("MOVE MODE OFF")
  end
end

defbindings("WScreen", {
    bdoc("Focus the window currently under the mouse pointer.", "foc-ptr"),
    kpress(CWIN.."F12", "ioncore.focus_under_pointer()"),
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

    bdoc("Query for a binding", "go"),
    kpress(WIN.."h", "mod_query.query_binding(_, _sub)"),

    kpress(WIN.."Left", "spatial_goto(_chld, _sub, 'left')", "_chld:non-nil"),
    kpress(WIN.."Right", "spatial_goto(_chld, _sub, 'right')", "_chld:non-nil"),
    kpress(WIN.."Up", "spatial_goto(_chld, _sub, 'up')", "_chld:non-nil"),
    kpress(WIN.."Down", "spatial_goto(_chld, _sub, 'down')", "_chld:non-nil"),

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
    kpress(WIN.."Tab", "goto_hop(1, 1)"), --ioncore.goto_next(_chld, 'right')", "_chld:non-nil"),
    kpress(CALT.."Tab", "ioncore.goto_next(_chld, 'right')", "_chld:non-nil"),

    bdoc("Backward-circulate focus.", "<-frame"),
    kpress(WIN.."W", "ioncore.goto_next(_chld, 'left')", "_chld:non-nil"),

    bdoc("Raise focused object, if possible.", "raise"),
    kpress(CALT.."R", "WRegion.rqorder(_chld, 'front')",
           "_chld:non-nil"),

     -- MRU cycling for floating frames (alt+tab equivalent)
     bdoc("MRU cycle to next window"),
     kpress(SWIN.."Right", "mru_cycle_next(_)"),
     bdoc("MRU cycle to previous window"),
     kpress(SWIN.."Left", "mru_cycle_prev(_)"),
     bdoc("MRU cycle to next window (alternative)"),
     kpress(SWIN.."Down", "mru_cycle_next(_)"),
     bdoc("MRU cycle to previous window (alternative)"),
     kpress(SWIN.."Up", "mru_cycle_prev(_)"),
})

-- Client window bindings
--
-- These bindings affect client windows directly.
defbindings("WClientWin", {
    bdoc("Nudge the client window. This might help with some "..
      "programs' resizing problems.", "nudge"),
    -- kpress_wait(WIN.."L", "WClientWin.nudge(_)"),

    bdoc("Kill client owning the client window.", "kill"),
    kpress(WIN.."C", "WClientWin.kill(_)"),
    kpress(CWIN.."C", "WClientWin.kill(_)"),

    bdoc("Send next key press to the client window. "..
         "Some programs may not allow this by default.", "quote"),

    --kpress(WIN.."Button1", ""),  -- Dummy binding but forces event processing
    --menter("ioncore.goto_current(_sub)"),  -- The fix: handle enter
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
    kpress("XF86MonBrightnessDown", "notioncore.exec_on(_, 'exec brightnessctl set 5%-')"),
    kpress("XF86MonBrightnessUp", "notioncore.exec_on(_, 'exec brightnessctl set 5%+')"),
    
    kpress(WIN.."T", "WRegion.set_tagged(_sub, 'toggle')", "_sub:non-nil"),
    kpress(WIN.."Q", "notioncore.exec_on(_, 'exec alacritty')"),
    kpress(WIN.."V", "notioncore.exec_on(_, 'exec /home/chris/bin/llm-magic')"),

    bdoc("Clear all tags.", "-tags"),
    kpress(CWIN.."T", "ioncore.clear_tags()"),

    bdoc("Query for workspace to go to or create a new one.", "+ws"),
    kpress(WIN.."9", "mod_query.query_workspace(_)"),

    bdoc("Query for a client window to go to.", "go"),

    bdoc("Display context menu.", "ctx"),
    kpress(WIN.."M", "mod_menu.grabmenu(_, _sub, 'focuslist', {sizepolicy='center'})"),
    --kpress(WIN.."M", "mod_menu.menu(_, _sub, 'ctxmenu')"),
    bdoc("Query for context menu.", "qctx"),
    kpress(CWIN.."M", "mod_query.query_menu(_, _sub, 'ctxmenu', 'Context menu:')"),

}) 

-- WFrame context bindings
--
-- These bindings are common to all types of frames. Some additional
-- frame bindings are found in some modules' configuration files.

defbindings("WFrame", {
    bdoc("Ctrl+Win+click: focus the window under the pointer.", "foc-click"),
    mpress(CWIN.."Button1", "WRegion.goto_focus(_sub)"),
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

    bdoc("Begin move-only mode for a floating window.", "move"),
    kpress(WIN.."I", "begin_frame_move_mode()"),

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

    bdoc("Nudge move by 50px (j/k/l/i = left/down/right/up)."),
    kpress("J", "nudge_frame(-50, 0)"),
    kpress("K", "nudge_frame(0, 50)"),
    kpress("L", "nudge_frame(50, 0)"),
    kpress("I", "nudge_frame(0, -50)"),
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
