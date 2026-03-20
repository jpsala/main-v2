# AGENTS.md

Guide for LLMs and coding agents working in this repo.

## Mission

This repo is a personal Windows automation environment built with AutoHotkey v2.
Its job is to:

- launch, focus, minimize, and reuse apps and windows
- provide keyboard-first menus and modal workflows
- manage browser profiles and site launchers
- add editor-centric automation for VS Code / Cursor
- expose reusable UI systems built on WebView2

The repo is not a library first. It is a working automation setup for one user.
When changing behavior, preserve existing muscle memory unless the user explicitly asks to redesign it.

## Runtime Model

- `main.ahk` is the entry point and include graph root.
- `init.ahk` does startup, path validation, browser profile setup, timers, and hot-reload.
- Most feature work lives in plain `.ahk` modules included by `main.ahk`.
- Web UIs live under `ui/` and are rendered with `WebViewToo.ahk` / WebView2.

If you create a new module:

1. Include it from `main.ahk`.
2. Add it to `filesToCheckForReload` in `init.ahk` if it should trigger dev reloads.
3. If it has an HTML file under `ui/`, add that HTML file to `filesToCheckForReload` too.

## First Files To Read

Read these first before making non-trivial changes:

- `main.ahk`: include order and module boundaries.
- `init.ahk`: startup model, `config.ini` handling, browser profile launchers, hot-reload.
- `menus.ahk`: main user-facing menus such as `#a`, `#w`, `#c`.
- `roa.ahk`: window reuse / launch behavior (`Roa`, `RoAWithPattern`, aliases).
- `hotkeys-global.ahk`: system-wide hotkeys.
- `vim-mode.ahk`: VIM mode engine.
- `vim-keymap.ahk`: global VIM bindings.
- `vim-keymap-code.ahk`: editor-specific VIM bindings for Code/Cursor.
- `lib/chord-hotkeys.ahk`: which-key / chord engine.
- `menu-webview.ahk`: existing keyboard-first hierarchical menu system.

## Repo Map

### Core startup and config

- `main.ahk`
  - loads everything
- `init.ahk`
  - validates paths from `config.ini`
  - seeds browser profile defaults
  - builds launch commands like `vivaldiWithMainProfile`
  - owns hot-reload file list
- `config.ini`
  - real machine-local config
  - not portable, may contain user-specific paths
- `config.ini.dist`
  - template and canonical schema reference

### Reusable libraries

- `lib/path-validator.ahk`
  - path auto-detection and missing-path UX
- `lib/chord-hotkeys.ahk`
  - standalone which-key style chord engine
  - supports delayed hint display, timeout, nested submenus, cancel on invalid key
  - renders hint UI through `ui/chord-hint.html`
- `lib/WebViewToo.ahk`
  - WebView wrapper used by settings, menus, chord hint

### Menus and UI

- `menus.ahk`
  - main launcher menus (`#a`, `#w`, `#c`)
  - many app/site launch actions eventually call `Roa(...)` or `Run(...)`
- `menu-webview.ahk`
  - generic hierarchical menu engine with keyboard-first flow and WebView fallback
- `ui/menu.html`
  - menu WebView UI
- `settings-window.ahk`
  - settings backend
- `ui/settings.html`
  - settings frontend
- `tray-menu.ahk`
  - tray actions and toggles

### Editing and coding workflows

- `code.ahk`
  - VS Code / Cursor-specific shortcuts and hotstrings
- `vim-mode.ahk`
  - VIM state machine, mode indicator, action execution
- `vim-keymap.ahk`
  - declarative global VIM bindings
- `vim-keymap-code.ahk`
  - Code/Cursor-only VIM bindings

### Window reuse and bookmarks

- `roa.ahk`
  - run-or-activate behavior
  - alias loading from `config.ini`
  - reuse existing windows if possible
- `bookmarks.ahk`
  - bookmark windows and reactivate them later

### Misc

- `hotkeys-global.ahk`
  - global non-menu hotkeys
