-- WIN+b n        Go to bookmark n (n=0..9)
-- WIN+b Shift+n  Set bookmark n
--

local bms={}
bookmarks={}

function bookmarks.set(bm, frame)
    bms[bm]=frame
end

function bookmarks.goto_bm(bm)
    if bms[bm] then
        bms[bm]:goto_focus()
    end
end

for k=2, 9 do
    local bm=tostring(k)
    defbindings("WScreen", {
        kpress(WIN..bm, function() bookmarks.goto_bm(bm) end),
    })
    defbindings("WClientWin", {
        submap(WIN.."T", {
            kpress(bm, function(frame) bookmarks.set(bm, frame) end),
        })
    })
end

