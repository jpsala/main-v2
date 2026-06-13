;===============================================================================
; LOGGING MODULE
; Debugging and logging utilities
;===============================================================================

log(params*) {
    if (!IsSet(logVisibility)) {
        logVisibility := false
    }
    
    ; Check if first parameter is an object with log options
    logOptions := {}
    if (params.Length > 0 && Type(params[1]) == "Object") {
        logOptions := params[1]
        params.RemoveAt(1) ; Remove the options object from params
    }
    
    ; Set default options
    showLog := false
    isError := false
    logFilePath := ""
    
    ; Check if logOptions has the properties
    if (logOptions) {
        if (logOptions.HasOwnProp("showLog")) {
            showLog := logOptions.showLog
        }
        if (logOptions.HasOwnProp("isError")) {
            isError := logOptions["isError"]
        }
        if (logOptions.HasOwnProp("logFilePath")) {
            logFilePath := logOptions.logFilePath
        }
    }
    
    result := ''

    tryAgain := false
    try {
        ; Add error prefix if this is an error log
        if (isError) {
            result := "[ERROR] "
        }
        
        for idx, param in params {
            separator := (idx < params.Length) ? ' | ' : ''
            if (Type(param) == 'Array') {
                arr := 'Arr-> '
                for a, b in param {
                    arr .= '[' String(a) ']' ':' String(b)
                    if (a < param.Length) {
                        arr .= ' | '
                    }
                }
                result .= arr . separator
            } else {
                result .= String(param) . separator
            }
        }
        ; Default to the repo log files unless a custom target was provided.
        logFile := logFilePath ? logFilePath : A_ScriptDir . '\' . (isError ? 'error.txt' : 'log.txt')
        if (!logFile) {
            msgV1("Error: Missing log file path", 3)
            return
        }
        try {
            FileAppend(result . '`n', logFile)
        } catch Error as e {
            tryAgain := true
        }
        if (tryAgain) {
            Sleep 100
            try {
                FileAppend(result . '`n', logFile)
            } catch Error as e2 {
                msg("Error appending to log file", e2.Message, e2.File, e2.Line, { Seconds: 3 })
                return
            }
        }
        if (showLog or logVisibility) {
            runLogExe(logFile)
            Sleep 100
        }
    } catch Error as e {
        msg("Error appending to log file", e.Message, e.File, e.Line, { Seconds: 3 })
    }
}

runLogExe(logFile := "") {
    if (!WinExist("ahk_exe Tail.exe")) {
        tailExe := GetCachedConfig("desktop", "tail_exe", "")
        logFile := logFile ? logFile : A_ScriptDir . '\log.txt'

        if (!tailExe) {
            msgV1("Error: Missing tail path in config.ini", 3)
            return
        }

        win := WinGetID('A')
        Run(tailExe . ' ' . logFile)
        WinWaitActive("ahk_exe Tail.exe")
        WinActivateFast("ahk_exe Tail.exe")
        WinSetAlwaysontop(-1, "A")
        WinActivateFast(win)
        WinMoveTop("ahk_exe Tail.exe")
    }
}

emptylog(logFile := '') {
    logFile := logFile ? logFile : A_ScriptDir . '\log.txt'
    
    if (!logFile) {
        msgV1("Error: Missing log file path", 3)
        return
    }
    if (FileExist(logFile)) {
        try {
            FileDelete(logFile)
        } catch Error as e {
            MsgBox('Error deleting log file: ' . e.Message)
            msgV1("Error deleting log file", 3, 19)
        }
    }
    Sleep 100
    FileAppend("Emptied" . '`n', logFile)
}
