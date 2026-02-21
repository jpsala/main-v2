# Main - AutoHotkey v2 Automation Suite

Personal workflow automation framework built in **AutoHotkey v2**. Orchestrated by `main.ahk` which includes 23 modules in a specific load order.

## Language & Syntax

- **AutoHotkey v2** (NOT v1). Key differences from v1:
  - Functions use parentheses: `MsgBox('text')` not `MsgBox, text`
  - Variables don't use `%`: use `myVar` not `%myVar%`
  - Strings use single quotes `'text'` (preferred) or double quotes `"text"`
  - Objects use `{key: value}`, arrays use `[item1, item2]`
  - `#HotIf` replaces `#IfWinActive`
  - Use `SendMode("Input")` not `SendMode, Input`

## Architecture

### Module Load Order (main.ahk)
Modules are loaded in this exact order. Dependencies flow top-down:

1. `msg.ahk` - Tooltip/notification queue system
2. `functions.ahk` - Core utility library (1200+ lines). All shared functions live here
3. `roa.ahk` - Window management: `Roa()`, `RoAWithPattern()`, `toggleOrLaunchApp()`
4. `init.ahk` - Config loading, machine detection, timers, file monitoring
5. `bookmarks.ahk` - Win+key window bookmarking with persistence
6. `menus.ahk` - App launcher menus (`#a`, `#w`, `#c`) and context menus
7. `code.ahk` - VS Code / Cursor editor hotkeys
8. `browser.ahk` - Chrome/Vivaldi hotkeys
9. `keyboardSwitch.ahk` - Auto keyboard layout switching (US/INTL)
10. `hotstrings.ahk` - Text replacements and snippets
11. `system.ahk` - System-wide hotkeys and instance tracking init
12. `chrome.ahk` - Chrome-specific hotkeys
13. `terminal.ahk` - Terminal hotkeys
14. `media.ahk` - Media app hotkeys
15. `hotkeys-global.ahk` - Global hotkeys (brightness, cursor nav, clipboard)
16. `menu.ahk` - Enhanced menu engine with GUI/keyboard support

### Key Subsystems

- **Window Management**: `Roa(alias, launchCmd, bookmark)` for alias-based activate/launch. `RoAWithPattern()` for title-matching. `toggleOrLaunchApp()` for generic toggle/launch
- **Menu System**: `customMenu(options)` with keyboard-first navigation + GUI fallback after `waitml` ms
- **Config**: `config.ini` with device-specific sections (`[desktop]`, `[notebook]`, `[gordos]`, `[work]`, `[carnival]`)
- **Persistence**: `appInstanceMap`, `aliasMap`, `bookmarkMap` saved to config.ini on exit

## Conventions

### Adding Hotkeys

- **App-specific hotkeys**: Use `#HotIf WinActive('ahk_exe appname.exe')` blocks in the corresponding module file
- **Global hotkeys**: Add to `hotkeys-global.ahk`
- **System hotkeys**: Add to `system.ahk`
- Hotkey notation: `#` = Win, `!` = Alt, `^` = Ctrl, `+` = Shift

### Adding Hotstrings

- Add to `hotstrings.ahk`
- Use `:*:` for immediate trigger (no ending char needed)
- Use `:?:` for trigger even inside words
- Use `:C:` for case-sensitive
- Pattern: `:*:.shortcut:: { SendText('expansion') }`

### Adding Menu Items

Menus are in `menus.ahk`. Three main menus:
- `#a` → `mainSeqA()` - Apps & utilities
- `#w` → `mainSeqW()` - Browser & web
- `#c` → `mainSeqC()` - Code & development

To add an item:
1. Add `{ key: 'KEY', label: 'Label' }` to the `items` array
2. Add `case 'KEY':` to the switch statement
3. For submenus: use `{ key: 'KEY', label: 'Label', items: [...] }` and prefix case keys (e.g., parent `s` + child `c` = case `'sc'`)

### Adding a New Module

1. Create `modulename.ahk` in root directory
2. Add `#Include ".\modulename.ahk"` to `main.ahk` (order matters - after dependencies)
3. Use `#HotIf WinActive(...)` for app-specific hotkeys
4. Close context with `#HotIf` (no condition) at end of block
5. Add the file to `filesToCheckForReload` array in `init.ahk` for auto-reload

### Launching/Activating Apps

- **Preferred**: `Roa('alias-name', 'launch command', '#bookmark')` - alias-based, persistent
- **Pattern-based**: `RoAWithPattern('window title', 'launch command')` - title matching
- **Toggle**: `toggleOrLaunchApp({winPattern: '...', launchCmd: '...'})` - with callbacks
- **Multi-instance**: `toggleOrLaunchAppByUid({...})` - strict UID tracking, no pattern fallback

### Naming

- Functions: `camelCase`
- Global variables: `camelCase`
- Menu function names: `mainSeqX()` where X is the hotkey letter
- Aliases (for Roa): `kebab-case` (e.g., `'vivaldi-main'`, `'obsidian-ai'`)
- Config sections: `[lowercase]`

## Key Global Variables

- `cursorExe`, `vscodeExe`, `vivaldiExe` - App paths from config
- `vivaldiWithMainProfile`, `vivaldiWithAIProfile`, etc. - Browser launch commands with profiles
- `chromeWithWorkProfile`, `chromeWithDebugProfile` - Chrome profiles
- `deviceSection` - Current machine identifier (`desktop`/`notebook`/`gordos`/`work`/`carnival`)
- `isNotebook`, `isRemote`, `isGordos`, `isWork` - Machine detection booleans
- `activeGroup`, `mode` - Current state flags
- `tvWin`, `activeTradeWin` - Trading window patterns
- `xyploreExe`, `nircmdExe` - Tool paths

## Important Notes

- Script auto-reloads when any `.ahk` file is modified (monitored by `init.ahk`)
- Do NOT run as Administrator (main.ahk warns about this)
- `config.ini` is UTF-16LE encoded - be careful when editing programmatically
- API keys in `hotstrings.ahk` are sensitive - never log or expose them
- The `menu.ahk` (last loaded) provides `customMenu()` which is used by `menus.ahk` (loaded earlier via forward reference)
