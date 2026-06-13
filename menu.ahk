; Global variable to store the selected keys from GUI menu
global SelectedKeys := ""

; ========================================
; Enhanced Menu System with Sub-menu Support
; ========================================
; 
; Features:
; - Keyboard navigation with timeout (showDelaySeconds/waitSeconds option) for main menus
; - Sub-menus with ► indicator appear instantly (no delay)
; - Key combinations returned as strings (e.g., "SX1" for S→X→1)
; - Both GUI (mouse) and keyboard navigation supported
;
; Usage:
; - Press Alt+B to show the main fold menu
; - Press Alt+S to show a test items with two-key combinations 
; - When using keyboard navigation, press the key for the menu item
; - For itemss, press the parent key, then the child key
; - The system will return both keys when navigating through itemss
;
customMenu(options, parentKeys := []) {
    ; Check if options.items exists
    if (!options.HasProp("items") || !IsObject(options.items)) {
        return false
    }
    
    ; Check if a wait option is provided - use pure keyboard navigation
    if (LegacyMenuGetWaitSeconds(options) > 0) {
        return ShowKeyboardMenu(options, parentKeys)
    }
    
    ; If no wait is configured, show GUI menu
    return ShowGUIMenu(options, parentKeys)
}

ShowKeyboardMenu(options, parentKeys := []) {
    ; Safety: Ensure any stuck modifier keys are released
    ; This prevents issues with keys getting stuck
    SetKeyDelay(10)
    if (GetKeyState("Shift", "P")) {
        Send("{Shift Up}")
        Sleep(10)
    }
    if (GetKeyState("Ctrl", "P")) {
        Send("{Ctrl Up}")
        Sleep(10)
    }
    if (GetKeyState("Alt", "P")) {
        Send("{Alt Up}")
        Sleep(10)
    }
    
    ; Wait for a key press with timeout (only one attempt for main menu)
    timeout := LegacyMenuGetWaitSeconds(options)
    Input := InputHook("L1 T" . timeout)  ; Single key, with timeout
    Input.Start()
    Input.Wait()
    
    ; If a key was pressed within the timeout, handle it
    if ((Input.EndReason == "Max" || Input.EndReason == "EndKey") && Input.Input != "") {
        keyPressed := Input.Input
        
        ; Handle case sensitivity properly by checking shift state
        ; Get the base character (what would be typed without shift)
        baseKey := StrLower(keyPressed)
        
        ; Check if Shift was held down during input - use more reliable detection
        ; Get the actual character that was typed (this accounts for Shift state during input)
        actualKey := keyPressed
        
        ; For alphabetic characters, determine the intended key based on what was actually typed
        if (RegExMatch(actualKey, "^[a-zA-Z]$")) {
            ; The InputHook already captured the correct character based on Shift state
            ; So we can use the actual key directly for matching
            finalKey := actualKey
        } else {
            ; For non-alphabetic characters, use the key as captured
            finalKey := actualKey
        }
        
        ; Find the item with this key (try exact match first)
        foundItem := false
        matchedKey := ""
        
        for index, item in options.items {
            ; Try exact match with the actual key pressed
            if (item.key == actualKey) {
                foundItem := item
                matchedKey := actualKey
                break
            }
            ; For alphabetic keys, also try case-insensitive match
            if (RegExMatch(actualKey, "^[a-zA-Z]$") && RegExMatch(item.key, "^[a-zA-Z]$")) {
                if (item.key == actualKey) {
                    foundItem := item
                    matchedKey := item.key  ; Use the original case from the menu item
                    break
                }
            }
        }
        
        if (foundItem) {
            ; If this item has a items, show it
            if (foundItem.HasProp("items") && IsObject(foundItem.items)) {
                subOptions := {
                    waitSeconds: timeout,
                    items: foundItem.items
                }
                newParentKeys := parentKeys.Clone()
                newParentKeys.Push(matchedKey)
                return ShowKeyboardMenu(subOptions, newParentKeys)
            } else {
                ; No items, return the result as a string with all keys
                allKeys := parentKeys.Clone()
                allKeys.Push(matchedKey)
                keyString := ""
                for key in allKeys {
                    keyString .= key
                }
                return keyString
            }
        }
        
        ; Debug: Show what key was pressed if not found
        ToolTip("Key pressed: " . actualKey . " not found in menu", , , 1)
        SetTimer(() => ToolTip(, , , 1), -1000)
        return false
    } else {
        ; Timeout occurred - fall back to GUI menu
        return ShowGUIMenu(options, parentKeys)
    }
}

