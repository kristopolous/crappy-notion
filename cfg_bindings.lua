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

-- Stable sort key per frame: the object's address, fixed for its lifetime.
-- Used only to order frames that are otherwise tied (e.g. all at 0,0).
local function frame_key(f)
  return tonumber(tostring(f):match("0x(%x+)") or "0", 16) or 0
end

-- Spatial focus in direction dir ("left"/"right"/"up"/"down").
-- Bound on WScreen: _sub is the workspace. On a floating workspace the
-- frames are its managed children; on a tiled one, ws:current() is a WTiling.
--
-- Rule (floating): along the axis of travel, d = how far ahead a frame is.
--   * candidates: frames with d > 0, or frames at the exact same spot whose
--     key is "ahead" (bigger for right/down, smaller for left/up)
--   * pick the smallest (d, perpendicular distance, key)
--   * nothing ahead -> wrap to the far side, same ordering
-- So a pile of frames at the same position is walked one by one and then
-- left, and every step can be undone by the opposite arrow.
function spatial_goto(_chld, _sub, dir)
  local ws = _sub
  local ref = ws:current()
  if ref == nil then return nil end

  -- Start from the frame that really has focus. WTiling:current() and
  -- ws:current() can be stale (they lag behind the actual focus), which made
  -- navigation only work in one direction.
  local frame = ioncore.current()
  while frame and obj_typename(frame) ~= "WFrame" do frame = frame:manager() end
  if frame == nil then return nil end
  local mgr = frame:manager()
  local tiled = mgr ~= nil and obj_typename(mgr) == "WTiling"
  if mgr == nil then return nil end

  local horiz = (dir == "left" or dir == "right")
  local s = (dir == "right" or dir == "down") and 1 or -1
  local cg = frame:geom()
  local ca, cb = horiz and cg.x or cg.y, horiz and cg.y or cg.x
  local ck = s * frame_key(frame)

  local best, br
  local function better(r)
    if br == nil then return true end
    for i = 1, 3 do
      if r[i] ~= br[i] then return r[i] < br[i] end
    end
    return false
  end

  local function scan(wrap)
    mgr:managed_i(function(f)
      if f == frame then return true end
      if obj_typename(f) ~= "WFrame" then return true end
      local g = f:geom()
      local a, b = horiz and g.x or g.y, horiz and g.y or g.x
      local d = s * (a - ca)
      local perp = math.abs(b - cb)
      local k = s * frame_key(f)
      local r
      if wrap then
        r = {s * a, perp, k}
      elseif d > 0 or (not tiled and d == 0 and perp == 0 and k > ck) then
        r = {d, perp, k}
      end
      if r and better(r) then best, br = f, r end
      return true
    end)
  end

  scan(false)
  -- floating wraps around the screen edge; tiled just stops at the edge
  if best == nil and not tiled then scan(true) end

  local log = io.open("/tmp/spatial2.log", "a")
  if log then
    log:write(string.format("dir=%s from=%s @%d,%d -> %s\n", dir,
      tostring(frame), cg.x, cg.y, best and tostring(best) or "NONE"))
    log:close()
  end

  if best then
    if spatial_goto_notify then
      spatial_goto_notify(dir, frame, best:current() and best:current():current(), best)
    end
    best:goto_focus()
    if not tiled then best:rqorder("front") end
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

-- Move the focused frame by an exact number of pixels (dx, dy).
function nudge_frame(dx, dy)
  local f = notioncore.current()
  while f and obj_typename(f) ~= "WFrame" do f = f:parent() end
  if not f then return end
  local g = f:geom()
  f:rqgeom({x = g.x + dx, y = g.y + dy})
end

-- Keyboard modes for floating frames. While a mode is on, the arrow keys
-- call that mode's action on the frame;
-- Return or Escape (or the same WIN+key again) leaves the mode. The keys are
-- only bound while a mode is on, so terminals keep them otherwise.
--   move50 (WIN+I): move MOVE_STEP px per press
--   move6  (WIN+P): move 1/6 of the screen per press
--   shrink (WIN+R): shrink to 2/3 in that direction, holding that edge
local SHRINK = 2/3
local MOVE_STEP = 50
local TILED_STEP = 50    -- tiled WIN+R: divider moves this many px per press
local MODE_DIRS = {Left="left", Right="right", Up="up", Down="down"}
local MODE_KEYS = {"Left", "Right", "Up", "Down", "Return", "Escape"}
-- AnyModifier: the keys work whether or not WIN is still held down
local function mode_key(k) return "AnyModifier+" .. k end

