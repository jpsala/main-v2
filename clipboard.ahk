#Include 'gdip.ahk'

; Initialize copyAndSave state
copyAndSaveMode := false
copyAndSaveIndicatorGui := false
global copyAndSaveMode := false
global copyAndSaveIndicatorGui := false
global copyAndSaveQueue := [], copyAndSaveQueueCurrentIndex := 1


; ===================================================================
; hotkeys
; ===================================================================

!^c:: {
    toggleCopyAndSave()
}

#hotif copyAndSaveMode == 1

    ^l:: {
        logCopyAndSaveQueue()
    }
    ^x:: {
        clearCopyAndSaveQueue()
    }
    !c:: {
        KeyWait('alt')
        sleep(10)
        if (WinActive('ahk_exe obsidian.exe')) {
            for (n in [1, 2, 3]) {
                send('^a')
                sleep(20)
                ctrlC()
                send('{tab}')
                sleep(50)
            }
            send('{tab}')
        } else {
            ctrlC()
        }
    }

    !r:: {
        clearCopyAndSaveQueue()
    }
    ; !v:: {
    ;     KeyWait('alt')
    ;     if (WinActive('ahk_exe StrategyQuantX_nocheck.exe')) {
    ;         for (n in [1, 2, 3]) {
    ;             copyCurrentItemToClipboardAndIncrementThePointer()
    ;             send('^a')
    ;             sleep(20)
    ;             send('^v')
    ;             sleep(2)
    ;             send('{tab}')
    ;         }
    ;     } else {
    ;         copyCurrentItemToClipboardAndIncrementThePointer()
    ;         send('^v')
    ;     }
    ; }   
#hotif

OnClipboardChange(ClipChanged)

ClipChanged(Type) {
    addToCopyAndSaveQueue(A_Clipboard)
}

addToCopyAndSaveQueue(item, type := "text") {
    global copyAndSaveMode, copyAndSaveQueue
    ; Store as an object with type and value
    copyAndSaveQueue.Push({ type: type, value: item })
}

logCopyAndSaveQueue() {
    global copyAndSaveQueue
    log('Copy and Save queue: ' . copyAndSaveQueue.Length)
    for (item in copyAndSaveQueue) {
        log('type: ' . item.type . ', value: ' . item.value)
    }
}

clearCopyAndSaveQueue() {
    global copyAndSaveQueue, copyAndSaveQueueCurrentIndex
    copyAndSaveQueueCurrentIndex := 1
    copyAndSaveQueue := []
    msg('Copy and Save queue cleared')
    emptylog()
    soundHigh()
}

copyCurrentItemToClipboardAndIncrementThePointer() {
    global copyAndSaveQueue, copyAndSaveQueueCurrentIndex
    if (copyAndSaveQueue.Length == 0) {
        msgBox("Alt+c=Copia y guarda - Alt+v=Pega y va al siguiente - F1 inicia/fin", "Nada para pegar")
        return false
    }

    msg('Current item pointer: ' . copyAndSaveQueueCurrentIndex . ' remaining items: ' . copyAndSaveQueue.Length - copyAndSaveQueueCurrentIndex)

    if (copyAndSaveQueueCurrentIndex == copyAndSaveQueue.Length) {
        msg('Last Item')
    }

    itemObj := copyAndSaveQueue[copyAndSaveQueueCurrentIndex]
    if (itemObj.type = "text") {
        A_Clipboard := ''
        A_Clipboard := itemObj.value
        if (!ClipWait(0.5)) {
            msg("Failed to copy text item to clipboard")
            return false
        }
    } else if (itemObj.type = "image") {
        if (!setImageFileToClipboard(itemObj.value)) {
            msg("Failed to copy image item to clipboard")
            return false
        }
    } else {
        msg("Unknown item type in queue: " . itemObj.type)
        return false
    }

    copyAndSaveQueueCurrentIndex += 1
    if (copyAndSaveQueueCurrentIndex > copyAndSaveQueue.Length) {
        copyAndSaveQueueCurrentIndex := 1
        msg("copyAndSaveQueueCurrentIndex reset to 1")
        soundHigh()
    }

    return true
}

setImageFileToClipboard(imagePath) {
    if !FileExist(imagePath) {
        msg("Image file does not exist: " . imagePath)
        return false
    }
    if !pToken := Gdip_Startup() {
        msg("Failed to initialize GDI+.")
        return false
    }
    pBitmap := Gdip_CreateBitmapFromFile(imagePath)
    if !pBitmap {
        msg("Failed to load image: " . imagePath)
        Gdip_Shutdown(pToken)
        return false
    }
    Gdip_SetBitmapToClipboard(pBitmap)
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)
    return true
}