- `hotstrings.ahk`
  - text expansion
- `msg.ahk`
  - transient on-screen message helpers

## How To Answer Common User Requests

### "What Vivaldi routes / profiles do I have in this repo?"

Look in this order:

1. `config.ini` `[vivaldi-profiles]` and `[vivaldi-local-profiles]`
2. `config.ini.dist` for default schema and expected format
3. `init.ahk`
   - `BuildProfileCmd(...)`
   - `SeedDefaultProfiles()`
   - variables like `vivaldiWithMainProfile`, `vivaldiWithDebugProfile`

Important details:

- The profile format is `key=profileDir|userDataDir|extraFlags`.
- The canonical launcher strings are built in `init.ahk`, not hardcoded in menus.
- If the user asks for the actual current machine values, inspect `config.ini`.
- If the user asks what profiles the repo supports in general, inspect `config.ini.dist` plus `SeedDefaultProfiles()`.

### "Add site X to the `#w` menu"

Edit `menus.ahk`.

For `#w` specifically:

- menu definition is in `mainSeqW()`
- visible entries are in `options.items`
- execution behavior is in the `switch key` block below it

Typical pattern:

1. Add an item to `options.items`.
2. Add a matching `case` in the `switch`.
3. Usually launch via `Roa(alias, browserLauncher . " https://site")`.

Use `Roa(...)` if you want reuse/minimize semantics.
Use `Run(...)` if the action should always create a new instance.

When adding a browser site entry, prefer reusing an existing profile launcher such as:

- `vivaldiWithMainProfile`
- `vivaldiWithAIProfile`
- `vivaldiWithDebugProfile`
- `chromeWithWorkProfile`

### "Create a new menu"

There are two menu systems:

1. `menus.ahk` + `customMenuWebView(...)`
2. `lib/chord-hotkeys.ahk` + `ChordRegister(...)`

Use `customMenuWebView(...)` when:

- you want hierarchical menus that can fall back to a searchable WebView picker
- the action is launched from an existing Win hotkey like `#a`, `#w`, `#c`
- you want submenu keys like `sc`, `tp1`, `xx`

Use `ChordRegister(...)` when:

- you want a which-key style transient overlay after a prefix hotkey
- you want a prefix like `Alt+T`
- you want nested submenus with hint overlay

Examples:

- `menus.ahk` shows the repo's main production menu style.
- `chord-examples.ahk` shows current which-key usage and nested submenu syntax.

### "Create a which-key menu that does X"

Primary files:

- `lib/chord-hotkeys.ahk`
- `chord-examples.ahk`
- `ui/chord-hint.html`

How it works:

- register a top-level prefix with `ChordRegister(prefixMap, executeFn)`
- use `ChordEntry(command, label)` for final actions
- use `{ label: "...", items: Map(...) }` for submenus
- optional submenu delay per node is `hintDelay: 0.35`

Example shape:

```ahk
myChordMap := Map(
    "!t", Map(
        "a", ChordEntry("action_a", "Action A"),
        "m", {
            label: "More",
            hintDelay: 0.2,
            items: Map(
                "x", ChordEntry("action_x", "Action X")
            )
        }
    )
)
ChordRegister(myChordMap, HandleMyChord)
```

Behavior currently supported:

- root delay via `ChordSetHintDelay(...)`
- visible duration via `ChordSetTimeout(...)`
- submenus
- breadcrumb in hint
- `Esc` goes up one level, then cancels at root
- invalid key is absorbed and cancels

If the user asks to restyle the hint, edit:

- `ui/chord-hint.html`

If the user asks to change timing or behavior, edit:

- `lib/chord-hotkeys.ahk`

### "Add a command to VIM mode"

Primary files:

- `vim-keymap.ahk`
- `vim-keymap-code.ahk`
- `vim-mode.ahk`

Rule of thumb:

