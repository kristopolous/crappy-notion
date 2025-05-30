--
-- Menu module configuration
--

defbindings("WMenu", {
    bdoc("Close the menu."),
    kpress("Escape", "WMenu.cancel(_)"),
    kpress("Control+G", "WMenu.cancel(_)"),
    kpress("Control+C", "WMenu.cancel(_)"),
    kpress("Left", "WMenu.cancel(_)"),

    bdoc("Activate current menu entry."),
    kpress("Return",  "WMenu.finish(_)"),
    kpress("Control+M", "WMenu.finish(_)"),
    kpress("Right", "WMenu.finish(_)"),

    bdoc("Select next/previous menu entry."),
    kpress(WIN.."N", "WMenu.select_next(_)"),
    kpress(WIN.."P", "WMenu.select_prev(_)"),
    kpress("Up", "WMenu.select_prev(_)"),
    kpress("Down", "WMenu.select_next(_)"),

    bdoc("Clear the menu's typeahead find buffer."),
    kpress("BackSpace", "WMenu.typeahead_clear(_)"),
})
