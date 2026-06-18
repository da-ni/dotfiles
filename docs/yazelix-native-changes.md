# Yazelix Native Changes

This note tracks the changes that would be worth carrying in a small Yazelix fork or proposing upstream. It intentionally skips behavior that the base Yazelix config menu can already change, such as widget tray contents, tab label mode, ordinary custom popups, default mode, and normal keybinding choices.

## Goals

- Keep Yazelix visually aligned with Omarchy without patching generated runtime files after every refresh.
- Preserve the stock Yazelix layout behavior, pane swapping, side pane lifecycle, and command routing.
- Avoid taking ownership of user preferences that already belong in `~/.config/yazelix/settings.jsonc`.

## Native Changes Wanted

### Omarchy theme source

Add a first-class theme adapter that can read the active Omarchy theme and generate Yazelix theme artifacts from it. The adapter should cover Zellij, Yazi, Helix, and the embedded terminal in one place, including terminal font, cursor, and padding values inherited from the host terminal config.

This should replace the current local sync script's runtime patching of generated Zellij and Helix files.

### Explicit pane frame roles

Expose stable theme roles for active pane frame, inactive pane frame, and frame hover/highlight. The current setup needs those roles to map to:

- active frame: Omarchy foreground
- inactive frame: Omarchy `color2`
- hover/highlight frame: Omarchy accent

These should not be derived indirectly from unrelated palette slots inside generated runtime config.

### Optional built-in status bar

Add a real setting to disable the bottom Zellij key-hint/status bar while keeping Yazelix's generated layout intact. This needs to be implemented in the layout renderer rather than through a full layout override, because the override broke sidebar persistence and pane spawning behavior.

### Helix config layering

Make generated Helix config respect host-style editor preferences instead of forcing statusline and cursor-shape overrides. The desired behavior is to apply the selected theme and Yazelix-specific bindings while leaving editor appearance choices to the user's normal Helix configuration where possible.

### SERPL and Yazi editor tools

Provide supported Helix bindings for the article-style `Space q` workflow:

- open selected Yazi files in the current Helix view
- open selected Yazi files in vertical splits
- open selected Yazi files in horizontal splits
- run SERPL in a Zellij floating pane at the current workspace root

The implementation should avoid terminal output leaking back into Helix and should not depend on local wrapper scripts for command routing.