- add bindings in `vim-keymap.ahk` for global behavior
- add bindings in `vim-keymap-code.ahk` for Code/Cursor-only behavior
- only edit `vim-mode.ahk` if you need a new action kind or state transition

`vim-keymap.ahk` is the first place to look. It is intentionally declarative and documents the available `VimAction(...)` kinds at the top of the file.

Examples:

- motion: `VimAction("motion", "word_forward")`
- operator: `VimAction("operator", "d")`
- direct command: `VimAction("send", "^z")`
- special logic: `VimAction("char_motion", "f")`

If a requested behavior cannot be expressed with existing action kinds, extend `VimExecuteAction(...)` in `vim-mode.ahk`.

### "Change VIM mode toggle or modal behavior"

Look in `vim-mode.ahk`.

Current architecture:

- mode state globals at top
- indicator GUI is defined there
- short `LAlt` tap toggles mode
- click exits VIM mode
- keymaps are registered dynamically from `vim-keymap.ahk`

### "Add an editor-only VIM behavior for Cursor / VS Code"

Use `vim-keymap-code.ahk`.

That file is already guarded by a context function checking:

- `Code.exe`
- `Cursor.exe`

If the requested behavior depends on Code/Cursor shortcuts rather than raw text editing, prefer adding it there rather than globally.

### "Change the settings UI"

Files:

- `settings-window.ahk`
- `ui/settings.html`

The AHK file owns window lifecycle and WebMessage handling.
The HTML file owns visuals and frontend interactions.

### "Change the main searchable menu UI"

Files:

- `menu-webview.ahk`
- `ui/menu.html`

### "Change bookmark behavior"

Files:

- `bookmarks.ahk`
- `config.ini` `[bookmarks]`
- `config.ini` `[bookmarkHotkeys]`

### "Add a new reusable launcher / alias"

Files:

- `roa.ahk`
- `config.ini` `[windowAliases]`

Use `Roa(...)` when the desired behavior is:

- activate if present
- minimize if already active
- launch if absent

That is the repo's default "app reuse" primitive.

## Important Existing Patterns

### Browser launchers are assembled, not handwritten

Do not duplicate browser profile command strings if you can avoid it.
Prefer using the already built variables from `init.ahk`.

### Menus are declarative first, imperative second

For `menus.ahk`:

- visible structure lives in `options.items`
- side effects live in the `switch key`

Keep both in sync.

### WebView UIs are split cleanly

For WebView features:

- `.ahk` file owns window lifecycle, timers, IPC, and positioning
- `ui/*.html` owns appearance and frontend rendering

### New files should participate in hot-reload

If you add a file that is meant to be edited during development, update `init.ahk`:

- add the `.ahk` file to `filesToCheckForReload`
- add the `.html` file too if relevant

## Gotchas

- `config.ini` is user-local and may differ from `config.ini.dist`.
- Some globals are intentionally initialized in `init.ahk`, not in the feature module.
- `menus.ahk` has a few duplicate-looking keys and historical quirks; preserve behavior unless the user asks to clean them.
- `lib/chord-hotkeys.ahk` currently includes `WebViewToo.ahk` itself because the hint UI is WebView-based.
- VIM mode is modal: unmapped printable keys are suppressed on purpose.
- If a user asks for "where is X configured", first determine whether X lives in code, `config.ini`, or both.

## AutoHotkey v2 Notes For Agents

- Treat `#Include` order as executable startup order, not just dependency order. Code at top level in an included file runs immediately during load.
- Do not call repo functions from top-level code in a newly included file unless you have verified those functions are already defined by earlier includes.
- When passing functions around, prefer explicit function objects such as `Func("Name")` or closures instead of relying on bare identifiers.
- Distinguish carefully between:
  - calling a function now: `MyFn()`
  - passing a function object: `Func("MyFn")`
  - scheduling a call: `SetTimer(Func("MyFn"), -1)` or `SetTimer(fn.Bind(args*), -1)`
