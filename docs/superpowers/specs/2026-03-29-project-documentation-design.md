# Project Documentation Design

Date: 2026-03-29
Status: Approved in chat
Scope: Documentation-first foundation for future local skills and repo navigation

## Goal

Create a documentation system that makes this AutoHotkey repo easier to navigate, extend, and discuss. The documentation should help answer these practical questions quickly:

- What can the project do today?
- Which feature owns a given behavior?
- Which files should be touched for a change?
- Which reusable primitives already exist?
- How should common changes be added without breaking existing muscle memory?

This documentation is a prerequisite for future local skills that automate recurring AutoHotkey work such as adding hotkeys, adding menu entries, extending VS Code/Cursor automation, or wiring new browser/site actions.

## Problem Statement

The repo already has a strong internal structure, but discoverability is distributed across many modules:

- Startup and global state are centered in `main.ahk`, `init.ahk`, `functions.ahk`, `lib/globals.ahk`, and `lib/path-validator.ahk`.
- User-facing behaviors are split across menus, bookmarks, hotkeys, VIM mode, editor automation, and settings.
- Several capabilities are intentionally composed from reusable primitives such as `Roa(...)`, `customMenuWebView(...)`, `ChordRegister(...)`, and `VimAction(...)`.

Without a feature-oriented map, it is slower to answer change requests like:

- "Add a site to `#w`"
- "Create a new chord"
- "Add a VIM binding"
- "Add a Code/Cursor-only shortcut"
- "Change a launcher to reuse an existing window"

## Documentation Strategy

Use a hybrid structure:

1. A central project map for fast orientation.
2. A set of focused feature documents organized by capability, not by source file.

This avoids two bad extremes:

- one long monolithic document that becomes hard to scan
- a file-per-module system that mirrors the codebase but does not match how the repo is used

The central map should answer "where do I go?" and the feature docs should answer "how does this feature work and how do I safely change it?"

## Information Architecture

### Primary Entry Point

`docs/project-map.md`

This file should be the main navigation hub. It should provide:

- a high-level architecture summary
- the runtime model and include order
- a feature index
- a lookup table from common request types to the owning feature/doc
- a lookup table from features to key files and reusable primitives

This should stay short and operational rather than exhaustive.

### Feature Docs

Feature docs should live under:

`docs/features/`

These documents should be oriented around capabilities the user actually asks to change, rather than around individual implementation files.

## Feature Taxonomy

The initial documentation set should use this feature breakdown:

1. Bootstrap and configuration
2. Window launch and reuse
3. Menus and navigation
4. Which-key / chords
5. Window bookmarks
6. Browser profiles and site launchers
7. VS Code / Cursor automation
8. VIM mode
9. Global hotkeys and system utilities
10. Settings and admin UI
11. Shared WebView UI infrastructure

### Why This Taxonomy

This grouping matches the repo's real change requests better than a module-by-module breakdown. Future asks are more likely to sound like:

- "Add something to a menu"
- "Create a hotkey"
- "Add a site launcher"
- "Extend VIM mode"
- "Change a Code/Cursor behavior"

than:

- "Edit `functions.ahk`"
- "Change `main.ahk` include order"

The docs should therefore be optimized for operational discoverability first, code layout second.

## Initial Document Set

The first documentation pass should create:

- `docs/project-map.md`
- `docs/features/bootstrap-and-config.md`
- `docs/features/window-reuse-and-launch.md`
- `docs/features/menus-and-navigation.md`
- `docs/features/bookmarks.md`
- `docs/features/browser-profiles-and-sites.md`
- `docs/features/vscode-cursor-automation.md`
- `docs/features/vim-mode.md`
- `docs/features/global-hotkeys-and-system-utils.md`
- `docs/features/settings-and-admin.md`
- `docs/features/ui-webview.md`

## Standard Feature Doc Template

Each feature document should use the same internal shape so it can later support local skills and predictable maintenance work.

### Required Sections

- What problem this feature solves
- What it does today
- Main entry points
- Key files
- Reusable primitives
- Internal flow
- Related config
- How to extend it
- Gotchas

### Section Intent

#### What Problem This Feature Solves

Explains the user's mental model of the feature, not its implementation details.

#### What It Does Today

Lists current capabilities and examples of real usage.

#### Main Entry Points

Documents how the feature is reached:

- hotkeys
- menu entries
- chords
- GUI/WebView surfaces
- public helper functions when relevant

#### Key Files

Lists the most important files and their responsibilities.

