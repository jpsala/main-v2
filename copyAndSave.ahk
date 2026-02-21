; Initialize copyAndSave state
copyAndSaveMode := false
copyAndSaveIndicatorGui := false
global copyAndSaveMode := false
global copyAndSaveIndicatorGui := false
global copyAndSaveQueue := [], copyAndSaveQueueCurrentIndex := 1

addToCopyAndSaveQueue(item) {
    global copyAndSaveMode, copyAndSaveQueue
    copyAndSaveQueue.Push(item)
}


clearCopyAndSaveQueue() {
    global copyAndSaveQueue, copyAndSaveQueueCurrentIndex
    copyAndSaveQueueCurrentIndex := 1
    copyAndSaveQueue := []
    msg('Copy and Save queue cleared')

    soundHigh()
}

copyCurrentItemToClipboardAndIncrementThePointer() {
    global copyAndSaveQueue, copyAndSaveQueueCurrentIndex
    if (copyAndSaveQueue.Length == 0) {
        msgBox("Alt+c=Copia y guarda - Alt+v=Pega y va al siguiente - F1 inicia/fin", "Nada para pegar")
        return false
    }
    ; aa bb cc dd ee ff

    msg('Current item pointer: ' . copyAndSaveQueueCurrentIndex . ' remaining items: ' . copyAndSaveQueue.Length - copyAndSaveQueueCurrentIndex)

    if (copyAndSaveQueueCurrentIndex == copyAndSaveQueue.Length) {
        msg('Last Item')
    }

    A_Clipboard := ''
    A_Clipboard := copyAndSaveQueue[copyAndSaveQueueCurrentIndex]
    if (!ClipWait(0.5)) {
        msg("Failed to copy first item to clipboard")
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
    prev := copyAndSaveMode
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
    currItem := (queueLen >= currPos && currPos > 0) ? copyAndSaveQueue[currPos] : ""
    currItemPreview := SubStr(currItem, 1, 10)
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