- Avoid assuming semantics from JavaScript, Python, or C# for object literals, scope, or top-level execution. AutoHotkey v2 has its own parser and warning behavior.
- After non-trivial `.ahk` edits, syntax-check with AutoHotkey before finishing. Prefer:
  - `"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut path\to\probe.ahk`
- When a warning mentions "This local variable appears to never be assigned a value", suspect one of these first:
  - a bare identifier was interpreted as a local variable instead of a function reference
  - include order caused a top-level call to happen before the function definition was loaded
  - a function/object reference was passed incorrectly
- For hotkey systems, prefer the simplest AHK-native mechanism that fits. Avoid dynamic capture layers that leave temporary hotkeys active unless there is a clear need and cleanup is proven.

### Valid / Invalid Patterns

Prefer these patterns in this repo:

- Valid: define setup functions in included files and call them explicitly from a known-safe point.
- Valid: `fn := Func("HandleMainSeqAKey")`
- Valid: `options := Func("GetMainSeqAOptions").Call()`
- Valid: `SetTimer(fn.Bind(arg1), -1)`
- Valid: `Hotkey("#a", (*) => DoThing())` when dynamic registration is really needed
- Valid: static hotkeys such as `#a:: { ... }` when behavior is fixed and simple
- Valid: keep top-level code limited to declarations, helper functions, and carefully reviewed initialization

Avoid these patterns unless you have verified they are safe in AHK v2 for this include order:

- Invalid: assuming an included file behaves like an import that does not execute top-level code
- Invalid: passing bare identifiers when a function object is expected
- Invalid: calling repo functions at top level in a file that may load before their definitions
- Invalid: leaving temporary hotkeys, timers, or hooks enabled after a menu / modal flow exits
- Invalid: refactors that move initialization earlier in `main.ahk` without checking include-order side effects

Examples:

```ahk
; Good: explicit function object + explicit call
InitMenusWhichKey() {
    MenuWhichKeyRegister("#a", Func("GetMainSeqAOptions").Call(), Func("HandleMainSeqAKey"))
}

; Risky: relies on symbol resolution and top-level timing
InitMenusWhichKey() {
    MenuWhichKeyRegister("#a", GetMainSeqAOptions(), HandleMainSeqAKey)
}
```

```ahk
; Good: register from a known entry point after dependencies are loaded
#Include ".\menus.ahk"
#Include ".\menus-whichkey.ahk"

; Risky: top-level init in a file whose dependencies may not be loaded yet
InitMenusWhichKey()
```

## Quick Lookup Table

- Vivaldi/Chrome profiles: `init.ahk`, `config.ini`, `config.ini.dist`
- `#w` browser/sites menu: `menus.ahk`
- `#a` apps/tools menu: `menus.ahk`
- `#c` code/tools menu: `menus.ahk`
- which-key engine: `lib/chord-hotkeys.ahk`
- which-key example registrations: `chord-examples.ahk`
- which-key visual style: `ui/chord-hint.html`
- VIM engine: `vim-mode.ahk`
- VIM bindings: `vim-keymap.ahk`
- VIM Code/Cursor bindings: `vim-keymap-code.ahk`
- reusable window launch/reuse: `roa.ahk`
- settings UI: `settings-window.ahk`, `ui/settings.html`
- searchable WebView menu engine: `menu-webview.ahk`, `ui/menu.html`
- global hotkeys: `hotkeys-global.ahk`
- VS Code/Cursor extras: `code.ahk`
- bookmarks: `bookmarks.ahk`

## Recommended Workflow For Agents

When asked to implement a change:

1. Identify whether the request is about config, menu structure, launch behavior, modal editing, or UI.
2. Read the smallest relevant module first.
3. Reuse existing primitives:
   - `Roa(...)`
   - `customMenuWebView(...)`
   - `ChordRegister(...)`
   - `VimAction(...)`
4. If creating a new module or UI file, wire it into `main.ahk` and `init.ahk`.
5. Preserve the current interaction model unless the user asks for a redesign.
