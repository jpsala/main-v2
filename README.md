# Main Automation Tool

Personal automation tool built with AutoHotkey v2 for Windows.

## Features

- Custom hotkeys and hotstrings
- Window management utilities
- WebView2-based interactive menus
- Bookmark system for quick window access
- Chrome automation helpers
- System utilities

## Requirements

- Windows 10/11
- AutoHotkey v2.0 or later (for development)
- WebView2 Runtime (usually pre-installed on Windows)

## Installation

### Using the Installer (Recommended)

1. Download `main-automation-setup.exe`
2. Run the installer
3. Choose whether to start with Windows
4. Launch the application

### Portable Version

1. Download `main-automation-dist.zip`
2. Extract to any folder
3. Run `main.exe`
4. On first run, edit `config.ini` to match your system paths

## Configuration

Edit `config.ini` to customize:

- Application paths (browsers, editors, etc.)
- Tool locations (nircmd, notifu, etc.)
- Base directories
- Environment-specific settings (desktop, work, etc.)

The config file supports multiple machine profiles. The active profile is selected based on your computer name.

## Development

### Requirements

- AutoHotkey v2.0+ installed
- Inno Setup 6.x (optional, for creating installer)

### Building

Run `build.bat` to:
1. Compile `main.ahk` to `main.exe`
2. Package all required files into `dist/`
3. Create `main-automation-dist.zip` (portable)
4. Create `main-automation-setup.exe` (installer, if Inno Setup is installed)

### Project Structure

```
main.ahk              Entry point
├── lib/              Core libraries (WebView2, utilities)
├── ui/               HTML/CSS/JS for WebView2 menus
├── functions.ahk     Custom functions
├── hotkeys-global.ahk Global hotkey definitions
├── hotstrings.ahk    Text expansion shortcuts
├── menus.ahk         Menu definitions
├── bookmarks.ahk     Window bookmark system
└── config.ini        User configuration (not in git)
```

## License

Personal use only.

## Author

JP Salazar