#### Reusable Primitives

Highlights the existing building blocks that changes should reuse, such as:

- `Roa(...)`
- `RoAWithPattern(...)`
- `customMenuWebView(...)`
- `ChordRegister(...)`
- `VimAction(...)`

#### Internal Flow

Shows the sequence from user action to implementation effect.

#### Related Config

Points to the `config.ini` sections or runtime state relevant to the feature.

#### How To Extend It

Provides practical guidance for common modifications without requiring a full repo re-read.

#### Gotchas

Captures repo-specific constraints such as:

- include order matters
- top-level AHK execution matters
- state lives in `config.ini` and globals
- some launchers are assembled in `init.ahk`, not handwritten in menus
- behavior should preserve existing muscle memory unless intentionally redesigned

## Project Map Content Design

`docs/project-map.md` should include:

### 1. Repo Purpose

A short description of the repo as a personal Windows automation environment built with AutoHotkey v2.

### 2. Runtime Model

Describe:

- `main.ahk` as the include root
- `init.ahk` as startup/config/profile/hot-reload setup
- feature modules as included AHK files
- WebView-backed UI under `ui/`

### 3. Architecture Layers

Document the repo in layers:

- startup and config
- shared primitives and libraries
- user-facing interaction systems
- WebView UI
- feature modules

### 4. Feature Index

A short list of features linked to their documents.

### 5. Quick Lookup Table

The central lookup table should have columns like:

- Request type
- Feature
- Main files
- Reusable primitives

Example requests:

- add hotkey
- add menu item
- add chord
- add browser profile entry
- add site launcher
- add Code/Cursor automation
- add VIM binding

## Source Mapping For The First Pass

The documentation should derive primarily from these repo files:

- `main.ahk`
- `init.ahk`
- `menus.ahk`
- `menu-actions.ahk`
- `menus-whichkey.ahk`
- `menu-webview.ahk`
- `roa.ahk`
- `bookmarks.ahk`
- `hotkeys-global.ahk`
- `code.ahk`
- `vim-mode.ahk`
- `vim-keymap.ahk`
- `vim-keymap-code.ahk`
- `settings-window.ahk`
- `config.ini.dist`
- `lib/chord-hotkeys.ahk`
- `lib/globals.ahk`
- `lib/path-validator.ahk`
- `lib/window.ahk`

## How This Supports Future Local Skills

This documentation system is intentionally designed to become the context layer for future local skills. The likely next generation of local skills would be task-shaped, for example:

- add a menu item
- add a browser/site launcher
- add a chord
- add a global hotkey
- add a VIM binding
- add a Code/Cursor-only editor behavior
- add a config-backed launcher

These skills should not be created until the feature map exists, because each skill should point to a stable feature area and a known set of reusable primitives.

## Non-Goals

This first documentation pass should not:

- fully document every helper function in the repo
- replace inline code comments
- redesign feature boundaries
- normalize historical quirks unless they block comprehension
- create skills yet

## Rollout Order

Recommended authoring order:

1. `docs/project-map.md`
2. `docs/features/menus-and-navigation.md`
3. `docs/features/window-reuse-and-launch.md`
4. `docs/features/vscode-cursor-automation.md`
5. `docs/features/vim-mode.md`
6. Remaining feature docs

This order prioritizes the areas most likely to support future change requests quickly.

## Risks And Mitigations

### Risk: Docs Mirror Files Instead Of Features

Mitigation:

Keep the primary navigation feature-oriented and use file references only as support.

### Risk: Docs Become Descriptive But Not Operational

Mitigation:

Require "Main entry points", "How to extend it", and "Reusable primitives" in every feature doc.

### Risk: Historical Quirks Get Accidentally Presented As Design Intent

Mitigation:

Document quirks explicitly under "Gotchas" and avoid silently reframing them as ideal architecture.

### Risk: Future Skills Become Too Broad

Mitigation:

Create local skills later around recurring tasks, not around vague feature areas.

## Success Criteria

This documentation effort is successful if, after the first pass, it becomes easy to answer:

- Where do I add a new browser/site action?
- Where do I add or change a menu item?
- Where do I add a chord?
- Where do I add a Code/Cursor-only automation?
- Where do I change or extend VIM behavior?
- Which primitives already exist that I should reuse?

## Next Step After Approval

After this design spec is reviewed and accepted, the next step is to create an implementation plan for authoring:

- `docs/project-map.md`
- the first batch of feature docs
- the follow-up local skills that depend on this documentation layer
