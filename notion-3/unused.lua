
defbindings("WScreen", {
    bdoc("Go to previous screen on multihead setup.", "<-scr"),
    kpress(ALTMETA.."Escape", "ioncore.goto_prev_screen()"),
    bdoc("Go to next screen on multihead setup.", "->scr"),
    kpress(META.."Escape", "ioncore.goto_next_screen()"),

})
defbindings("WMPlex.toplevel", {

    bdoc("Run a terminal emulator.", "xterm"),
    --kpress(META.."Return", "mod_query.exec_on_merr(_, XTERM or 'xterm')"),
    --kpress("F2", "mod_query.exec_on_merr(_, XTERM or 'xterm')"),
 })
