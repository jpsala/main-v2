; ===================================================================
; Apps
; ===================================================================
#a:: mainSeqA()
mainSeqA() {
    options := {
        waitml: 800,
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
            { key: 'o', label: 'Obsidian', items: [
                { key: 'a', label: 'AI' },
                { key: 'l', label: 'Lab.v2' },
                { key: 'm', label: 'Main' },
                { key: 'b', label: 'Bots' },
                { key: 'w', label: 'Work' },
                { key: 'q', label: 'copyq-backup' },
            ]},
            { key: 'r', label: 'rust' },
            { key: 's', label: 'Spotify' },
            { key: 'S', label: 'ShareX screenshots' },
            { key: 't', label: 'tablet/telegram/terminal', items: [
                { key: 't', label: 'Windows Terminal' },
                { key: 'w', label: 'Warp Terminal' },
                { key: 'T', label: 'Telegram' },
                { key: 'a', label: 'Tablet' },
                { key: 'p1', label: 'Phone 500px' },
                { key: 'p2', label: 'Phone 550px' },
                { key: 'p3', label: 'Phone 700px' },
                { key: 'p4', label: 'Phone 900px' },
                { key: 'W', label: 'Tablet WIFI' }
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
    
    key := customMenu(options)

    ; Handle the selected key - can be single key or multi-key sequence
    switch key {
        case '7':
            Roa('test-calc', 'C:\dev\scripts\oss\70.exe')
        case 'a1':
            Roa('strategyquant-x', 'D:\SQX\142\StrategyQuantX_nocheck.exe')
        case 'ab':
            Roa('Bots', 'c:\tools\bots.exe')
        case 'as':
            Roa('sq-admin', 'C:\dev\aguila\sq-admin\build\bin\sq-admin.exe')
        case 'ae':
            Roa('sq-admin-project', cursorExe ' C:\dev\aguila\sq-admin')
            case 'ap':
            Roa('sqx-projects', xyploreExe . ' ' . 'D:\SQX\142\user\projects')
        case 'ax':
            Roa('sq-scripts', cursorExe . ' ' . 'C:\dev\aguila\SQ-scripts')
        case 'al':
            Roa('obsidian-lab', 'obsidian://advanced-uri?vault=Lab.v2', '#d')
        case '#b':
            showBookmarks()
        case 'c':
            Roa('SpeedCrunch', 'C:\tools\speedcrunch\speedcrunch.exe')
        case 'C':
            Roa('libreoffice-calc', 'C:\Program Files\LibreOffice\program\scalc.exe')
        case 'D':
            runLogExe()
        case 'f':
            Roa('file-explorer', 'C:\Windows\explorer.exe')
        case 'M':
            openMixer()
        case 'oa':
            Roa('obsidian-ai', 'obsidian://advanced-uri?vault=ai')
        case 'ol':
            Roa('obsidian-lab', 'obsidian://advanced-uri?vault=Lab.v2', '#d')
        case 'om':
            Roa('obsidian-main', 'obsidian://advanced-uri?vault=Main')
        case 'ob':
            Roa('obsidian-bots', 'obsidian://advanced-uri?vault=bots')
        case 'ow':
            Roa('obsidian-work', 'obsidian://advanced-uri?vault=Work', '#z')
        case 'oq':
            Roa('obsidian-copyq-backup', 'obsidian://advanced-uri?vault=copyq-backup')
        case 'r':
            Roa('rustdesk', "C:\Program Files\RustDesk\rustdesk.exe --connect 21920093", '#r')
        case 's':
            activateOrMinimize('ahk_exe spotify.exe', 'spotify.exe')
        case 'S':
            Roa('sharex-folder', xyploreExe . ' ' . 'C:/Users/jpsal/Pictures/sharex')
        case 'tt':
            Roa('windows-terminal', "C:\Program Files\WindowsApps\Microsoft.WindowsTerminal_1.23.20211.0_x64__8wekyb3d8bbwe\wt.exe")
        case 'tw':
            Roa('warp-terminal', "C:\Users\jpsal\AppData\Local\Programs\Warp\warp.exe")
        case 'tT':
            Roa('telegram', '"C:\tools\Telegram\Telegram.exe"')
        case 'ta':
            Roa('scrcpy-tablet', 'c:\tools\scrcpy\scrcpy-noconsole.vbs --select-usb --turn-screen-off --stay-awake')
        case 'tp1':
            Roa('scrcpy-phone-500px', 'c:\tools\scrcpy\scrcpy-noconsole.vbs --no-power-on --select-usb --turn-screen-off --stay-awake --window-title="My phone" --window-borderless -b 2M -m 800 --max-fps=15  --max-size 1024 --turn-screen-off --stay-awake --max-size 500')
        case 'tp2':
            Roa('scrcpy-phone-550px', 'c:\tools\scrcpy\scrcpy-noconsole.vbs --no-power-on --select-usb --turn-screen-off --stay-awake --window-title="My phone" --window-borderless -b 2M -m 550 --max-fps=15  --max-size 550 --turn-screen-off --stay-awake --max-size 550')
        case 'tp3':
            Roa('scrcpy-phone-700px', 'c:\tools\scrcpy\scrcpy-noconsole.vbs --no-power-on --select-usb --turn-screen-off --stay-awake --window-title="My phone" --window-borderless -b 2M -m 800 --max-fps=15  --max-size 1024 --turn-screen-off --stay-awake --max-size 700')
        case 'tp4':
            Roa('scrcpy-phone-900px', 'c:\tools\scrcpy\scrcpy-noconsole.vbs --no-power-on --select-usb --turn-screen-off --stay-awake --window-title="My phone" --window-borderless -b 2M -m 800 --max-fps=15  --max-size 1024 --turn-screen-off --stay-awake --max-size 900')
        case 'tW':
            Roa('scrcpy-wifi', 'c:\tools\scrcpy\scrcpy-noconsole.vbs -b 1M -m 1024')
        case 'w':
            RoAWithPattern('WhatsApp Beta', '"C:\Program Files\WindowsApps\5319275A.51895FA4EA97F_2.2564.350.0_x64__cv1g1gvanyjgm\whatsapp.exe"')
        case 'xx':
            Roa('xyplorer', 'C:\tools\xyplorer-portable\XYplorer.exe')
        case 'xs':
            Roa('sharex-folder', xyploreExe . ' ' . 'C:/Users/jpsal/Pictures/sharex')
        case 'xd':
            Roa('dev-folder', xyploreExe . ' ' . 'C:/dev')
        case 'y':
            Roa('window-spy', 'C:\Program Files\AutoHotkey\UX\WindowSpy.ahk')
    }
}
; ===================================================================
; Browser & Web
; ===================================================================
#w:: mainSeqW()
mainSeqW() {
    options := {
        waitml: 800,
        items: [
            { key: '$', label: 'USD' },
            { key: 'a', label: 'AI' },
            { key: 'A', label: 'Amaia' },
            { key: 'b', label: 'Browser Books' },
            { key: 'c', label: 'Browser Carnival' },
            { key: '#c', label: 'chrome-main' },
            { key: 'd', label: 'Debug with chrome' },
            { key: '#d', label: 'Debug with chrome' },
            { key: 'D', label: 'Debug with vivaldi' },
            { key: 'f', label: 'Browser Main' },
            { key: 's', label: 'Sites', items: [
                { key: 'c', label: 'Google Calendar' },
                { key: 'g', label: 'Gemini' },
                { key: 'j', label: 'Jitsi' },
                { key: 'k', label: 'Google Keep' },
                { key: 'm', label: 'Google Mail' },
                { key: 'cu', label: 'Cursor Dashboard' },
                { key: 'd', label: 'Google Drive' },
                { key: 't', label: 'TradingView' },
            ] },
            { key: 'F', label: 'Chrome Debug' },
            { key: 'g', label: 'Browser AI' },
            { key: 'G', label: 'Browser Gordos' },
            { key: 'r', label: 'Debug' },
            { key: 'w', label: 'Work' },
            { key: '#w', label: 'Work (Alt)' },
            { key: '#d', label: 'chrome-debug (Alt)' },
            { key: 'v', label: 'Youtube' },
            { key: 'yv', label: 'YouTube Video Downloader' },
            { key: 'ya', label: 'YouTube Audio Downloader' },
            { key: 'V', label: 'Vivaldi (App)' }
        ]
    }

    key := customMenu(options)
    
    switch key {
        ; case 'a':
        ;     openGptBrowser()
        ; case 'A':
        ;     Roa('chrome-amaia', browserWithAmaiaProfile)
        ; case 'c':
        ;     Roa('google-calendar', browserWithMainProfile . ' https://calendar.google.com/calendar/u/0/r')
        case 'c':
            Roa('chrome-carnival', vivaldiWithCarnivalProfile)
        case '#c':
            Roa('chrome-main', browserWithChromeMainProfile)
        case 'd', '#d':
            A_Clipboard := chromeWithDebugProfile
            run(chromeWithDebugProfile)
        case 'D':
            run(vivaldiWithDebugProfile)
        case 'f':
            Roa('vivaldi-main', vivaldiWithMainProfile, '#f')
        case 'v':
            Roa('vivaldi-youtube', vivaldiWithYoutubeProfile, '#v')
        case 'sc':
            Roa('google-calendar', vivaldiWithMainProfile . ' https://calendar.google.com/calendar/u/0/r')
        case 'sg':
            Roa('vivaldi-gemini', vivaldiWithGeminProfile . ' https://gemini.google.com/ --new-window', '#i')
        case 'sj':
            Roa('jitsi-meet', vivaldiWithMainProfile . ' https://meet.jit.si/JP_ALFRE_REDACTED_SECRET')
        case 'sk':
            Roa('google-keep', vivaldiWithMainProfile . ' https://keep.google.com/')
        case 'sm':
            Roa('google-mail', vivaldiWithMainProfile . ' https://mail.google.com')
        case 'scu':
            Roa('cursor-dashboard', vivaldiWithMainProfile . ' https://cursor.com/dashboard?tab=billing')
        case 'sd':
            Roa('google-drive', vivaldiWithMainProfile . ' https://drive.google.com/drive/my-drive?ths=true')
        case 'st':
            Roa('tradingview', vivaldiWithMainProfile . ' https://www.tradingview.com/chart')
        case 'b':
            Roa('vivaldi-books', vivaldiWithBooksProfile, '#b')
        case 'F':
            run(chromeWithDebugProfile)
        case 'g':
            Roa('vivaldi-ai', vivaldiWithAIProfile, '#g')
        case 'G':
            run(vivaldiWithGordosProfile)
        case 'w', 'w':
            Roa('browser-work', chromeWithWorkProfile)
        case 'yv':
            DownloadYouTubeVideoFromClipboard()
        case 'ya':
            DownloadYouTubeAudioFromClipboard()
        case 'V':
            Roa('vivaldi', vivaldiExe)
    }
}
; ===================================================================
; Code
; ===================================================================
#c:: mainSeqC()
mainSeqC() {
    options := {
        waitml: 800,
        items: [
            { key: 'M', label: 'Main script with cursor' },
            { key: 'm', label: 'Main script with vscode' },
            { key: 's', label: 'Scripts folder' },
            { key: 't', label: 'Chat' },
            { key: 'C', label: 'Code' },
            { key: 'c', label: 'Cursor' },
            { key: 'l', label: 'Claude Code' },
            { key: 'q', label: 'copyQ data' },
            { key: 'p', label: 'Passwords' },
        ]
    }

    key := customMenu(options)
    switch key {
        case 'p':
            Roa('passwords-backup', cursorExe . ' "D:\user-home-in-d\Documents\Chrome Passwords Backup.csv"')
        case 'M':
            Roa('main-scripts', cursorExe . ' c:\dev\scripts\main', '!m')
        case 'm':
            Roa('main-scripts', vscodeExe . ' c:\dev\scripts\main', '!m')
        case 's':
            Roa('scripts-folder', cursorExe . ' c:\dev\scripts', '!s')
        case 't':
            Roa('chat', cursorExe . ' c:\dev\chat', '#t')
        case 'C':
            RoAWithPattern('ahk_exe Code.exe', vscodeExe, '^!c')
        case 'c':
            Roa('cursor', cursorExe)
        case 'l':
            Roa('claude-code', 'wt --size 90,35 -p "Claude" -- claude --dangerously-skip-permissions --chrome --ide ')
        case 'q':
            Roa('chrome-passwords-copyq', cursorExe ' "D:\user-home-in-d\Documents\copyq-backup"')
        case 'P':
            Roa('chrome-passwords-copyq', cursorExe ' "D:\user-home-in-d\Documents\copyq-backup"')
        case 'p':
            Roa('chrome-passwords-csv', cursorExe ' "D:\user-home-in-d\Documents\Chrome Passwords.csv"')
    }
}
; ===================================================================
; Vivaldi
; ===================================================================
#HotIf WinActive('ahk_exe vivaldi.exe')
    ^!x:: {
        options := {
            waitml: 800,
            items: [
                { key: 'yv', label: 'YouTube Video Downloader' },
                { key: 'ya', label: 'YouTube Audio Downloader' },
                { key: 'ax', label: 'Toggle AI Chatbot Sidebar' },
                { key: 'az', label: 'Toggle Firefox Sidebar' },
                { key: 'od', label: 'Open Downloads' },
                { key: 'tr', label: 'Toggle Reader Mode (Windows)' },
                { key: 'ap', label: 'About Processes' },
                { key: 'sb', label: 'Show Bookmarks Sidebar' },
                { key: 'tb', label: 'Show Bookmarks Toolbar' },
                { key: 'c', label: 'close split view' },
                { key: 'h', label: 'split view horizontal' },
                { key: 'v', label: 'split view vertical' },
                { key: 'x', label: 'Clear Context' }
            ]
        }
        key := customMenu(options)
        
        switch key {
            case 'yv':
                ytdVideo()
            case 'ya':
                ytdAudio()
            case 'ax':
                Send("!^+x")
            case 'az':
                Send("!^+z")
            case 'od':
                Send("^j")
            case 'tr':
                Send("{f9}")
            case 'ap':
                Send("+{esc}")
            case 'sb':
                Send("^b")
            case 'tb':
                Send("+^b")
            case 'c':
                send('^+:')
            case 'h':
                send('!x')
            case 'v':
                send('!^v')
            case 'x':
                send('!x')
        }
    }

    ytdVideo() {
        url := A_Clipboard
        if (!InStr(url, 'https://www.youtube.com/watch?') and !InStr(url, 'https://youtu.be') and !InStr(url, 'https://www.youtube.com/shorts/')) {
            MsgBox('not valid url in clipboard')
            return
        }
        run('c:\tools\ytd.bat ' . url)
        copyToClipboard('c:\tools\ytd.bat ' . url)
    }

    ytdAudio() {
        url := A_Clipboard
        if (!InStr(url, 'https://www.youtube.com/watch?') and !InStr(url, 'https://youtu.be')) {
            MsgBox('not valid url in clipboard')
            return
        }
        run('c:\tools\ytd-audio.bat ' . url)
    }
    ; Helper function (if you don't already have it)

    ; !s:: {
    ;     options := {
    ;         waitml: 800,
    ;         items: [
    ;             { key: 'c', label: 'close split view' },
    ;             { key: 'h', label: 'split view horizontal' },
    ;             { key: 'v', label: 'split view vertical' }
    ;         ]
    ;     }
    ;     key := customMenu(options)

    ;     switch key {
    ;         case 'c':
    ;             send('^!x')
    ;         case 'h':
    ;             send('!^v')
    ;         case 'v':
    ;             send('!^h')
    ;         case 'yv':
    ;             url := A_Clipboard
    ;             ; https://youtu.be/Y_nRfa7S9F0?si=AG4nlUguFSJ-SdcZ
    ;             if (!InStr(url, 'https://www.youtube.com/watch?') and !InStr(url, 'https://youtu.be') and !InStr(url, 'https://www.youtube.com/shorts/')) {
    ;                 MsgBox('not valid url in clipboard')
    ;                 return
    ;             }
    ;             run('c:\tools\ytd.bat ' . url)
    ;             copyToClipboard('c:\tools\ytd.bat ' . url)
    ;         case 'ya':
    ;             url := A_Clipboard
    ;             if (!InStr(url, 'https://www.youtube.com/watch?') and !InStr(url, 'https://youtu.be')) {
    ;                 MsgBox('not valid url in clipboard')
    ;                 return
    ;             }
    ;             run('c:\tools\ytd-audio.bat ' . url)
    ;     }
    ; }
#HotIf

; ===================================================================
; Remote
; ===================================================================
#HotIf WinActive('ahk_exe mstsc.exe') or WinActive('ahk_exe StrategyQuantX_nocheck.exe')
    !p:: {
        msg('mstsc')
        options := {
            items: [
                { key: 'b', label: 'Bots', items: [
                    { key: 'b', label: 'Base' },
                    { key: 'o', label: 'Original' },
                    { key: 'm', label: 'MQ5' },
                ]}
            ]
        }
        key := customMenu(options)
        switch key {
            case 'bb':
                send('g:\my drive\sqx\bots\')
            case 'bo':
                send('g:\my drive\sqx\bots\original\')
            case 'bm':
                send('g:\my drive\sqx\bots\mq5\')
        }
    }
#HotIf
tv() {
    log(1)
    list := WinGetList(tvWin)
    if (list.Length == 0) {
        Run(browserWithTradingProfile 'https://www.tradingview.com/chart --new-window')
        ll := WinWaitActive(tvWin, , 20)
        setManualBookmark('#t', ll)
        send('{F11}')
        return
    }
    for index, id in list {
        if (!WinActive(id)) {
            WinActivateFast('ahk_id ' id)
        } else {
            WinMinimize('ahk_id ' id)
        }
    }
}

mysqlServiceUp() {
    Run('"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools\services.lnk"')
    Sleep(1000)
    MouseClick('Left', 444, 253)
    Sleep(100)
    send('mysql')
    sleep(500)
    send('+{F10}')
    Sleep(100)
    send('s')
}

activateTeams() {
    toggleOrLaunchApp({
        winPattern: 'ahk_exe ms-teams.exe',
        launchCmd: 'C:\Program Files\WindowsApps\MSTeams_24074.2321.2810.31000_x64__8wekyb3d8bbwe\ms-teams.exe',
        extraCheck: (hwnd, class, title) => InStr(title, ' | ')
    })
}

DownloadYouTubeVideoFromClipboard() {
    url := A_Clipboard
    if !IsValidYouTubeUrl(url) {
        MsgBox('Clipboard does not contain a valid YouTube video or shorts URL.`n`n' url, 'Invalid URL', 'IconWarning')
        return
    }
    command := 'c:\tools\ytd.bat "' . url . '"' ; Enclose URL in quotes for safety
    try {
        Run(command)
        ; Optionally copy the command for debugging/verification
        ; A_Clipboard := command
    } catch Error as e {
        MsgBox('Failed to run YouTube download command:`n' command '`n`nError: ' e.Message, 'Execution Error', 'IconError')
    }
}

DownloadYouTubeAudioFromClipboard() {
    url := A_Clipboard
    if !IsValidYouTubeUrl(url, false) { ; Allow standard videos/links, maybe not shorts for audio? Adjust as needed.
        MsgBox('Clipboard does not contain a valid YouTube URL for audio download.`n`n' url, 'Invalid URL', 'IconWarning')
        return
    }
    command := 'c:\tools\ytd-audio.bat "' . url . '"' ; Enclose URL in quotes
    try {
        Run(command)
    } catch Error as e {
        MsgBox('Failed to run YouTube audio download command:`n' command '`n`nError: ' e.Message, 'Execution Error', 'IconError')
    }
}

IsValidYouTubeUrl(url, allowShorts := true) {
    ; Basic check for non-empty string
    if (url = "")
        return false

    ; More robust RegEx check for common YouTube URL patterns
    ; Covers: youtube.com/watch?v=..., youtu.be/..., youtube.com/shorts/...
    pattern := "i)https?://(www\.)?(youtube\.com/(watch\?v=|embed/|v/)|youtu\.be/)"
    if (allowShorts) {
        pattern .= "|https?://(www\.)?youtube\.com/shorts/"
    }

    return RegExMatch(url, pattern)
}



; Note: The original SeqGui function has been removed and replaced with customMenu calls throughout the file