LegacyMenuGetWaitSeconds(options) {
    if (options.HasProp("showDelaySeconds"))
        return options.showDelaySeconds
    if (options.HasProp("waitSeconds"))
        return options.waitSeconds
    if (options.HasProp("waitml"))
        return options.waitml / 1000
    return 0
}

ShowGUIMenu(options, parentKeys := []) {
    ; Get mouse position
    MouseGetPos(&x, &y)
    
    ; Get screen dimensions
    MonitorGet(MonitorGetPrimary(), &Left, &Top, &Right, &Bottom)
    
    ; Menu dimensions (approximate)
    menuWidth := 250  ; Increased width for items indicators
    menuHeight := options.items.Length * 24 + 20 ; Dynamic height based on items
    
    ; Adjust position if menu would go off screen
    if (x + menuWidth > Right)
        x := Right - menuWidth
    if (y + menuHeight > Bottom)
        y := Bottom - menuHeight
    if (x < Left)
        x := Left
    if (y < Top)
        y := Top
    
    ; Create and show the menu
    foldMenu := Menu()
    
    ; Add menu items dynamically from options.items
    for index, item in options.items {
        if (item.key == "" && item.label == "") {
            ; Add separator
            foldMenu.Add()
        } else {
            ; Add menu item with key and label
            hasSubmenu := item.HasProp("items") && IsObject(item.items)
            ; Add & before key for keyboard accelerator, but handle special cases
            acceleratorKey := (StrLen(item.key) == 1 && RegExMatch(item.key, "^[a-zA-Z0-9]$")) ? "&" . item.key : item.key
            menuText := acceleratorKey . "`t" . item.label
            
            ; Create a closure function to properly capture the item and parent keys
            currentItem := item
            currentParentKeys := parentKeys
            
            if (hasSubmenu) {
                ; Create a native AutoHotkey items
                items := Menu()
                items.Color := "0x2D2D30"  ; Dark background for items too
                
                ; Add items items
                for subIndex, subItem in item.items {
                    if (subItem.key == "" && subItem.label == "") {
                        items.Add()  ; Separator
                    } else {
                        ; Create accelerator for items item
                        subAcceleratorKey := (StrLen(subItem.key) == 1 && RegExMatch(subItem.key, "^[a-zA-Z0-9]$")) ? "&" . subItem.key : subItem.key
                        subMenuText := subAcceleratorKey . "`t" . subItem.label
                        
                        ; Calculate the full key sequence for items item
                        subAllKeys := currentParentKeys.Clone()
                        subAllKeys.Push(currentItem.key)
                        subAllKeys.Push(subItem.key)
                        subKeyString := ""
                        for key in subAllKeys {
                            subKeyString .= key
                        }
                        
                        ; Add items item with proper callback
                        items.Add(subMenuText, ((capturedKeys, capturedLabel) => (*) => MenuAction(capturedLabel, capturedKeys))(subKeyString, subItem.label))
                    }
                }
                
                ; Add the items to the main menu
                foldMenu.Add(menuText, items)
            } else {
                ; For regular items, execute the action
                allKeys := currentParentKeys.Clone()  
                allKeys.Push(currentItem.key)
                keyString := ""
                for key in allKeys {
                    keyString .= key
                }
                ; Capture keyString by value using immediate function execution
                foldMenu.Add(menuText, ((capturedKeys) => (*) => MenuAction(currentItem.label, capturedKeys))(keyString))
            }
        }
    }
    
    ; Set the menu colors to dark theme
    foldMenu.Color := "0x2D2D30"  ; Dark background
    foldMenu.Default := ""
    
    ; Clear the global variable before showing menu
    global SelectedKeys := ""
    
    ; Show menu at calculated position
    ; Menu.Show() in AutoHotkey blocks until selection or cancellation
    try {
        foldMenu.Show(x, y)
    } catch {
        ; Handle any menu display errors
        return false
    }
    
    ; At this point, either an item was selected (SelectedKeys != "") or menu was cancelled
    ; Return the selected keys or false if cancelled
    return SelectedKeys != "" ? SelectedKeys : false
}

MenuAction(action, keySequence := "") {
    ; Store the keys in global variable for GUI menu usage
    global SelectedKeys := keySequence
    ; Simply return the concatenated valid keys without executing any actions
    return keySequence
}
