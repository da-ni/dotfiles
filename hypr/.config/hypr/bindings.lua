-- Personal application and utility bindings loaded after Omarchy defaults.

-- TU Wien web apps replace Omarchy's default Signal, Email, and Music bindings.
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Matrix", [[omarchy-launch-or-focus-webapp "matrix.tuwien" "https://matrix.tuwien.ac.at"]])

hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Email", [[omarchy-launch-or-focus-webapp "mail.tuwien" "https://mail.tuwien.ac.at"]])

hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + ALT + E", "Gmail", [[omarchy-launch-or-focus-webapp "gmail.com" "https://gmail.com"]])

hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music", [[omarchy-launch-or-focus-webapp "YouTube Music" "https://music.youtube.com/"]])

-- Remote development.
hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + SHIFT + RETURN", "Quartz SSH", "ghostty -e ssh -L 29432:127.0.0.1:19432 hana@quartz")

o.bind("SUPER + SHIFT + Q", "Atrium", [[omarchy-launch-webapp "https://quartz.tailc1be0d.ts.net/"]])

-- AI and media web apps replace Omarchy's preinstalled choices.
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Claude", [[omarchy-launch-or-focus-webapp "claude.com" "https://claude.com"]])

hl.unbind("SUPER + SHIFT + ALT + A")
o.bind("SUPER + SHIFT + ALT + A", "ChatGPT", [[omarchy-launch-or-focus-webapp "chatgpt.com" "https://chatgpt.com"]])

hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "Netflix", [[omarchy-launch-or-focus-webapp "netflix.com" "https://www.netflix.com/"]])

-- Use the Menu key for toggle recording instead of F9 push-to-talk.
hl.unbind("F9")
hl.unbind("Menu")
o.bind("Menu", "Toggle dictation", "voxtype record toggle")
