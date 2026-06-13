; Este script es una plantilla independiente para que agentes automaticen Windows con AutoHotkey v2.
; No dependas del resto del repo: copiá este archivo, cambiale el nombre y ajustalo para tu tarea.
; El binario de AutoHotkey está en "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe".
; Usalo como base para teclado, mouse, ventanas, logs, abrir utilitarios o automatizaciones varias.
; Hay herramientas de linea de comandos y otros utilitarios en C:\tools.
; Usa try/catch siempre que puedas para evitar mensajes de error interactivos al usuario.
; Si descubris una limitacion o una solucion util durante una automatizacion, documentala aca.
; Nota util: en AHK v2 conviene pasar datos por parametros o `global`, no asumir que una funcion
; definida dentro de un bloque va a capturar variables externas como en JavaScript.
; Nota util: para corridas repetidas, usa logs por corrida (`archivo-YYYYMMDD-HHMMSS.log`) en vez de
; truncar siempre el mismo archivo si otro proceso todavia puede tenerlo abierto.
; Nota util: en Windows real, `ahk_exe foo.exe` suele ser mas robusto que depender del titulo visible.
; Nota util: cuando cruces rects del renderer con clicks nativos, confirma si esos rects son relativos
; al client area o al frame externo de la ventana antes de sumar coordenadas.
; Nota util: en AHK v2 `WinGetTitle(selector)` devuelve el string directamente.

#Requires AutoHotkey v2.0
#SingleInstance Force
#ErrorStdOut UTF-8

CoordMode('Mouse', 'Window')
InstallKeybdHook()
InstallMouseHook()
SendMode("Input")
SetTitleMatchMode(2)
SetWorkingDir(A_ScriptDir)

global tempLogFile := A_Temp . "\codex-example-log.txt"

try {
    EmptyLog(tempLogFile)
    LogTempExample()

    ; Ejemplos de helpers reutilizables:
    ; SafeRun("notepad.exe")

    ExitApp(0)
} catch Error as e {
    log({ logFilePath: tempLogFile, isError: true }, "error en ejemplo.ahk", FormatException(e))
    ExitApp(1)
}

LogTempExample() {
    global tempLogFile
    log({ logFilePath: tempLogFile }, "esto es un ejemplo en la carpeta temporaria de windows")
}

log(params*) {
    logOptions := {}
    if (params.Length > 0 && IsObject(params[1]) && Type(params[1]) = "Object") {
        logOptions := params[1]
        params.RemoveAt(1)
    }

    logFilePath := GetOption(logOptions, "logFilePath", A_ScriptDir . "\log.txt")
    isError := GetOption(logOptions, "isError", false)
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    renderedParams := []

    for value in params {
        renderedParams.Push(FormatLogValue(value))
    }

    line := timestamp
    if (isError) {
        line .= " | [ERROR]"
    }
    if (renderedParams.Length > 0) {
        line .= " | " . JoinStrings(renderedParams, " | ")
    }

    EnsureParentDir(logFilePath)
    FileAppend(line . "`n", logFilePath, "UTF-8")
}

EmptyLog(logFilePath) {
    EnsureParentDir(logFilePath)
    if (FileExist(logFilePath)) {
        FileDelete(logFilePath)
    }
    FileAppend("Emptied`n", logFilePath, "UTF-8")
}

SafeRun(command, workingDir := "") {
    try {
        Run(command, workingDir)
    } catch Error as e {
        throw Error("SafeRun fallo | " . command . " | " . FormatException(e), -1)
    }
}

GetOption(options, key, defaultValue := "") {
    if (IsObject(options) && Type(options) = "Object" && options.HasOwnProp(key)) {
        return options.%key%
    }
    return defaultValue
}

EnsureParentDir(filePath) {
    SplitPath(filePath, , &dirPath)
    if (dirPath != "" && !DirExist(dirPath)) {
        DirCreate(dirPath)
    }
}

FormatLogValue(value) {
    valueType := Type(value)

    if (value is Error) {
        return FormatException(value)
    }

    if (valueType = "Array") {
        parts := []
        for item in value {
            parts.Push(FormatLogValue(item))
        }
        return "[" . JoinStrings(parts, ", ") . "]"
    }

    if (valueType = "Map") {
        parts := []
        for key, item in value {
            parts.Push(String(key) . ": " . FormatLogValue(item))
        }
        return "Map{" . JoinStrings(parts, ", ") . "}"
    }

    if (IsObject(value)) {
        return "<" . valueType . ">"
    }

    return String(value)
}

FormatException(err) {
    filePart := ""
    linePart := ""

    if (err.File != "") {
        filePart := " | file=" . err.File
    }
    if (err.Line != "") {
        linePart := " | line=" . err.Line
    }

    return err.Message . filePart . linePart
}

JoinStrings(values, separator := ", ") {
    result := ""
    for index, value in values {
        if (index > 1) {
            result .= separator
        }
        result .= value
    }
    return result
}
