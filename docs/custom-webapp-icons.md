# Custom Webapp Icons (Waybar + Hyprland)

When a custom web app shows a generic icon in Waybar, add matching desktop entries so the window class resolves to the app icon.

## Why this works

Waybar/Hyprland app icon lookup is tied to desktop metadata (`.desktop`) and window class (`StartupWMClass`).

For Chromium-based app windows, the class is typically:

`chrome-<host>__-Default`

Example for `https://music.youtube.com`:

`chrome-music.youtube.com__-Default`

## Steps

1. Create a visible launcher entry in `~/.local/share/applications/`:

```ini
[Desktop Entry]
Version=1.0
Name=YouTube Music
Comment=YouTube Music
Exec=omarchy-launch-webapp https://music.youtube.com
Terminal=false
Type=Application
Icon=/home/dn/.local/share/applications/icons/YouTube.png
StartupNotify=true
StartupWMClass=chrome-music.youtube.com__-Default
```

2. Create a matching hidden Chromium-class entry:

```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=YouTube Music
Comment=YouTube Music
Exec=omarchy-launch-webapp https://music.youtube.com
Icon=/home/dn/.local/share/applications/icons/YouTube.png
Terminal=false
NoDisplay=true
```

Save it as:

`~/.local/share/applications/chrome-music.youtube.com__-Default.desktop`

3. Refresh desktop DB and restart Waybar:

```bash
update-desktop-database ~/.local/share/applications
omarchy-restart-waybar
```

4. If app was already open, fully close and reopen it once.

## Quick checks

- Confirm files exist in `~/.local/share/applications/`.
- Confirm `Icon=` points to a real image file.
- Confirm `StartupWMClass=` matches the actual app class exactly.
