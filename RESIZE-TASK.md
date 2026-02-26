# Task: Make all assistant windows resizable

## Problem
After adding custom titlebars (`-Caption`), windows lost the native OS resize handles. Users can no longer resize any of the 4 windows by dragging edges/corners.

## Current state (ai-assistant.ahk)
All 4 windows already have `+Resize` except the picker:
- `settingsGui := WebViewGui("+AlwaysOnTop +Resize +MinSize300x200 -Caption", ...)`
- `editorGui := WebViewGui("+AlwaysOnTop +Resize +MinSize500x400 -Caption", ...)`
- `wvGui := WebViewGui("+AlwaysOnTop +Resize +MinSize400x400 -Caption", ...)`
- `pickerGui := WebViewGui("+AlwaysOnTop -Caption", ...)` — no resize (popup)

The `+Resize` flag alone isn't enough with `-Caption` — there's no visible border to grab.

## Solution approach
With `-Caption`, AHK's `+Resize` still enables resize if the window has a border, but the grab area is tiny/invisible. Two options:

### Option A: WM_NCHITTEST override (recommended)
Handle `WM_NCHITTEST` (0x0084) in AHK to create virtual resize borders at the window edges. When the mouse is within ~6px of any edge/corner, return the appropriate HT* constant so Windows provides native resize behavior.

```ahk
; Constants
HTLEFT := 10, HTRIGHT := 11, HTTOP := 12, HTBOTTOM := 15
HTTOPLEFT := 13, HTTOPRIGHT := 14, HTBOTTOMLEFT := 16, HTBOTTOMRIGHT := 17

OnMessage(0x0084, WM_NCHITTEST)

WM_NCHITTEST(wParam, lParam, msg, hwnd) {
    ; Only for our WebView windows
    ; Check if hwnd matches one of our GUIs
    ; Get mouse position relative to window
    ; If within border zone (6px), return appropriate HT* value
    ; Otherwise return 0 to let default handling proceed
}
```

### Option B: CSS resize handles (JS-driven)
Add invisible resize handles in HTML at edges, detect mousedown, and send resize messages to AHK via `postMessage`. More complex and less native-feeling.

## Files to modify
1. `ai-assistant.ahk` — add `WM_NCHITTEST` handler
2. Possibly `ui/shared.css` — add `cursor` styles on body edges (optional, the OS cursor change from WM_NCHITTEST should suffice)

## Per-window resize control
The WM_NCHITTEST handler should check `hwnd` against each GUI's `.Hwnd` property to decide if resize is allowed. The picker window should NOT be resizable.

## Window size persistence
Settings and main windows already save/restore sizes via `settings.conf` (`settings_w`, `settings_h`, `main_w`, `main_h`). Editor window does not currently persist size — consider adding that.
