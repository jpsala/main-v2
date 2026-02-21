# Unused Files in main/ Directory

Files that are **NOT** used by `main.ahk` or any of its dependencies and can potentially be moved to the `unusedInBin` folder.

## Unused Files Found

### Scripts
- `copyAndSave.ahk` - Not included by main.ahk or any dependency
- `log.ps1` - PowerShell script created for analysis (can be removed after use)

## Total Unused Files: 2

---

## Analysis Summary

**Total files in main/ directory:** 41  
**Files used by main.ahk:** 39  
**Unused files:** 2  

## Used Files (for reference)

The following 39 files ARE used by `main.ahk` and should **NOT** be moved:

### Core Scripts
- `main.ahk` - Entry point
- `msg.ahk`, `functions.ahk`, `init.ahk`, `bookmarks.ahk`, `menus.ahk`
- `code.ahk`, `browser.ahk`, `hotstrings.ahk`
- `system.ahk`, `chrome.ahk`, `obsidian.ahk`, `discord.ahk`
- `xyplorer.ahk`, `database.ahk`
- `teams.ahk`, `tv.ahk`, `clipboard.ahk`, `hotkeys-global.ahk`
- `gdip.ahk` (included by clipboard.ahk)

### Configuration Files
- `config.ini`, `sp.ini`

### Asset Files
- `wrench.png`, `tv.png`, `mt5_common.png`, `position.png`
- `bigAgiMenuIcon.png`, `bigAgiMenuIconTruncate.png`
- `start.mp3`, `stop.mp3`

### Data Files
- `log.txt`, `tmp.md`, `bookmarks.md`

### Other Files
- `typingmind-mcp.bat`, `.gitignore`, `.cursorignore`

---

## PowerShell Command to Move Unused Files

```powershell
# Run from the main/ directory
Move-Item "copyAndSave.ahk" "../unusedInBin/" -WhatIf
Move-Item "log.ps1" "../unusedInBin/" -WhatIf

# Remove -WhatIf to actually move the files
``` 
