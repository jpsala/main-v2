# Project Conventions — Main Automation

AutoHotkey v2 + WebView2 personal automation suite.

## WebView Windows — Required Pattern

All WebView windows MUST follow this structure for consistent look & feel.

### AHK side
```ahk
myGui := WebViewGui("+Resize -Caption", "Window Title",, {DllPath: dllPath})
```
- Always use `-Caption` (no OS titlebar — the HTML provides its own)
- Add `+Resize` for resizable windows, `+AlwaysOnTop` for popup/menu windows
- Handle `"minimize"` and `"close"` messages from the WebView

### HTML side — required includes
```html
<head>
  <link rel="stylesheet" href="shared.css">   <!-- shared vars, body, titlebar, grip, scrollbars -->
</head>
<body>
  ...
  <script src="ahk-bridge.js"></script>        <!-- postToAHK, minimizeWindow, closeWindow -->
  <script> /* window-specific JS */ </script>
</body>
```

### Titlebar — full window (with minimize/close)
```html
<div class="titlebar">
  <div class="grip">
    <span></span><span></span><span></span>
    <span></span><span></span><span></span>
  </div>
  <div class="titlebar-title">
    <span class="titlebar-icon">⚙</span>
    Window Title
  </div>
  <div class="window-controls">
    <button class="win-btn win-minimize" onclick="minimizeWindow()" title="Minimizar">&#x2212;</button>
    <button class="win-btn win-close"    onclick="closeWindow()"    title="Cerrar">&#x2715;</button>
  </div>
</div>
```

### Drag bar — popup/menu window (no window controls)
```html
<div class="drag-bar">
  <div class="grip">
    <span></span><span></span><span></span>
    <span></span><span></span><span></span>
  </div>
  <h2 id="window-title">Title</h2>
</div>
```

### AHK message format
Each window defines its own `sendToAHK()` on top of `postToAHK()` from the bridge:

```js
// Settings-style (each key is a top-level prop):
function sendToAHK(action, data = {}) { postToAHK({ action, ...data }); }

// Menu-style (data wrapped in an envelope):
function sendToAHK(action, data) { postToAHK({ action, data }); }
```

## File layout
```
main.ahk              — entry point
config.ini            — user config
ui/
  shared.css          — shared styles (variables, body, titlebar, grip, scrollbars)
  ahk-bridge.js       — shared JS (postToAHK, minimizeWindow, closeWindow)
  settings.html       — settings window (full titlebar)
  menu.html           — menu picker (drag-bar only)
lib/                  — AHK libraries (WebViewToo, chord-hotkeys, …)
```
