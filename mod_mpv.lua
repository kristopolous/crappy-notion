
keyList = { 'd', 's', '9', '0', 'space', 'Right', 'Left', 'Down', 'Up', 'comma', 'period', 'q', 'r', '3', '4', '5', 'p', 'u', 'Return'}
for i, key in ipairs(keyList) do
  defbindings("WScreen", {
     kpress(MPV..key, "notioncore.exec_on(_, '/home/chris/bin/mpv-control " .. key:lower() .. "')") 
  })
end
