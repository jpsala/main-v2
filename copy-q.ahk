#Requires AutoHotkey v2.0

; ===================================================================
; CopyQ + Clipboard Agent
; Centralizes CopyQ launchers, Clipboard Agent UI, and related hotkeys.
; ===================================================================

global COPYQ_EXE := "c:\tools\copyq\copyq.exe"
global CLIP_AGENT_PYTHON := "python"
global CLIP_AGENT_SCRIPT := "C:\dev\clip\scripts\clipboard_agent.py"
global CLIP_AGENT_WORKDIR := "C:\dev\clip"
global CLIP_AGENT_TEMP_DIR := "C:\temp\clipboard_agent"
global CLIP_AGENT_LOG_FILE := "C:\dev\clip\launcher.log"
global CLIP_AGENT_LAST_WINDOW := CLIP_AGENT_TEMP_DIR "\last_window.txt"
global CLIP_AGENT_INPUT_FILE := CLIP_AGENT_TEMP_DIR "\launcher_input.txt"
global CLIP_AGENT_OUTPUT_FILE := CLIP_AGENT_TEMP_DIR "\launcher_output.txt"
global CLIP_ANNOTATE_COPY_SCRIPT := "C:\dev\clip\scripts\annotate_copyq_item.py"
global CLIP_ANNOTATE_CONTEXT_FILE := CLIP_AGENT_TEMP_DIR "\annotate_copyq_item_context.txt"
global CLIP_ANNOTATE_OUTPUT_FILE := CLIP_AGENT_TEMP_DIR "\annotate_copyq_item_output.txt"
global CLIP_SEND_TO_PASS_SCRIPT := "C:\dev\clip\scripts\send_item_to_pass.py"
global CLIP_SEND_TO_PASS_OUTPUT_FILE := CLIP_AGENT_TEMP_DIR "\send_to_pass_output.txt"
global COPYQ_EXPORT_SELECTED_IMAGES_SHORTCUT := "^!+e"

CopyQ_EnsureTempDir() {
    global CLIP_AGENT_TEMP_DIR
    try DirCreate(CLIP_AGENT_TEMP_DIR)
}

CopyQ_Log(msg) {
    global CLIP_AGENT_LOG_FILE
    ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    try FileAppend("[" ts "] [copy-q] " msg "`n", CLIP_AGENT_LOG_FILE, "UTF-8")
}

CopyQ_EnsureAvailable() {
    global COPYQ_EXE
    if (FileExist(COPYQ_EXE))
        return true

    CopyQ_Log("CopyQ no encontrado en " COPYQ_EXE)
    msg("CopyQ no encontrado: " . COPYQ_EXE, { seconds: 4 })
    return false
}

CopyQ_Run(arguments) {
    global COPYQ_EXE
    if (!CopyQ_EnsureAvailable())
        return false

    try {
        Run('"' . COPYQ_EXE . '" ' . arguments)
        return true
    } catch Error as err {
        CopyQ_Log("Error ejecutando CopyQ (" arguments "): " err.Message)
        msg("No pude ejecutar CopyQ: " . err.Message, { seconds: 4 })
        return false
    }
}

CopyQ_Show() {
    CopyQ_Log("show")
    return CopyQ_Run("show")
}

CopyQ_Hide() {
    CopyQ_Log("hide")
    return CopyQ_Run("hide")
}

CopyQ_SaveActiveWindowContext() {
    global CLIP_AGENT_LAST_WINDOW

    CopyQ_EnsureTempDir()

    winTitle := WinGetTitle("A")
    winExe := WinGetProcessName("A")
    CopyQ_Log("guardando ventana activa: '" winTitle "' (" winExe ")")

    try FileDelete(CLIP_AGENT_LAST_WINDOW)
    FileAppend(winTitle "`n" winExe, CLIP_AGENT_LAST_WINDOW, "UTF-8")
}

OpenCopyQSaveWindow() {
    if (WinActive("ahk_exe copyq.exe")) {
        return CopyQ_Hide()
    }

    CopyQ_SaveActiveWindowContext()
    return CopyQ_Show()
}

ClipboardAgent_EnsureAvailable() {
    global CLIP_AGENT_SCRIPT
    if (FileExist(CLIP_AGENT_SCRIPT))
        return true

    CopyQ_Log("Clipboard Agent script no encontrado: " CLIP_AGENT_SCRIPT)
    msg("Clipboard Agent no encontrado: " . CLIP_AGENT_SCRIPT, { seconds: 4 })
    return false
}

ClipboardAgent_ShowResult(text, title := "Clipboard Agent") {
    g := Gui("+Resize", title)
    g.SetFont("s10", "Segoe UI")

    g.AddEdit("r12 w560 ReadOnly -Wrap", text)

    btnCopy := g.AddButton("w130", "Copiar al clipboard")
    btnCopy.OnEvent("Click", (*) => (A_Clipboard := text, ToolTip("Copiado.", , , 2), Sleep(1200), ToolTip(, , , 2)))

    btnClose := g.AddButton("x+10 w80", "Cerrar")
    btnClose.OnEvent("Click", (*) => g.Destroy())

    g.OnEvent("Close", (*) => g.Destroy())
    g.Show("w590")
}

