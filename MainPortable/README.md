# MainPortable

Portable AutoHotkey v2 toolkit for a second PC or a clean Windows setup.

Canonical workspace location: `C:\dev\main\MainPortable`.

## Files

- `MainPortable.ahk`: entrypoint.
- `MainPortable.ini`: local runtime config, generated on first run.
- `MainPortable.log`: local error log, generated when needed.
- `mainportable.ico`: tray icon from Tulliana 2 `K control`, LGPL/open source, downloaded via IconArchive.
- Companion PNGs: tray menu item icons copied from the main app so the portable menu matches the main application.
- `user-custom.ahk`: personal portable extensions. It is auto-created if missing, included by `MainPortable.ahk`, and watched for auto-reload.

## Current Features

- Window bookmarks with direct hotkeys and sequential bookmarks.
- Bookmark manager GUI with search and quick activation.
- Cursor-key layer copied from the main project.
- Optional Vim mode for keyboard navigation.
- Tray menu for common maintenance actions.
- Personal custom hotkeys/functions through `user-custom.ahk`.

## Main Hotkeys

- `Ctrl+Shift+Alt+B`: show bookmarks manager.
- `Win+S`, then a key: create/toggle sequential bookmark.
- `Win+Shift+S`, then a key: reassign sequential bookmark.
- Direct bookmark hotkey: activate/minimize saved window.
- `Shift+direct bookmark hotkey`: assign active window.
- `CapsLock+h/j/k/l`: arrow keys.
- `CapsLock+g/;`: Home/End.
- `CapsLock+d`: Delete.
- `Alt+h/j/k/l`: arrow keys when cursor keys are enabled.
- `Alt+Shift+h/l`: Home/End.
- `Alt+Shift+j/k`: PageDown/PageUp.
- `Win+Alt+K`: toggle Alt cursor keys.
- `CapsLock+Esc`: toggle CapsLock cursor layer.
- `Alt+V`: toggle Vim mode.
- Vim mode keys: `h/j/k/l` arrows, `w/b` word movement, `0/$` line start/end, `g/Alt+g` document start/end, `x` delete, `i` or `Esc` exits.

## Portability

Copy the whole `MainPortable` folder to another PC and run `MainPortable.ahk` with AutoHotkey v2.

Keep generated local state (`MainPortable.ini`) next to the script unless you intentionally want a fresh machine profile.

## Working Model

This folder is part of the main repo only so agents can discover and maintain it. The script itself must stay standalone and copyable as a folder.

Put your own one-off hotkeys in `user-custom.ahk`. Save it and MainPortable reloads automatically.
