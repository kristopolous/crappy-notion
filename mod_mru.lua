-- MRU (Most Recently Used) Window Cycling for Floating Mode
-- Replaces spatial navigation with temporal focus history navigation

-- Track focus history for floating frames
local focus_history = {}
local history_index = 1
local max_history = 50
local last_reg=nil
local invalidate=nil
local mru_timer = ioncore.create_timer()

function diagnose(obj, name)
    name = name or "object"
    local t = type(obj)
    print(name .. " type:", t)
    
    if t == "userdata" or t == "table" then
        local mt = getmetatable(obj)
        if mt then
            print(name .. " metatable:")
            for k, v in pairs(mt) do
                print("  " .. k, type(v))
                -- If the value is a table (like __index), show its contents
                if k == "__index" and type(v) == "table" then
                    print("    Contents of __index:")
                    for method, val in pairs(v) do
                        print("      " .. method, type(val))
                    end
                end
            end
        else
            print(name .. " has no metatable")
        end
    end
    
    if t == "table" then
        print(name .. " contents:")
        for k, v in pairs(obj) do
            print("  " .. tostring(k), type(v), v)
        end
    end
    
    if t == "userdata" then
        print(name .. " value:", obj)
        local mt = getmetatable(obj)
        if mt and mt.__name then
            print(name .. " C type:", mt.__name)
        end
    end
end

-- Update focus history when a window is focused
function mru_track_focus(win)
  if not win then return end
  --print("-------")
  if win.xid == nil then return end
  local mt = getmetatable(win)
  local idx = mt.__index
  if idx.__typename ~= "WClientWin" then return end
  last_reg = win
  old_index = -1 
  for i, id in ipairs(focus_history) do
    if id == win then
      old_index = i

      if i < history_index then
        history_index = history_index - 1
      end

      break
    end
  end
  
  mru_timer:set(300, function()
    if invalidate then
      invalidate = nil
    elseif win == last_reg then
      last_reg=idx
      print("Inserting ... " .. win:xid())

      if old_index ~= -1 then
        table.remove(focus_history, old_index)
      end

      table.insert(focus_history, 1, win)

      history_index = 1
      
      if #focus_history > max_history then
        table.remove(focus_history)
      end
    end
  end)
end

function mru_cycle(dir)
  print("MRU: cycle " .. dir .. " " .. history_index .. " " .. #focus_history)
  if #focus_history == 0 then return end
  local current_region = ioncore.current()
  invalidate = 1
  
  -- Try to find next valid window
  local attempts = 0
  while attempts < #focus_history do
    history_index = history_index + dir
    if history_index > #focus_history then
      history_index = 1
    elseif history_index < 1 then
      history_index = #focus_history
    end
    
    local win = focus_history[history_index]
    
    if win then
      -- Use pcall to handle dead objects which throw errors instead of nil
      local success, xid = pcall(function() return win:xid() end)
      
      if success then
        WRegion.goto_focus(win)
        return
      else
        -- Object is dead, remove it from history
        print("MRU: removing dead window")
        table.remove(focus_history, history_index)
        
        -- The table shifted, so the next valid window is now at history_index 
        -- again. Decrement attempts to check this one immediately.
        attempts = attempts - 1
      end
    end
 
    attempts = attempts + 1
  end
  print("MRU: no valid window found to cycle to")
end

function mru_cycle_next()
  mru_cycle(1)
end

function mru_cycle_prev()
  mru_cycle(-1)
end

-- Hook into focus changes
local hook = ioncore.get_hook("region_notify_hook")
if hook then
  hook:add(function(reg, how)
    if how == "activated" or how == "pseudoactivated" then
      ioncore.defer(function()
        mru_track_focus(reg)
      end)
    end
  end)
end
