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
            Roa('sqx-projects', xyplorerExe . ' ' . 'D:\SQX\142\user\projects')
        case 'ax':
            Roa('sq-scripts', cursorExe . ' ' . 'C:\dev\aguila\SQ-scripts')
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
        case 'r':
            Roa('rustdesk', "C:\Program Files\RustDesk\rustdesk.exe --connect 21920093", '#r')
        case 's':
            Roa('spotify', 'spotify.exe')
        case 'S':
            Roa('sharex-folder', xyplorerExe . ' ' . 'C:/Users/jpsal/Pictures/sharex')
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
            Roa('sharex-folder', xyplorerExe . ' ' . 'C:/Users/jpsal/Pictures/sharex')
        case 'xd':
            Roa('dev-folder', xyplorerExe . ' ' . 'C:/dev')
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



; Note: The original SeqGui function has been removed and replaced with customMenu calls throughout the file