;===============================================================================
; COPY AND SAVE FUNCTIONALITY
;===============================================================================


/**
 * Toggles copyAndSave mode ON/OFF
 * When ON: clears queue, shows indicator
 * When OFF: hides indicator
 */
toggleCopyAndSave() {
    global copyAndSaveMode, copyAndSaveQueue, copyAndSaveIndicatorGui
    copyAndSaveMode := !copyAndSaveMode
    if (copyAndSaveMode) {
        copyAndSaveQueue := []
        showCopyAndSaveIndicator()
    } else {
        hideCopyAndSaveIndicator()
    }
}

/**
 * Shows a checkmark at the top left of the screen
 */
showCopyAndSaveIndicator() {
    global copyAndSaveIndicatorGui, copyAndSaveQueue, copyAndSaveQueueCurrentIndex
    try {
        if (copyAndSaveIndicatorGui) {
            copyAndSaveIndicatorGui.Destroy()
        }
        copyAndSaveIndicatorGui := Gui(, "copyAndSaveIndicator")
        copyAndSaveIndicatorGui.Opt("-Caption +AlwaysOnTop +ToolWindow +E0x20") ; E0x20 = WS_EX_TRANSPARENT
        copyAndSaveIndicatorGui.BackColor := "0x010101" ; Use a color for transparency key
        ; Add a smaller checkmark with a smaller font
        copyAndSaveIndicatorGui.SetFont("s18 bold", "Segoe UI Emoji")
        copyAndSaveIndicatorGui.Add("Text", "x0 y0 w30 h30 cGreen Center BackgroundTrans vCheckMarkText", "✔️")

        ; Add info text (will be updated by timer)
        copyAndSaveIndicatorGui.SetFont("s10", "Segoe UI")
        copyAndSaveIndicatorGui.Add("Text", "x35 y10 w380 h40 cWhite BackgroundTrans vQueueInfoText", "")

        copyAndSaveIndicatorGui.Show("x0 y0 w530 h40 NoActivate")
        ; Make the background transparent
        WinSetTransColor("0x010101", copyAndSaveIndicatorGui.Hwnd)
        ; Initial update
        updateCopyAndSaveIndicatorText()
    } catch Error as e {
        msg("Error showing copyAndSave indicator: " e.Message)
    }
}

hideCopyAndSaveIndicator() {
    global copyAndSaveIndicatorGui
    try {
        if (copyAndSaveIndicatorGui) {
            copyAndSaveIndicatorGui.Destroy()
            copyAndSaveIndicatorGui := false
        }
    } catch Error as e {
        msg("Error hiding copyAndSave indicator: " e.Message)
    }
}

updateCopyAndSaveIndicatorText() {
    global copyAndSaveIndicatorGui, copyAndSaveQueue, copyAndSaveQueueCurrentIndex
    if (!copyAndSaveIndicatorGui) {
        return
    }
    queueLen := copyAndSaveQueue.Length
    currPos := copyAndSaveQueueCurrentIndex
    currItemObj := (queueLen >= currPos && currPos > 0) ? copyAndSaveQueue[currPos] : ""
    if (IsObject(currItemObj)) {
        if (currItemObj.type = "text") {
            currItemPreview := SubStr(currItemObj.value, 1, 10)
        } else if (currItemObj.type = "image") {
            ; Show filename or [image]
            currItemPreview := "[image] " . (currItemObj.value ? SubStr(currItemObj.value, -20) : "")
        } else {
            currItemPreview := "[unknown]"
        }
    } else {
        currItemPreview := ""
    }
    infoText := "Copiados: " queueLen "  Actual: " (!currItemPreview ? "No" : currPos) " Siguiente: " (currItemPreview ? currItemPreview . '...' : "Vacio")
    try {
        copyAndSaveIndicatorGui["QueueInfoText"].Text := infoText
    } catch Error as e {
        msg("Error updating copyAndSaveIndicator text: " e.Message)
    }
}

updateCopyAndSaveIndicatorTimer() {
    global copyAndSaveMode
    if (copyAndSaveMode) {
        updateCopyAndSaveIndicatorText()
    }
}

SetTimer(updateCopyAndSaveIndicatorTimer, 200)