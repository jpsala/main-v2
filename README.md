# Main v2 — Windows Automation Command Center

Turn Windows into a keyboard-first workspace: launch apps, reuse windows, switch browser profiles, drive VS Code/Cursor, run mouse gestures, and build your own personal command menus with AutoHotkey v2.

This repo is not a tiny hotkey snippet collection. It is a working, daily-use automation environment that shows how to build a **personal operating layer** on top of Windows.

## Why this exists

If your day looks like this:

- too much `Alt+Tab` hunting
- too many browser profiles, tabs, and workspaces
- repeated app-launching and window-position rituals
- editor commands you know exist but never remember
- tiny workflows that are too personal for commercial tools

…then this project is meant to be forked, customized, and turned into your own command center.

## What you get

| Area | What it does |
| --- | --- |
| **Run-or-Activate apps** | Reuse existing windows instead of spawning duplicates. If an app is active, toggle/minimize it; if missing, launch it. |
| **Keyboard-first menus** | `Win+A`, `Win+W`, `Win+C` open app/browser/code menus with fast key selection and WebView fallback. |
| **Which-key style chords** | Prefix keys show discoverable overlays for nested command trees. Great for complex workflows. |
| **Window bookmarks** | Pin any live window to a hotkey and jump back instantly, even across sessions. |
| **Browser profile launcher** | Manage Vivaldi/Chrome profiles from config instead of hardcoding commands everywhere. |
| **VS Code / Cursor control** | Editor-only chords for navigation, settings, folding, file actions, AI sidebars, and command execution. |
| **Global Vim mode** | Optional modal editing layer with Vim-like motions, operators, paste, visual mode, and editor-specific bindings. |
| **Mouse gestures** | Context-aware gesture engine with a wizard, learned shapes, sorting, debug state, and per-app actions. |
| **WebView2 UIs** | Settings, searchable menus, chord hints, audio device picker, calendar/reminders, and clipboard surfaces. |
| **Per-machine config** | `config.ini` selects machine-specific paths and profiles by computer name. |
| **Hot reload for development** | Editing core `.ahk`/UI files reloads the script automatically during development. |

## The main idea: stop thinking about windows

Most launchers start programs. This repo tries to preserve **flow**:

```text
Press hotkey → choose command → find existing window → activate/minimize it
                                    │
                                    └─ if not found: launch it, then remember it
```

That behavior lives around the `Roa(...)` / `RoAWithPattern(...)` primitives and powers many menu entries.

## Quick start

### Requirements

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/) for development/use from source
- Microsoft WebView2 Runtime (usually already installed on Windows 10/11)

### Run from source

```powershell
git clone https://github.com/jpsala/main-v2.git
cd main-v2
copy config.ini.dist config.ini
copy .env.example .env   # optional, only if you use secret hotstrings/API keys
```

Then edit `config.ini` for your machine paths and run:

```powershell
main.ahk
```

On first run, missing optional tools are reported instead of crashing. Features depending on unavailable paths simply do not work until configured.

## First things to try

| Shortcut | Use it for |
| --- | --- |
| `Win+A` | Apps/tools menu |
| `Win+W` | Browsers, profiles, web projects/sites |
| `Win+C` | Code/editor/project menu |
| `Win+S`, then any key | Create or toggle a dynamic bookmark for the active window |
| `Shift+Win+S`, then any key | Reassign a bookmark |
| `Ctrl+Alt+Shift+B` | Show bookmark manager |
| `Win+,` | Open settings window |

Some entries are intentionally personal examples. Replace them with your own launchers in `menus.ahk` and `menu-actions.ahk`.

## Who this is for

Good fit if you:

- live on Windows and want keyboard-first control
- use several browsers/profiles/editors/projects
- are comfortable editing AutoHotkey scripts
- want a real example of a large personal automation setup
- prefer composing small local workflows over installing another platform

Probably not a fit if you want:

- a polished consumer app
- zero configuration
- cross-platform support
- a minimal snippet-only AHK repo

## Core workflows

### 1. App and site menus

Menu data lives in `menus.ahk`; side-effect helpers live in `menu-actions.ahk`.

Typical entry shape:

```ahk
{ key: "s", label: "Spotify", action: () => Roa("spotify", "spotify.exe") }
```

Nested menus are supported, and the same menu tree can feed keyboard-first flows and which-key overlays.

### 2. Window bookmarks

