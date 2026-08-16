-- US/German layouts, both Alt keys together switch layout, Caps is Compose.
hl.config({
  input = {
    kb_layout = "us,de",
    kb_options = "compose:caps,grp:alts_toggle",
    touchpad = {
      natural_scroll = true,
    },
  },
})

-- Three-finger horizontal swipe switches workspaces.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
