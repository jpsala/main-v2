; ===================================================================
; Menu WebView Test - Win+` para probar el sistema
; ===================================================================
; Para activar, agrega en main.ahk:
; #Include ".\menu-webview-test.ahk"
; ===================================================================

#`:: testMenuWebView()

testMenuWebView() {
    options := {
        waitml: 800,
        title: "Test Menu",
        items: [
            { key: '1', label: 'Option One' },
            { key: '2', label: 'Option Two' },
            { key: '3', label: 'Option Three' },
            { key: 'a', label: 'Apps', items: [
                { key: 'c', label: 'Calculator' },
                { key: 'n', label: 'Notepad' },
                { key: 'e', label: 'Explorer' },
            ]},
            { key: 'b', label: 'Browsers', items: [
                { key: 'c', label: 'Chrome' },
                { key: 'f', label: 'Firefox' },
                { key: 'e', label: 'Edge' },
                { key: 'v', label: 'Vivaldi' },
            ]},
            { key: 't', label: 'Tools', items: [
                { key: 't', label: 'Terminal' },
                { key: 'c', label: 'Code Editor', items: [
                    { key: 'v', label: 'VS Code' },
                    { key: 'c', label: 'Cursor' },
                    { key: 's', label: 'Sublime' },
                ]},
                { key: 's', label: 'System Monitor' },
            ]},
            { key: 'x', label: 'Exit Test' },
        ]
    }
    
    key := customMenuWebView(options)
    
    if (!key) {
        ToolTip("Cancelled", , , 1)
        SetTimer(() => ToolTip(, , , 1), -2000)
        return
    }
    
    ; Show result
    msg := "Selected: " . key . "`n`n"
    
    switch key {
        case '1':
            msg .= "You selected Option One"
        case '2':
            msg .= "You selected Option Two"
        case '3':
            msg .= "You selected Option Three"
        case 'ac':
            msg .= "You selected Apps → Calculator"
        case 'an':
            msg .= "You selected Apps → Notepad"
        case 'ae':
            msg .= "You selected Apps → Explorer"
        case 'bc':
            msg .= "You selected Browsers → Chrome"
        case 'bf':
            msg .= "You selected Browsers → Firefox"
        case 'be':
            msg .= "You selected Browsers → Edge"
        case 'bv':
            msg .= "You selected Browsers → Vivaldi"
        case 'tt':
            msg .= "You selected Tools → Terminal"
        case 'tcs':
            msg .= "You selected Tools → Code Editor → Sublime"
        case 'tcv':
            msg .= "You selected Tools → Code Editor → VS Code"
        case 'tcc':
            msg .= "You selected Tools → Code Editor → Cursor"
        case 'ts':
            msg .= "You selected Tools → System Monitor"
        case 'x':
            msg .= "You selected Exit Test"
        default:
            msg .= "Unknown key: " . key
    }
    
    MsgBox(msg, "Test Result", "T5")
}

; Test simple sin submenus - Win+Shift+`
#+`:: testSimpleMenu()

testSimpleMenu() {
    options := {
        waitml: 600,
        title: "Simple Test",
        items: [
            { key: 'a', label: 'Alpha' },
            { key: 'b', label: 'Beta' },
            { key: 'c', label: 'Gamma' },
            { key: 'd', label: 'Delta' },
            { key: 'e', label: 'Epsilon' },
            { key: 'f', label: 'Zeta' },
            { key: 'g', label: 'Eta' },
            { key: 'h', label: 'Theta' },
        ]
    }
    
    key := customMenuWebView(options)
    
    if (!key) {
        ToolTip("Cancelled", , , 1)
        SetTimer(() => ToolTip(, , , 1), -2000)
        return
    }
    
    ToolTip("Selected: " . key, , , 1)
    SetTimer(() => ToolTip(, , , 1), -2000)
}

; Test de muchos items - Win+Ctrl+`
#^`:: testLargeMenu()

testLargeMenu() {
    items := []
    
    ; Generate 30 test items
    Loop 30 {
        items.Push({ 
            key: String(A_Index), 
            label: "Test Item " . A_Index . " - Lorem ipsum dolor sit amet"
        })
    }
    
    options := {
        waitml: 500,
        title: "Large Menu Test (30 items)",
        items: items
    }
    
    key := customMenuWebView(options)
    
    if (!key) {
        ToolTip("Cancelled", , , 1)
        SetTimer(() => ToolTip(, , , 1), -2000)
        return
    }
    
    MsgBox("You selected item: " . key, "Large Menu Result", "T3")
}
