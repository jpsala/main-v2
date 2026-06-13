# AGENTS.md

Guide for agents working on `C:\dev\main\MainPortable`.

## Mission

`MainPortable` is a standalone AutoHotkey v2 toolkit meant to be copied to another PC. It starts with bookmarks and keyboard mouse movement, and will grow with small portable Windows automation features.

This project lives under `C:\dev\main\MainPortable` for discoverability, but it must remain portable. Do not import files from the parent repo or add `#Include` dependencies pointing outside this folder.

## Rules

- Keep the project portable: all runtime files should live beside `MainPortable.ahk` inside this folder after copying.
- Prefer one self-contained `MainPortable.ahk` until the file becomes clearly too large.
- If adding modules later, use relative includes and keep them inside this folder.
- Keep user-specific experiments in `user-custom.ahk`; it is auto-created, included, and watched for reload.
- Do not depend on user-local `config.ini` from the main automation repo.
- Use AutoHotkey v2 only.
- Preserve current hotkeys unless the user explicitly asks to change them.
- Validate syntax after edits:

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut /Validate "C:\dev\main\MainPortable\MainPortable.ahk"
```

## Current Surface

- Bookmarks: window save, activate, minimize, manager GUI, local INI persistence.
- Cursor movement: copied from main `hotkeys-global.ahk`; `CapsLock+h/j/k/l` sends arrows, `Alt+h/j/k/l` is gated by `cursorKeysEnabled`.
- Vim mode: ported from main `vim-mode.ahk` / `vim-keymap.ahk`; tap `LAlt`, `Alt+V`, or tray toggles it.
- Tray: icon, manager, save/reload/clean/clear, config/log/folder/help, suspend/exit.
- User custom layer: `user-custom.ahk` for personal portable hotkeys/functions.

## Icon

Tray menu item icons should visually match the main app. Keep copied PNG icons beside `MainPortable.ahk` so the folder remains copyable. The tray icon itself is `mainportable.ico`, downloaded from IconArchive. Source icon: Tulliana 2 `K control`, LGPL/open source.

Source page: https://www.iconarchive.com/show/tulliana-2-icons-by-umut-pulat/k-control-icon.html