RunClipboardAgent() {
    global CLIP_AGENT_PYTHON
    global CLIP_AGENT_SCRIPT
    global CLIP_AGENT_WORKDIR
    global CLIP_AGENT_INPUT_FILE
    global CLIP_AGENT_OUTPUT_FILE

    if (!ClipboardAgent_EnsureAvailable())
        return

    CopyQ_EnsureTempDir()

    ib := InputBox("¿Qué querés hacer?", "Clipboard Agent", "W480 H80")
    CopyQ_Log("InputBox: " ib.Result " / " ib.Value)
    if (ib.Result != "OK" or Trim(ib.Value) = "")
        return

    try FileDelete(CLIP_AGENT_INPUT_FILE)
    try FileDelete(CLIP_AGENT_OUTPUT_FILE)
    FileAppend(ib.Value, CLIP_AGENT_INPUT_FILE, "UTF-8")

    ToolTip("Clipboard Agent — pensando...", , , 1)

    cmd := CLIP_AGENT_PYTHON ' "' CLIP_AGENT_SCRIPT '" --quiet --message-file "' CLIP_AGENT_INPUT_FILE '"'
    fullCmd := 'cmd /c ' cmd ' > "' CLIP_AGENT_OUTPUT_FILE '" 2>&1'
    CopyQ_Log("ejecutando: " fullCmd)

    try {
        RunWait(fullCmd, CLIP_AGENT_WORKDIR, "Hide")
        CopyQ_Log("RunWait terminó")
    } catch Error as err {
        ToolTip(, , , 1)
        CopyQ_Log("Error ejecutando Clipboard Agent: " err.Message)
        msg("No pude ejecutar el Clipboard Agent: " . err.Message, { seconds: 4 })
        return
    }

    ToolTip(, , , 1)

    result := ""
    if FileExist(CLIP_AGENT_OUTPUT_FILE) {
        result := Trim(FileRead(CLIP_AGENT_OUTPUT_FILE, "UTF-8"))
        CopyQ_Log("output (" StrLen(result) " chars): " SubStr(result, 1, 200))
        try FileDelete(CLIP_AGENT_OUTPUT_FILE)
    } else {
        CopyQ_Log("ERROR: no existe " CLIP_AGENT_OUTPUT_FILE)
    }

    if (result = "")
        result := "(sin respuesta)"

    ClipboardAgent_ShowResult(result)
}

CopyQ_LabelSelectedItem() {
    ib := InputBox("Label for selected item", "copyq", , "")
    if (ib.Result != "OK" or Trim(ib.Value) = "")
        return

    BlockInput(true)
    try {
        OpenCopyQSaveWindow()

        if (!WinWaitActive("ahk_exe copyq.exe", , 2)) {
            msg("CopyQ window not found.")
            return
        }

        Send("+{F2}")
        Sleep(40)
        Send(ib.Value)
        Sleep(400)
        Send("{F2}")
        Sleep(100)
        CopyQ_Hide()
    } finally {
        BlockInput(false)
    }
}

CopyQ_ConfirmSearchSelection() {
    Send("^{Home}")
    Sleep(20)
    Send("{Enter}")
}

CopyQ_SmartCopy() {
    return CopyQ_SmartCopyToTab("&clipboard")
}