`bookmarks.ahk` lets you bind windows dynamically:

- `Win+S` → key: create/toggle bookmark
- `Shift+Win+S` → key: force reassignment
- direct hotkeys such as `Win+1`, `Win+F`, etc. activate/minimize saved windows
- bookmarks persist in local `config.ini`

### 3. Browser profiles

Browser profile commands are assembled from `config.ini` / `config.ini.dist`:

```ini
[vivaldi-profiles]
main=Profile 1||
ai=AI|%LocalAppData%\Vivaldi\User Data|
debug=Debug||--no-first-run
```

That keeps browser profile knowledge centralized instead of scattered across menu code.

### 4. VS Code / Cursor chords

When Code/Cursor is active, friendly launchers like `Alt+G`, `Alt+B`, `Alt+T`, `Alt+S`, `Alt+Z`, and `Alt+F` open command groups for navigation, bookmarks, toggles, settings, folding, and file actions.

Key files:

- `code.ahk`
- `menus-whichkey.ahk`
- `lib/chord-hotkeys.ahk`
- `ui/chord-hint.html`

### 5. Vim mode

`vim-mode.ahk` plus `vim-keymap.ahk` / `vim-keymap-code.ahk` implement a modal layer with motions, operators, visual mode, paste, history navigation, and Code/Cursor-specific behavior.

### 6. Mouse gestures

The gesture system is split into:

- `mouse-gestures.ahk` — recognition engine
- `mouse-gestures-conditions.ahk` — human-edited action rules
- `mouse-gestures-wizard.ahk` — stub generation and sorting
- `docs/features/gestures.md` — working guide

Gestures can match by shape, size, screen cell, monitor, exe, class, and title.

## Configuration model

Local state is intentionally not committed:

- `config.ini` — machine paths, bookmarks, aliases, browser profile values
- `.env` — local secrets for hotstrings/API-key helpers

Committed templates:

- `config.ini.dist`
- `.env.example`

Machine-specific config is selected through the `[machines]` section in `config.ini`.

## Project map

```text
main.ahk                     Entry point and include graph root
init.ahk                     Startup, path validation, profiles, hot reload
menus.ahk                    Main user-facing menu definitions
menu-actions.ahk             Actions called by menu items
menus-whichkey.ahk           Bridge from menu trees to chord/which-key engine
lib/chord-hotkeys.ahk        Generic chord engine and hint lifecycle
ui/chord-hint.html           Which-key overlay UI
menu-webview.ahk             Searchable WebView menu engine
ui/menu.html                 Menu picker UI
bookmarks.ahk                Persistent window bookmark system
roa.ahk                      Run-or-Activate window reuse engine
hotkeys-global.ahk           Global hotkeys and system controls
hotstrings.ahk               Text expansions and local secret helpers
code.ahk                     VS Code/Cursor automation and chords
vim-mode.ahk                 Vim-mode state machine
vim-keymap.ahk               Global Vim bindings
vim-keymap-code.ahk          Code/Cursor-only Vim bindings
mouse-gestures*.ahk          Gesture engine, wizard, and conditions
settings-window.ahk          Settings backend
ui/settings.html             Settings frontend
config.ini.dist              Public config template
.env.example                 Public secret template
MainPortable/                Smaller portable automation toolkit
```

## Extending it

### Add a menu item

1. Add an item in `menus.ahk`.
2. Put reusable behavior in `menu-actions.ahk` if it is more than one line.
3. Prefer `Roa(...)` when you want reuse/minimize semantics.
4. Keep local paths in `config.ini`, not hardcoded in actions.

### Add a new module

1. Include it from `main.ahk`.
2. Add it to `filesToCheckForReload` in `init.ahk` if you want hot reload.
3. If it has a WebView UI, put the HTML under `ui/` and hot-reload that too.

## Security notes

This repo is public, but local secrets are expected to stay local:

- never commit `.env`
- never commit `config.ini`
- keep real API keys out of hotstrings and menu code
- use `.env.example` and `config.ini.dist` for shareable templates

If you fork from an older private copy that had secrets in history, rotate those keys and rewrite your fork history before publishing.

## Current status

This is a production personal automation setup, published as a reference implementation and forkable starting point. It is powerful because it is opinionated. Expect to customize paths, menus, profiles, and gestures to match your own workstation.

## License

MIT License. See [LICENSE](LICENSE).
