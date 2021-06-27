
-- Put all dockapps in the statusbar's systray, also adding the missing size
-- hints necessary for this to work.
defwinprop {
    is_dockapp = true,
    statusbar = "systray",
    max_size = { w = 64, h = 64},
    min_size = { w = 64, h = 64},
}

-- Make an exception for Docker, which sets correct size hints.
defwinprop {
    is_dockapp = true,
    class = "Docker",
    statusbar = "systray",
}

-- https://sourceforge.net/tracker/?func=detail&aid=3471910&group_id=314802&atid=1324528
defwinprop {
    class = "Gimp",
    acrobatic = true,
}


-- Define some additional title shortening rules to use when the full title
-- doesn't fit in the available space. The first-defined matching rule that
-- succeeds in making the title short enough is used.
ioncore.defshortening("(.*) - Mozilla(<[0-9]+>)", "$1$2$|$1$<...$2")
ioncore.defshortening("(.*) - Mozilla", "$1$|$1$<...")
ioncore.defshortening("[^:]+: (.*)(<[0-9]+>)", "$1$2$|$1$<...$2")
ioncore.defshortening("[^:]+: (.*)", "$1$|$1$<...")
ioncore.defshortening("(.*)(<[0-9]+>)", "$1$2$|$1$<...$2")
ioncore.defshortening("(.*)", "$1$|$1$<...")