CopyQ_SmartCopyToTab(targetTab := "&clipboard") {
    global CLIP_AGENT_PYTHON
    global CLIP_AGENT_WORKDIR
    global CLIP_ANNOTATE_COPY_SCRIPT
    global CLIP_ANNOTATE_CONTEXT_FILE
    global CLIP_ANNOTATE_OUTPUT_FILE
    global CLIP_SEND_TO_PASS_SCRIPT
    global CLIP_SEND_TO_PASS_OUTPUT_FILE

    if (!FileExist(CLIP_ANNOTATE_COPY_SCRIPT)) {
        msg("Script no encontrado: " . CLIP_ANNOTATE_COPY_SCRIPT, { seconds: 4 })
        return false
    }

    CopyQ_EnsureTempDir()

    sourceTitle := WinGetTitle("A")
    sourceExe := WinGetProcessName("A")
    try FileDelete(CLIP_ANNOTATE_CONTEXT_FILE)
    try FileDelete(CLIP_ANNOTATE_OUTPUT_FILE)
    FileAppend(sourceTitle "`n" sourceExe, CLIP_ANNOTATE_CONTEXT_FILE, "UTF-8")

    A_Clipboard := ""
    Sleep(30)
    Send("^c")
    if !ClipWait(1.5) {
        msg("No pude copiar al clipboard.", { seconds: 4 })
        return false
    }

    Sleep(350)

    cmd := CLIP_AGENT_PYTHON ' "' CLIP_ANNOTATE_COPY_SCRIPT '" --source-context-file "' CLIP_ANNOTATE_CONTEXT_FILE '"'
    fullCmd := 'cmd /c ' cmd ' > "' CLIP_ANNOTATE_OUTPUT_FILE '" 2>&1'
    CopyQ_Log("smart copy: " fullCmd)

    try {
        RunWait(fullCmd, CLIP_AGENT_WORKDIR, "Hide")
    } catch Error as err {
        CopyQ_Log("Error smart copy: " err.Message)
        msg("Copio, pero no pude anotar metadata: " . err.Message, { seconds: 4 })
        return false
    }

    result := FileExist(CLIP_ANNOTATE_OUTPUT_FILE)
        ? Trim(FileRead(CLIP_ANNOTATE_OUTPUT_FILE, "UTF-8"))
        : ""
    try FileDelete(CLIP_ANNOTATE_OUTPUT_FILE)

    if (SubStr(result, 1, 3) = "OK:") {
        if (targetTab = "&clipboard") {
            msg("Copiado con metadata", { seconds: 2 })
            return true
        }

        try FileDelete(CLIP_SEND_TO_PASS_OUTPUT_FILE)
        sendCmd := CLIP_AGENT_PYTHON ' "' CLIP_SEND_TO_PASS_SCRIPT '" --target-tab "' targetTab '"'
        sendFullCmd := 'cmd /c ' sendCmd ' > "' CLIP_SEND_TO_PASS_OUTPUT_FILE '" 2>&1'
        CopyQ_Log("smart copy send: " sendFullCmd)

        try {
            RunWait(sendFullCmd, CLIP_AGENT_WORKDIR, "Hide")
        } catch Error as err {
            CopyQ_Log("Error smart copy send: " err.Message)
            msg("Copie con metadata, pero no pude enviarlo a " . targetTab, { seconds: 4 })
            return false
        }

        sendResult := FileExist(CLIP_SEND_TO_PASS_OUTPUT_FILE)
            ? Trim(FileRead(CLIP_SEND_TO_PASS_OUTPUT_FILE, "UTF-8"))
            : ""
        try FileDelete(CLIP_SEND_TO_PASS_OUTPUT_FILE)

        if (SubStr(sendResult, 1, 3) = "OK:") {
            msg("Copiado con metadata a " . targetTab, { seconds: 2 })
            return true
        }

        msg(sendResult != "" ? sendResult : "Copie con metadata, pero no pude enviarlo a " . targetTab, { seconds: 4 })
        return false
    }

    msg(result != "" ? result : "Copie, pero no pude guardar metadata.", { seconds: 4 })
    return false
}

CopyQ_SendItemToPass() {
    global CLIP_AGENT_PYTHON
    global CLIP_AGENT_WORKDIR
    global CLIP_SEND_TO_PASS_SCRIPT
    global CLIP_SEND_TO_PASS_OUTPUT_FILE

    if (!FileExist(CLIP_SEND_TO_PASS_SCRIPT)) {
        msg("Script no encontrado: " . CLIP_SEND_TO_PASS_SCRIPT, { seconds: 4 })
        return false
    }

    CopyQ_EnsureTempDir()

    try FileDelete(CLIP_SEND_TO_PASS_OUTPUT_FILE)

    cmd := CLIP_AGENT_PYTHON ' "' CLIP_SEND_TO_PASS_SCRIPT '"'
    fullCmd := 'cmd /c ' cmd ' > "' CLIP_SEND_TO_PASS_OUTPUT_FILE '" 2>&1'
    CopyQ_Log("send to pass: " fullCmd)

    try {
        RunWait(fullCmd, CLIP_AGENT_WORKDIR, "Hide")
    } catch Error as err {
        CopyQ_Log("Error send to pass: " err.Message)
        msg("No pude guardar el item en pass: " . err.Message, { seconds: 4 })
        return false
    }

    result := FileExist(CLIP_SEND_TO_PASS_OUTPUT_FILE)
        ? Trim(FileRead(CLIP_SEND_TO_PASS_OUTPUT_FILE, "UTF-8"))
        : ""
    try FileDelete(CLIP_SEND_TO_PASS_OUTPUT_FILE)

    if (SubStr(result, 1, 3) = "OK:") {
        msg("Item actual guardado en pass", { seconds: 2 })
        return true
    }

    msg(result != "" ? result : "No pude guardar el item actual en pass.", { seconds: 4 })
    return false
}

CopyQ_ExportSelectedImages() {
    global COPYQ_EXPORT_SELECTED_IMAGES_SHORTCUT

    if !WinExist("ahk_exe copyq.exe") {
        msg("Abrí CopyQ y seleccioná las imágenes primero.", { seconds: 4 })
        return false
    }

    WinActivate("ahk_exe copyq.exe")
    if !WinWaitActive("ahk_exe copyq.exe", , 2) {
        msg("No pude activar CopyQ.", { seconds: 4 })
        return false
    }

    Send(COPYQ_EXPORT_SELECTED_IMAGES_SHORTCUT)
    return true
}

; ===================================================================
; Hotkeys
; ===================================================================

#Space:: {
    RunClipboardAgent()
}

#+c:: {
    OpenCopyQSaveWindow()
}

#!l:: {
    CopyQ_LabelSelectedItem()
}

#HotIf WinActive("ahk_exe copyq.exe")
!Enter:: {
    CopyQ_ConfirmSearchSelection()
}
#HotIf
