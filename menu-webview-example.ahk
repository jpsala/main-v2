; ===================================================================
; Ejemplo de uso del sistema de menú WebView
; ===================================================================
; Este archivo muestra cómo usar customMenuWebView() en lugar de customMenu()
; 
; NOTA: Los menús de test ya están integrados en menus.ahk con Win+- hotkeys.
; Este archivo contiene ejemplos adicionales si quieres probar otros casos.
;
; Para activar estos ejemplos, agrega esta línea a main.ahk:
; #Include ".\menu-webview-example.ahk"
; ===================================================================

; Ejemplo 1: Menú de apps con WebView (Win+Shift+A)
#+a:: mainSeqAWebView()

mainSeqAWebView() {
    options := {
        waitml: 800,
        title: "Apps Menu",
        items: [
            { key: '7', label: '70% date for SQ' },
            { key: 'a', label: 'Algo', items: [
                { key: '1', label: 'SQ 14' },
                { key: 'b', label: 'Bots' },
                { key: 'g', label: 'Get-settings' },
                { key: 'e', label: 'Get-settings sources' },
                { key: 'p', label: 'SQ Projects folder in xyplorer' },
                { key: 'x', label: 'SQ Scripts in cursor' },
                { key: 'l', label: 'Lab.v2 Vault' },
                { key: 's', label: 'Leer settings de un proyecto' },
            ]},
            { key: '#b', label: 'Show Bookmarks' },
            { key: 'c', label: 'SpeedCrunch' },
            { key: 'C', label: 'LibreOffice Calc' },
            { key: 'D', label: 'Run Tail.exe (Debug)' },
            { key: 'f', label: 'File Explorer' },
            { key: 'M', label: 'Mixer' },
            { key: 'r', label: 'rust' },
            { key: 's', label: 'Spotify' },
            { key: 'S', label: 'ShareX screenshots' },
            { key: 't', label: 'tablet/telegram/terminal', items: [
                { key: 't', label: 'Windows Terminal' },
                { key: 'w', label: 'Warp Terminal' },
                { key: 'T', label: 'Telegram' },
                { key: 'a', label: 'Tablet' },
            ]},
            { key: 'w', label: 'WhatsApp' },
            { key: 'x', label: 'XYplorer', items: [
                { key: 'x', label: 'XYplorer' },
                { key: 's', label: 'ShareX' },
                { key: 'd', label: 'dev' },
            ]},
            { key: 'y', label: 'Window Spy' },
        ]
    }
    
    ; Usa customMenuWebView en lugar de customMenu
    key := customMenuWebView(options)

    if (!key) {
        return
    }

    ; Handle the selected key
    switch key {
        case '7':
            MsgBox("Ejecutaría: 70% calculator")
        case 'a1':
            MsgBox("Ejecutaría: StrategyQuant X")
        case 'ab':
            MsgBox("Ejecutaría: Bots")
        case 'c':
            MsgBox("Ejecutaría: SpeedCrunch")
        case 'C':
            MsgBox("Ejecutaría: LibreOffice Calc")
        case 'f':
            MsgBox("Ejecutaría: File Explorer")
        case 'tt':
            MsgBox("Ejecutaría: Windows Terminal")
        case 'tw':
            MsgBox("Ejecutaría: Warp Terminal")
        case 'tT':
            MsgBox("Ejecutaría: Telegram")
        case 'ta':
            MsgBox("Ejecutaría: Tablet scrcpy")
        case 'w':
            MsgBox("Ejecutaría: WhatsApp")
        case 'xx':
            MsgBox("Ejecutaría: XYplorer")
        case 'xs':
            MsgBox("Ejecutaría: ShareX folder")
        case 'xd':
            MsgBox("Ejecutaría: dev folder")
        case 'y':
            MsgBox("Ejecutaría: Window Spy")
        default:
            MsgBox("Key seleccionada: " . key)
    }
}

; Ejemplo 2: Menú web con WebView (Win+Shift+W)
#+w:: mainSeqWWebView()

mainSeqWWebView() {
    options := {
        waitml: 800,
        title: "Browser & Web",
        items: [
            { key: 'a', label: 'AI' },
            { key: 'b', label: 'Browser Books' },
            { key: 'c', label: 'Browser Carnival' },
            { key: 'd', label: 'Debug with chrome' },
            { key: 'f', label: 'Browser Main' },
            { key: 's', label: 'Sites', items: [
                { key: 'c', label: 'Google Calendar' },
                { key: 'g', label: 'Gemini' },
                { key: 'j', label: 'Jitsi' },
                { key: 'k', label: 'Google Keep' },
                { key: 'm', label: 'Google Mail' },
                { key: 'd', label: 'Google Drive' },
                { key: 't', label: 'TradingView' },
            ] },
            { key: 'g', label: 'Browser AI' },
            { key: 'v', label: 'Youtube' },
            { key: 'V', label: 'Vivaldi (App)' }
        ]
    }

    key := customMenuWebView(options)
    
    if (!key) {
        return
    }
    
    switch key {
        case 'a':
            MsgBox("Ejecutaría: Browser AI")
        case 'f':
            MsgBox("Ejecutaría: Browser Main")
        case 'v':
            MsgBox("Ejecutaría: YouTube")
        case 'sc':
            MsgBox("Ejecutaría: Google Calendar")
        case 'sg':
            MsgBox("Ejecutaría: Gemini")
        case 'sk':
            MsgBox("Ejecutaría: Google Keep")
        case 'sm':
            MsgBox("Ejecutaría: Google Mail")
        default:
            MsgBox("Key seleccionada: " . key)
    }
}

; Ejemplo 3: Menú de código con WebView (Win+Shift+C)
#+c:: mainSeqCWebView()

mainSeqCWebView() {
    options := {
        waitml: 800,
        title: "Code & Dev",
        items: [
            { key: 'M', label: 'Main script with cursor' },
            { key: 'm', label: 'Main script with vscode' },
            { key: 's', label: 'Scripts folder' },
            { key: 't', label: 'Chat' },
            { key: 'C', label: 'Code' },
            { key: 'c', label: 'Cursor' },
            { key: 'l', label: 'Claude Code' },
        ]
    }

    key := customMenuWebView(options)
    
    if (!key) {
        return
    }
    
    switch key {
        case 'M':
            MsgBox("Ejecutaría: Main scripts with Cursor")
        case 'm':
            MsgBox("Ejecutaría: Main scripts with VSCode")
        case 'c':
            MsgBox("Ejecutaría: Cursor")
        case 'C':
            MsgBox("Ejecutaría: VSCode")
        default:
            MsgBox("Key seleccionada: " . key)
    }
}