local frame_mode_actions = {
  move50 = function(f, dir)
    local g = f:geom()
    local dx = (dir == "left" and -MOVE_STEP) or (dir == "right" and MOVE_STEP) or 0
    local dy = (dir == "up" and -MOVE_STEP) or (dir == "down" and MOVE_STEP) or 0
    f:rqgeom({x = g.x + dx, y = g.y + dy})
  end,
  -- snap the top-left to the next grid line 0/6, 1/6 ... 5/6 of the screen
  -- in that direction (a grid for floating windows, not a relative step)
  move6 = function(f, dir)
    local g, sg = f:geom(), f:screen_of():geom()
    local horiz = (dir == "left" or dir == "right")
    local size = horiz and sg.w or sg.h
    local pos = horiz and g.x or g.y
    local k = pos * 6 / size
    if dir == "right" or dir == "down" then
      k = math.floor(k + 1e-6) + 1
    else
      k = math.ceil(k - 1e-6) - 1
    end
    k = math.max(0, math.min(5, k))
    local v = math.floor(k * size / 6 + 0.5)
    if horiz then f:rqgeom({x = v}) else f:rqgeom({y = v}) end
  end,
  shrink = function(f, dir)
    local g = f:geom()
    if f:mode() ~= "floating" then
      -- tiled: the arrow moves the divider between this frame and its
      -- neighbour in that direction, by a fixed step, so Left then Right
      -- puts it back. Uses the right/bottom divider when there is one,
      -- otherwise the left/top one (frames against the screen edge).
      local tg = f:manager():geom()
      local horiz = (dir == "left" or dir == "right")
      local sign = (dir == "right" or dir == "down") and 1 or -1
      if horiz then
        local d = sign * TILED_STEP
        if g.x + g.w < tg.x + tg.w then
          f:rqgeom({x = g.x, y = g.y, w = g.w + d, h = g.h})
        elseif g.x > tg.x then
          f:rqgeom({x = g.x + d, y = g.y, w = g.w - d, h = g.h})
        end
      else
        local d = sign * TILED_STEP
        if g.y + g.h < tg.y + tg.h then
          f:rqgeom({x = g.x, y = g.y, w = g.w, h = g.h + d})
        elseif g.y > tg.y then
          f:rqgeom({x = g.x, y = g.y + d, w = g.w, h = g.h - d})
        end
      end
      return
    end
    local horiz = (dir == "left" or dir == "right")
    local far = (dir == "right" or dir == "down")   -- hold the far edge
    local function req(hold_far)
      if horiz then
        local w = math.floor(g.w * SHRINK)
        f:rqgeom({x = hold_far and (g.x + g.w - w) or g.x, y = g.y, w = w, h = g.h})
      else
        local h = math.floor(g.h * SHRINK)
        f:rqgeom({x = g.x, y = hold_far and (g.y + g.h - h) or g.y, w = g.w, h = h})
      end
    end
    req(far)
    -- tiled frames can't pull away from the screen edge; if nothing changed,
    -- shrink from the other side instead
    local n = f:geom()
    if n.w == g.w and n.h == g.h then req(not far) end
  end,
}

local frame_mode = nil
local frame_mode_target = nil      -- the frame the mode was started on
local frame_mode_saved_mf = nil    -- mousefocus setting to restore on exit

function frame_mode_set(name, f)
  if name == frame_mode then name = nil end   -- same hotkey toggles off
  local was = frame_mode
  frame_mode = name
  if name then
    -- lock onto the frame the mode started on, so moving/resizing it under
    -- the pointer can't hand the keys to another window
    if f then
      while f and obj_typename(f) ~= "WFrame" do f = f:manager() end
      frame_mode_target = f
    end
    if not was then
      -- pause sloppy mouse focus while the mode is on
      frame_mode_saved_mf = ioncore.get().mousefocus
      ioncore.set({mousefocus = "disabled"})
      for _, k in ipairs(MODE_KEYS) do
        defbindings("WFrame", { kpress(mode_key(k), "frame_mode_key(_, '"..k.."')") })
      end
    end
  else
    frame_mode_target = nil
    if frame_mode_saved_mf then
      ioncore.set({mousefocus = frame_mode_saved_mf})
      frame_mode_saved_mf = nil
    end
    -- always unbind on exit, even if our state got out of sync (e.g. after
    -- a config reload), so the keys can never stay stuck
    for _, k in ipairs(MODE_KEYS) do
      pcall(defbindings, "WFrame", { kpress(mode_key(k), nil) })
      pcall(defbindings, "WFrame", { kpress(k, nil) })
    end
  end
  print("frame mode: " .. tostring(name))
end

function frame_mode_key(f, key)
  if key == "Return" or key == "Escape" then return frame_mode_set(nil) end
  local act = frame_mode and frame_mode_actions[frame_mode]
  local dir = MODE_DIRS[key]
  if not (act and dir) then return end
  f = frame_mode_target or f
  if frame_mode == "shrink" or f:mode() == "floating" then act(f, dir) end
end

-- WIN+I compatibility name
function begin_frame_move_mode(f) frame_mode_set("move50", f) end

-- WIN+R: shrink mode, for floating and tiled frames.
function frame_resize_key(f)
  frame_mode_set("shrink", f)
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
    kpress(WIN.."R", "frame_resize_key(_)"),

    bdoc("Begin move-only mode for a floating window.", "move"),
    kpress(WIN.."I", "begin_frame_move_mode(_)"),

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

    bdoc("Begin 1/6-screen move mode.", "move6"),
    kpress(WIN.."P", "frame_mode_set('move6', _)"),

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
