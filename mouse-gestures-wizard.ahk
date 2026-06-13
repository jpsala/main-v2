MouseGestureQuickCreateStubWizard() {
    defaults := MouseGestureQuickGetStubDefaults()

    formResult := MouseGestureQuickCollectWizardData(defaults)
    if (!formResult.ok)
        return

    formData := formResult.data
    contextConfig := MouseGestureQuickResolveContextChoice(formData.contextChoice, formData.exe)

    trigger := MouseGestureQuickBuildTrigger(formData.triggerKind, formData.triggerValue)
    if (!trigger.ok) {
        MouseGestureQuickNotify("Gesture stub: trigger invalido", 2.2)
        return
    }

    screenCellSpec := MouseGestureQuickBuildScreenCellSpec(formData.areaSpec)
    if (!screenCellSpec.ok) {
        MouseGestureQuickNotify("Gesture stub: celda o grid invalidos", 2.2)
        return
    }

    stub := MouseGestureQuickBuildStub({
        targetFunction: contextConfig.targetFunction,
        button: formData.button,
        trigger: trigger,
        exe: contextConfig.exe,
        titleRegex: formData.titleRegex,
        size: MouseGestureQuickNormalizeSizeChoice(formData.size),
        screenCellSpec: screenCellSpec,
        label: formData.label,
        sendKeys: formData.sendKeys
    })

    A_Clipboard := stub.text
    insertResult := MouseGestureQuickInsertStub(stub)
    if (insertResult.ok)
        MouseGestureQuickOpenTargetFunction(contextConfig.targetFunction, insertResult.lineNumber)
    else
        MouseGestureQuickOpenTargetFunction(contextConfig.targetFunction)

    message := insertResult.ok
        ? "Gesture stub copiado e insertado en " . contextConfig.targetFunction
        : "Gesture stub copiado | no pude insertarlo automatico"
    MouseGestureQuickNotify(message, 3)
}

MouseGestureQuickNotify(text, seconds := 2.2) {
    try {
        notifyFn := Func("msg")
        notifyFn.Call(text, {seconds: seconds})
    } catch {
    }
}

MouseGestureQuickCollectWizardData(defaults) {
    state := {ok: false, data: 0}
    wizardGui := Gui("+AlwaysOnTop +OwnDialogs", "Gesture Stub")
    wizardGui.MarginX := 12
    wizardGui.MarginY := 10

    wizardGui.Add("Text", "xm w430", "Programa / contexto")
    contextDDL := wizardGui.Add("DropDownList", "xm w430 y+4", MouseGestureQuickGetContextOptions())

    wizardGui.Add("Text", "xm y+10 w430", "Exe opcional. Requerido si elegis Other exe. Para cualquier app usa Global (all).")
    exeEdit := wizardGui.Add("Edit", "xm w430 y+4", defaults.exe)

    wizardGui.Add("Text", "xm y+10 w430", "Boton")
    buttonDDL := wizardGui.Add("DropDownList", "xm w430 y+4", ["RButton", "MButton"])

    wizardGui.Add("Text", "xm y+10 w430", "Tipo")
    triggerKindDDL := wizardGui.Add("DropDownList", "xm w430 y+4", ["gesture", "shape"])

    wizardGui.Add("Text", "xm y+10 w430", "Gesture o shape")
    triggerValueEdit := wizardGui.Add("Edit", "xm w430 y+4", defaults.triggerValue)

    wizardGui.Add("Text", "xm y+10 w430", "Size opcional")
    sizeDDL := wizardGui.Add("DropDownList", "xm w430 y+4", ["(none)", "small", "medium", "large"])

    wizardGui.Add("Text", "xm y+10 w430", "Area opcional: fila,columna|fila,columna@filasxcolumnas")
    areaEdit := wizardGui.Add("Edit", "xm w430 y+4", defaults.areaSpec)

    wizardGui.Add("Text", "xm y+10 w430", "Title regex opcional")
    titleEdit := wizardGui.Add("Edit", "xm w430 y+4", defaults.titleRegex)

    wizardGui.Add("Text", "xm y+10 w430", "Label")
    labelEdit := wizardGui.Add("Edit", "xm w430 y+4", defaults.label)

    wizardGui.Add("Text", "xm y+10 w430", "Send keys opcional")
    sendKeysEdit := wizardGui.Add("Edit", "xm w430 y+4", defaults.sendKeys)

    okButton := wizardGui.Add("Button", "xm y+14 w90 Default", "OK")
    cancelButton := wizardGui.Add("Button", "x+8 yp w90", "Cancel")

    MouseGestureQuickSetChoiceValue(contextDDL, MouseGestureQuickGetContextOptions(), defaults.contextChoice)
    MouseGestureQuickSetChoiceValue(buttonDDL, ["RButton", "MButton"], defaults.button)
    MouseGestureQuickSetChoiceValue(triggerKindDDL, ["gesture", "shape"], defaults.triggerKind)
    MouseGestureQuickSetChoiceValue(sizeDDL, ["(none)", "small", "medium", "large"], defaults.size)

    okButton.OnEvent("Click", (*) => MouseGestureQuickSubmitWizard(
        wizardGui,
        state,
        contextDDL.Text,
        exeEdit.Value,
        buttonDDL.Text,
        triggerKindDDL.Text,
        triggerValueEdit.Value,
        sizeDDL.Text,
        areaEdit.Value,
        titleEdit.Value,
        labelEdit.Value,
        sendKeysEdit.Value
    ))
    cancelButton.OnEvent("Click", (*) => MouseGestureQuickCancelWizard(wizardGui, state))
    wizardGui.OnEvent("Escape", (*) => MouseGestureQuickCancelWizard(wizardGui, state))
    wizardGui.OnEvent("Close", (*) => MouseGestureQuickCancelWizard(wizardGui, state))

    hwnd := wizardGui.Hwnd
    wizardGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " . hwnd)

    return state
}

MouseGestureQuickSetChoiceValue(control, options, value) {
    choiceIndex := MouseGestureQuickFindOptionIndex(options, value)
    if (choiceIndex > 0)
        control.Choose(choiceIndex)
    else
        control.Choose(1)
}

MouseGestureQuickSubmitWizard(guiObj, state, contextChoice, exeValue, button, triggerKind, triggerValue, sizeValue, areaSpec, titleRegex, label, sendKeys) {
    formData := {
        contextChoice: Trim(contextChoice),
        exe: Trim(exeValue),
        button: Trim(button),
        triggerKind: Trim(triggerKind),
        triggerValue: Trim(triggerValue),
        size: Trim(sizeValue),
        areaSpec: Trim(areaSpec),
        titleRegex: Trim(titleRegex),
        label: Trim(label),
        sendKeys: Trim(sendKeys)
    }

    validation := MouseGestureQuickValidateFormData(formData)
    if (!validation.ok) {
        MouseGestureQuickNotify(validation.message, 3.2)
        return
    }

    state.ok := true
    state.data := formData
    guiObj.Destroy()
}

MouseGestureQuickValidateFormData(formData) {
    trigger := MouseGestureQuickBuildTrigger(formData.triggerKind, formData.triggerValue)
    if (!trigger.ok)
        return {ok: false, message: "Gesture stub: trigger invalido"}

    screenCellSpec := MouseGestureQuickBuildScreenCellSpec(formData.areaSpec)
    if (!screenCellSpec.ok)
        return {ok: false, message: "Gesture stub: celda o grid invalidos"}

    return {ok: true}
}

MouseGestureQuickCancelWizard(guiObj, state) {
    state.ok := false
    state.data := 0
    guiObj.Destroy()
}

MouseGestureQuickGetStubDefaults() {
    return {
        contextChoice: "Global (all)",
        button: "RButton",
        triggerKind: "gesture",
        triggerValue: "",
        exe: "",
        titleRegex: "",
        size: "(none)",
        areaSpec: "",
        label: "",
        sendKeys: ""
    }
}

MouseGestureQuickPromptChoice(prompt, title, options, defaultValue := "") {
    state := {ok: false, value: ""}
    promptGui := Gui("+AlwaysOnTop +OwnDialogs", title)
    promptGui.MarginX := 12
    promptGui.MarginY := 12
    promptGui.Add("Text", "w430", prompt)
    ddl := promptGui.Add("DropDownList", "w430 y+8", options)
    okButton := promptGui.Add("Button", "xm y+12 w90 Default", "OK")
    cancelButton := promptGui.Add("Button", "x+8 yp w90", "Cancel")

    choiceIndex := MouseGestureQuickFindOptionIndex(options, defaultValue)
    if (choiceIndex > 0)
        ddl.Choose(choiceIndex)
    else
        ddl.Choose(1)

    okButton.OnEvent("Click", (*) => MouseGestureQuickCloseChoicePrompt(promptGui, state, true, ddl.Text))
    cancelButton.OnEvent("Click", (*) => MouseGestureQuickCloseChoicePrompt(promptGui, state, false, ""))
    promptGui.OnEvent("Escape", (*) => MouseGestureQuickCloseChoicePrompt(promptGui, state, false, ""))
    promptGui.OnEvent("Close", (*) => MouseGestureQuickCloseChoicePrompt(promptGui, state, false, ""))

    hwnd := promptGui.Hwnd
    promptGui.Show("AutoSize Center")
    WinWaitClose("ahk_id " . hwnd)
    MouseGestureQuickWaitForPromptInputRelease()

    return {
        ok: state.ok,
        value: Trim(state.value)
    }
}

MouseGestureQuickCloseChoicePrompt(gui, state, ok, value) {
    state.ok := ok
    state.value := value
    gui.Destroy()
}

MouseGestureQuickWaitForPromptInputRelease() {
    KeyWait("Enter")
    KeyWait("NumpadEnter")
    KeyWait("LButton")
}

MouseGestureQuickFindOptionIndex(options, targetValue) {
    if (targetValue = "")
        return 0

    for index, option in options {
        if (option = targetValue)
            return index
    }
    return 0
}

MouseGestureQuickPromptField(prompt, title, defaultValue := "") {
    result := InputBox(prompt, title, "w520 h160", defaultValue)
    MouseGestureQuickWaitForPromptInputRelease()
    return {
        ok: result.Result = "OK",
        value: Trim(result.Value)
    }
}

MouseGestureQuickInferTargetFunction(exeName) {
    if (exeName = "OpenCode.exe")
        return "HandleOpenCodeGestures"
    if (exeName = "Code.exe")
        return "HandleCodeGestures"
    if (exeName = "chrome.exe")
        return "HandleChromeGestures"
    return "HandleGlobalGestures"
}

MouseGestureQuickGetContextOptions() {
    return [
        "Global (all)",
        "Code.exe",
        "chrome.exe",
        "OpenCode.exe",
        "Other exe (global block)"
    ]
}

MouseGestureQuickInferContextChoice(exeName) {
    if (exeName = "OpenCode.exe")
        return "OpenCode.exe"
    if (exeName = "Code.exe")
        return "Code.exe"
    if (exeName = "chrome.exe")
        return "chrome.exe"
    if (exeName != "")
        return "Other exe (global block)"
    return "Global (all)"
}

MouseGestureQuickResolveContextChoice(contextChoice, customExe := "") {
    exeValue := Trim(customExe)

    switch contextChoice {
        case "Global (all)":
            return {ok: true, targetFunction: "HandleGlobalGestures", exe: ""}
        case "Code.exe":
            return {ok: true, targetFunction: "HandleCodeGestures", exe: "Code.exe"}
        case "chrome.exe":
            return {ok: true, targetFunction: "HandleChromeGestures", exe: "chrome.exe"}
        case "OpenCode.exe":
            return {ok: true, targetFunction: "HandleOpenCodeGestures", exe: "OpenCode.exe"}
        case "Other exe (global block)":
            return {ok: true, targetFunction: "HandleGlobalGestures", exe: exeValue}
    }

    return {ok: false, targetFunction: "HandleGlobalGestures", exe: ""}
}

MouseGestureQuickBuildTrigger(triggerKind, triggerValue) {
    value := Trim(triggerValue)
    if (value = "")
        return {ok: false}

    return {
        ok: triggerKind = "gesture" || triggerKind = "shape",
        kind: triggerKind,
        value: value
    }
}

MouseGestureQuickNormalizeSizeChoice(sizeChoice) {
    return sizeChoice = "(none)" ? "" : sizeChoice
}

MouseGestureQuickBuildScreenCellSpec(areaValue) {
    global mouseGestureConfig

    areaText := Trim(areaValue)
    if (areaText = "") {
        return {
            ok: true,
            enabled: false,
            cells: [],
            rows: mouseGestureConfig.screenGridRows,
            cols: mouseGestureConfig.screenGridCols
        }
    }

    parts := StrSplit(areaText, "@")
    if (parts.Length > 2)
        return {ok: false}

    cellListText := Trim(parts[1])
    if (cellListText = "")
        return {ok: false}

    if (parts.Length = 2) {
        gridText := Trim(parts[2])
        if !RegExMatch(gridText, "^(\d+)\s*x\s*(\d+)$", &gridMatch)
            return {ok: false}
        rows := gridMatch[1] + 0
        cols := gridMatch[2] + 0
    } else {
        rows := mouseGestureConfig.screenGridRows
        cols := mouseGestureConfig.screenGridCols
    }

    if (rows <= 0 || cols <= 0)
        return {ok: false}

    cells := []
    seen := Map()
    for _, rawCell in StrSplit(cellListText, "|") {
        cellText := Trim(rawCell)
        if !RegExMatch(cellText, "^(\d+)\s*,\s*(\d+)$", &cellMatch)
            return {ok: false}
        row := cellMatch[1] + 0
        col := cellMatch[2] + 0
        if (row <= 0 || col <= 0)
            return {ok: false}
        if (row > rows || col > cols)
            return {ok: false}

        cellKey := row . "," . col
        if (seen.Has(cellKey))
            continue
        seen[cellKey] := true
        cells.Push(cellKey)
    }

    if (cells.Length = 0)
        return {ok: false}

    return {
        ok: true,
        enabled: true,
        cells: cells,
        rows: rows,
        cols: cols
    }
}

MouseGestureQuickBuildStub(params) {
    resolvedExe := MouseGestureQuickResolveExe(params.targetFunction, params.exe)
    label := params.label != "" ? params.label : "TODO label"
    outerIndent := "    "
    innerIndent := "        "
    commentPrefix := outerIndent . Chr(59) . " "
    innerCommentPrefix := innerIndent . Chr(59) . " "

    conditions := []
    conditions.Push("event.triggerButton = " . MouseGestureQuickQuote(params.button))
    if (params.trigger.kind = "gesture")
        conditions.Push("event.gesture = " . MouseGestureQuickQuote(params.trigger.value))
    else
        conditions.Push("event.shapeName = " . MouseGestureQuickQuote(params.trigger.value))
    if (resolvedExe != "")
        conditions.Push("event.window.exe = " . MouseGestureQuickQuote(resolvedExe))
    if (params.titleRegex != "")
        conditions.Push("RegExMatch(event.window.title, " . MouseGestureQuickQuote(params.titleRegex) . ")")
    if (params.size != "")
        conditions.Push("event.sizeBucket = " . MouseGestureQuickQuote(params.size))
    if (params.screenCellSpec.enabled) {
        cellArgs := []
        for _, cell in params.screenCellSpec.cells
            cellArgs.Push(MouseGestureQuickQuote(cell))
        conditions.Push(
            "MouseGestureEventMatchesAnyCell(event, "
            . params.screenCellSpec.rows . ", "
            . params.screenCellSpec.cols . ", "
            . MouseGestureQuickJoin(cellArgs, ", ") . ")"
        )
    }

    lines := []
    lines.Push(commentPrefix . label)
    lines.Push(outerIndent . "if (" . MouseGestureQuickJoin(conditions, " && ") . ") {")
    if (params.sendKeys != "") {
        lines.Push(innerIndent . "MouseGestureQuickSend(event, " . MouseGestureQuickQuote(params.sendKeys) . ", " . MouseGestureQuickQuote(label) . ")")
        lines.Push(innerIndent . "return true")
    } else {
        sampleSend := innerCommentPrefix . "MouseGestureQuickSend(event, " . MouseGestureQuickQuote("^w") . ", " . MouseGestureQuickQuote(label) . ")"
        sampleRoa := innerCommentPrefix . "SetTimer(() => Roa(" . MouseGestureQuickQuote("app-alias") . ", " . MouseGestureQuickQuote("app.exe") . "), -30)"
        sampleHandled := innerCommentPrefix . "MouseGestureQuickHandled(event, " . MouseGestureQuickQuote(label) . ")"
        lines.Push(innerCommentPrefix . "TODO: add action")
        lines.Push(sampleSend)
        lines.Push(sampleRoa)
        lines.Push(sampleHandled)
        lines.Push(innerCommentPrefix . "return true")
    }
    lines.Push(outerIndent . "}")

    codeLines := []
    index := 1
    while (index <= lines.Length) {
        codeLines.Push(lines[index])
        index += 1
    }

    return {
        text: MouseGestureQuickJoin(lines, "`r`n"),
        codeText: MouseGestureQuickJoin(codeLines, "`r`n"),
        targetFunction: params.targetFunction,
        specificity: MouseGestureQuickBuildSpecificity(params)
    }
}

MouseGestureQuickBuildSpecificity(params) {
    score := 0

    score += params.trigger.kind = "gesture" ? 40 : 30
    if (params.exe != "")
        score += 30
    if (params.titleRegex != "")
        score += 35
    if (params.size != "")
        score += 15
    if (params.screenCellSpec.enabled)
        score += MouseGestureQuickBuildCellSpecificity(params.screenCellSpec)

    return score
}

MouseGestureQuickBuildCellSpecificity(screenCellSpec) {
    totalCells := screenCellSpec.rows * screenCellSpec.cols
    matchedCells := screenCellSpec.cells.Length
    if (totalCells <= 0 || matchedCells <= 0)
        return 0

    ; More grid cells and fewer matched cells means more specific.
    return 100 + (totalCells * 10) - matchedCells
}

MouseGestureQuickResolveExe(targetFunction, exeValue) {
    if (Trim(exeValue) != "")
        return Trim(exeValue)
    if (targetFunction = "HandleCodeGestures")
        return "Code.exe"
    if (targetFunction = "HandleChromeGestures")
        return "chrome.exe"
    if (targetFunction = "HandleOpenCodeGestures")
        return "OpenCode.exe"
    return ""
}

MouseGestureQuickQuote(value) {
    return '"' . StrReplace(value, '"', '""') . '"'
}

MouseGestureQuickJoin(items, separator) {
    result := ""
    for index, item in items {
        if (index > 1)
            result .= separator
        result .= item
    }
    return result
}

MouseGestureQuickGetConditionsFilePath() {
    return A_ScriptDir . "\mouse-gestures-conditions.ahk"
}

MouseGestureQuickOpenTargetFunction(targetFunction, lineNumber := 0) {
    filePath := MouseGestureQuickGetConditionsFilePath()
    if (!lineNumber)
        lineNumber := MouseGestureQuickFindFunctionLine(filePath, targetFunction)
    if (!lineNumber)
        lineNumber := 1

    editorExe := MouseGestureQuickResolveEditorExe()
    if (!editorExe) {
        Run("notepad.exe " . MouseGestureQuickQuote(filePath))
        return false
    }

    Run(QuoteCommandPath(editorExe) . " --goto " . MouseGestureQuickQuote(filePath . ":" . lineNumber))
    return true
}

MouseGestureQuickResolveEditorExe() {
    global cursorExe
    global vscodeExe

    if (cursorExe && FileExist(cursorExe))
        return cursorExe
    if (vscodeExe && FileExist(vscodeExe))
        return vscodeExe
    return ""
}

MouseGestureQuickFindFunctionLine(filePath, functionName) {
    if (!FileExist(filePath))
        return 0

    fileLines := StrSplit(FileRead(filePath, "UTF-8"), "`n", "`r")
    for index, line in fileLines {
        if (InStr(Trim(line), functionName . "(") = 1)
            return index
    }

    return 0
}

MouseGestureQuickInsertStub(stub) {
    filePath := MouseGestureQuickGetConditionsFilePath()
    if (!FileExist(filePath))
        return {ok: false, lineNumber: 0}

    lines := StrSplit(FileRead(filePath, "UTF-8"), "`n", "`r")
    bodyInsertLine := MouseGestureQuickFindBodyInsertLine(lines, stub.targetFunction, stub.specificity)
    if (!bodyInsertLine)
        return {ok: false, lineNumber: 0}

    lines := MouseGestureQuickInsertLines(lines, bodyInsertLine, StrSplit(stub.codeText, "`n", "`r"))

    out := FileOpen(filePath, "w", "UTF-8")
    if (!out)
        return {ok: false, lineNumber: 0}
    out.Write(MouseGestureQuickJoin(lines, "`r`n"))
    out.Close()

    MouseGestureQuickSortConditions(stub.targetFunction)

    return {ok: true, lineNumber: 0}
}

MouseGestureQuickInsertLines(lines, insertAtLine, newLines) {
    result := []

    if (insertAtLine < 1)
        insertAtLine := 1
    if (insertAtLine > lines.Length + 1)
        insertAtLine := lines.Length + 1

    loop insertAtLine - 1
        result.Push(lines[A_Index])

    for _, newLine in newLines
        result.Push(newLine)

    index := insertAtLine
    while (index <= lines.Length) {
        result.Push(lines[index])
        index += 1
    }

    return result
}

MouseGestureQuickFindBodyInsertLine(lines, targetFunction, newSpecificity) {
    startLine := 0
    for index, line in lines {
        if (InStr(Trim(line), targetFunction . "(") = 1) {
            startLine := index
            break
        }
    }
    if (!startLine)
        return 0

    endLine := MouseGestureQuickFindBlockEndLine(lines, startLine)
    if (!endLine)
        return 0

    blockRanges := MouseGestureQuickFindInsertableBlocks(lines, startLine, endLine)
    for _, block in blockRanges {
        if (newSpecificity > block.specificity)
            return block.startLine
    }

    index := endLine - 1
    while (index > startLine) {
        if (Trim(lines[index]) = "return false")
            return index
        index -= 1
    }

    return endLine
}

MouseGestureQuickFindInsertableBlocks(lines, startLine, endLine) {
    blocks := []
    index := startLine + 1

    while (index < endLine) {
        line := lines[index]
        trimmed := Trim(line)
        if (trimmed = "" || SubStr(trimmed, 1, 1) = ";") {
            index += 1
            continue
        }

        if (MouseGestureQuickIsFunctionGuardBlock(lines, index, endLine)) {
            index += 2
            continue
        }

        if (MouseGestureQuickIsTopLevelIfLine(line, trimmed)) {
            blockEndLine := MouseGestureQuickFindBlockEndLine(lines, index)
            if (!blockEndLine || blockEndLine > endLine)
                blockEndLine := index

            blocks.Push({
                startLine: index,
                endLine: blockEndLine,
                specificity: MouseGestureQuickEstimateExistingSpecificity(trimmed)
            })
            index := blockEndLine + 1
            continue
        }

        index += 1
    }

    return blocks
}

MouseGestureQuickRefreshFunctionUsedComments(lines, targetFunction) {
    startLine := MouseGestureQuickFindFunctionStartLine(lines, targetFunction)
    if (!startLine)
        return 0

    endLine := MouseGestureQuickFindBlockEndLine(lines, startLine)
    if (!endLine)
        return 0

    blocks := MouseGestureQuickFindInsertableBlocks(lines, startLine, endLine)
    if (blocks.Length = 0)
        return 0

    guardStartLine := MouseGestureQuickFindFunctionGuardStartLine(lines, startLine, endLine)
    if (guardStartLine)
        regionStart := guardStartLine + 2
    else
        regionStart := startLine + 1

    regionEnd := blocks[1].startLine - 1
    replacementLines := MouseGestureQuickBuildUsedCommentLines(lines, blocks, targetFunction, guardStartLine != 0)
    existingLines := MouseGestureQuickSliceLines(lines, regionStart, regionEnd)
    if (MouseGestureQuickLineArraysEqual(existingLines, replacementLines))
        return 0

    return MouseGestureQuickReplaceLineRange(lines, regionStart, regionEnd, replacementLines)
}

MouseGestureQuickFindFunctionGuardStartLine(lines, startLine, endLine) {
    index := startLine + 1
    while (index <= endLine) {
        trimmed := Trim(lines[index])
        if (trimmed = "") {
            index += 1
            continue
        }

        if (MouseGestureQuickIsFunctionGuardBlock(lines, index, endLine))
            return index
        return 0
    }

    return 0
}

MouseGestureQuickBuildUsedCommentLines(lines, blocks, targetFunction, hasGuard) {
    commentLines := []
    commentPrefix := "    " . Chr(59) . " "
    if (hasGuard) {
        commentLines.Push("")
    }
    commentLines.Push(commentPrefix . "Used:")
    for _, block in blocks
        commentLines.Push(commentPrefix . MouseGestureQuickDescribeBlock(lines, block, targetFunction))
    commentLines.Push("")
    return commentLines
}

MouseGestureQuickDescribeBlock(lines, block, targetFunction) {
    ifLine := Trim(lines[block.startLine])
    conditionText := MouseGestureQuickCompactIfLine(ifLine)
    label := MouseGestureQuickExtractBlockLabel(lines, block)
    if (label = "")
        return conditionText

    return conditionText . " -> " . label
}

MouseGestureQuickCompactIfLine(ifLine) {
    compact := ifLine
    if (InStr(compact, "if (") = 1)
        compact := SubStr(compact, 5)
    compact := Trim(compact)
    if (SubStr(compact, -1) = "{")
        compact := Trim(SubStr(compact, 1, StrLen(compact) - 1))
    if (SubStr(compact, -1) = ")")
        compact := Trim(SubStr(compact, 1, StrLen(compact) - 1))
    return compact
}

MouseGestureQuickExtractBlockLabel(lines, block) {
    previousIndex := block.startLine - 1
    while (previousIndex >= 1) {
        previousTrimmed := Trim(lines[previousIndex])
        if (previousTrimmed = "") {
            previousIndex -= 1
            continue
        }

        if (SubStr(previousTrimmed, 1, 1) = ";") {
            commentText := Trim(SubStr(previousTrimmed, 2))
            if (commentText != "" && commentText != "Used:" && InStr(commentText, "->") = 0)
                return commentText
        }
        break
    }

    index := block.startLine
    while (index <= block.endLine) {
        rawLine := lines[index]
        if (InStr(rawLine, "MouseGestureQuickSend(event,") || InStr(rawLine, "MouseGestureQuickHandled(event,")) {
            quotedParts := StrSplit(rawLine, Chr(34))
            if (quotedParts.Length >= 4 && InStr(rawLine, "MouseGestureQuickSend(event,"))
                return quotedParts[4]
            if (quotedParts.Length >= 2 && InStr(rawLine, "MouseGestureQuickHandled(event,"))
                return quotedParts[2]
        }
        index += 1
    }
    return ""
}

MouseGestureQuickSliceLines(lines, startLine, endLine) {
    result := []
    if (endLine < startLine)
        return result
    index := startLine
    while (index <= endLine) {
        result.Push(lines[index])
        index += 1
    }
    return result
}

MouseGestureQuickLineArraysEqual(leftLines, rightLines) {
    if (leftLines.Length != rightLines.Length)
        return false
    loop leftLines.Length {
        if (leftLines[A_Index] != rightLines[A_Index])
            return false
    }
    return true
}

MouseGestureQuickReplaceLineRange(lines, startLine, endLine, replacementLines) {
    result := []
    loop startLine - 1
        result.Push(lines[A_Index])
    for _, replacementLine in replacementLines
        result.Push(replacementLine)
    index := endLine + 1
    while (index <= lines.Length) {
        result.Push(lines[index])
        index += 1
    }
    return result
}

MouseGestureQuickIsTopLevelIfLine(line, trimmed) {
    return InStr(trimmed, "if (") = 1 && RegExMatch(line, "^\s*if ")
}

MouseGestureQuickIsFunctionGuardBlock(lines, index, endLine) {
    if (index + 1 > endLine)
        return false

    trimmed := Trim(lines[index])
    nextTrimmed := Trim(lines[index + 1])
    if (InStr(trimmed, "if (") != 1)
        return false
    if (nextTrimmed != "return false")
        return false

    return InStr(trimmed, "!=") > 0
}

MouseGestureQuickEstimateExistingSpecificity(trimmedIfLine) {
    score := 0

    if (InStr(trimmedIfLine, 'event.gesture = '))
        score += 40
    if (InStr(trimmedIfLine, 'event.shapeName = '))
        score += 30
    if (InStr(trimmedIfLine, 'event.window.exe = '))
        score += 30
    if (InStr(trimmedIfLine, 'RegExMatch(event.window.title'))
        score += 35
    if (InStr(trimmedIfLine, 'event.sizeBucket = '))
        score += 15
    if (InStr(trimmedIfLine, 'MouseGestureEventMatchesAnyCell('))
        score += MouseGestureQuickEstimateExistingCellSpecificity(trimmedIfLine)

    return score
}

MouseGestureQuickEstimateExistingCellSpecificity(trimmedIfLine) {
    if !RegExMatch(trimmedIfLine, 'MouseGestureEventMatchesAnyCell\(event,\s*(\d+),\s*(\d+),\s*(.+?)\)', &match)
        return 100

    rows := match[1] + 0
    cols := match[2] + 0
    cellArgs := match[3]
    totalCells := rows * cols
    matchedCells := 0
    loop parse cellArgs, ',' {
        part := Trim(A_LoopField)
        if (RegExMatch(part, '^"'))
            matchedCells += 1
    }
    if (totalCells <= 0 || matchedCells <= 0)
        return 100

    return 100 + (totalCells * 10) - matchedCells
}

MouseGestureQuickSortConditions(targetFunction := "") {
    filePath := MouseGestureQuickGetConditionsFilePath()
    if (!FileExist(filePath))
        return false

    lines := StrSplit(FileRead(filePath, "UTF-8"), "`n", "`r")
    targetFunctions := targetFunction != ""
        ? [targetFunction]
        : ["HandleOpenCodeGestures", "HandleCodeGestures", "HandleChromeGestures", "HandleGlobalGestures"]

    changed := false
    for _, currentTarget in targetFunctions {
        sortedLines := MouseGestureQuickSortFunctionBlocks(lines, currentTarget)
        if (Type(sortedLines) = "Array") {
            lines := sortedLines
            changed := true
        }

        refreshedLines := MouseGestureQuickRefreshFunctionUsedComments(lines, currentTarget)
        if (Type(refreshedLines) = "Array") {
            lines := refreshedLines
            changed := true
        }
    }

    if (!changed)
        return true

    out := FileOpen(filePath, "w", "UTF-8")
    if (!out)
        return false
    out.Write(MouseGestureQuickJoin(lines, "`r`n"))
    out.Close()
    return true
}

MouseGestureQuickRefreshUsedComments(targetFunction := "") {
    filePath := MouseGestureQuickGetConditionsFilePath()
    if (!FileExist(filePath))
        return false

    lines := StrSplit(FileRead(filePath, "UTF-8"), "`n", "`r")
    targetFunctions := targetFunction != ""
        ? [targetFunction]
        : ["HandleOpenCodeGestures", "HandleCodeGestures", "HandleChromeGestures", "HandleGlobalGestures"]

    changed := false
    for _, currentTarget in targetFunctions {
        refreshedLines := MouseGestureQuickRefreshFunctionUsedComments(lines, currentTarget)
        if (Type(refreshedLines) = "Array") {
            lines := refreshedLines
            changed := true
        }
    }

    if (!changed)
        return true

    out := FileOpen(filePath, "w", "UTF-8")
    if (!out)
        return false
    out.Write(MouseGestureQuickJoin(lines, "`r`n"))
    out.Close()
    return true
}

MouseGestureQuickSortFunctionBlocks(lines, targetFunction) {
    startLine := MouseGestureQuickFindFunctionStartLine(lines, targetFunction)
    if (!startLine)
        return 0

    endLine := MouseGestureQuickFindBlockEndLine(lines, startLine)
    if (!endLine)
        return 0

    blocks := MouseGestureQuickFindInsertableBlocks(lines, startLine, endLine)
    if (blocks.Length <= 1)
        return 0

    sortedBlocks := []
    for _, block in blocks
        sortedBlocks.Push(block)

    MouseGestureQuickSortBlockListBySpecificity(sortedBlocks)

    unchanged := true
    loop blocks.Length {
        if (blocks[A_Index].startLine != sortedBlocks[A_Index].startLine) {
            unchanged := false
            break
        }
    }
    if (unchanged)
        return 0

    regionStart := blocks[1].startLine
    regionEnd := blocks[blocks.Length].endLine
    rebuiltRegion := []
    loop regionStart - 1
        rebuiltRegion.Push(lines[A_Index])

    for index, block in sortedBlocks {
        lineIndex := block.startLine
        while (lineIndex <= block.endLine) {
            rebuiltRegion.Push(lines[lineIndex])
            lineIndex += 1
        }
        if (index < sortedBlocks.Length)
            rebuiltRegion.Push("")
    }

    lineIndex := regionEnd + 1
    while (lineIndex <= lines.Length) {
        rebuiltRegion.Push(lines[lineIndex])
        lineIndex += 1
    }

    return rebuiltRegion
}

MouseGestureQuickSortBlockListBySpecificity(blocks) {
    if (blocks.Length <= 1)
        return

    loop blocks.Length - 1 {
        swapped := false
        loop blocks.Length - A_Index {
            leftIndex := A_Index
            rightIndex := A_Index + 1
            leftBlock := blocks[leftIndex]
            rightBlock := blocks[rightIndex]
            if (rightBlock.specificity > leftBlock.specificity) {
                blocks[leftIndex] := rightBlock
                blocks[rightIndex] := leftBlock
                swapped := true
            }
        }
        if (!swapped)
            break
    }
}

MouseGestureQuickFindFunctionStartLine(lines, targetFunction) {
    for index, line in lines {
        if (InStr(Trim(line), targetFunction . "(") = 1)
            return index
    }
    return 0
}

MouseGestureQuickFindBlockEndLine(lines, startLine) {
    depth := 0
    foundOpen := false

    index := startLine
    while (index <= lines.Length) {
        line := lines[index]
        loop parse line {
            if (A_LoopField = "{") {
                depth += 1
                foundOpen := true
            } else if (A_LoopField = "}") {
                depth -= 1
                if (foundOpen && depth = 0)
                    return index
            }
        }
        index += 1
    }

    return 0
}

RegisterMouseGestureQuickShapes() {
    MouseGestureRegisterShape("C", ["L_D_R"])
    MouseGestureRegisterShape("square", ["U_R_D_L", "L_D_R_U", "R_D_L_U", "D_R_U_L", "L_D_R_U_L", "R_D_L_U_R", "D_L_U_R_D", "D_R_U_L_D", "R_U_L_D_R", "U_L_D_R_U"])
    MouseGestureRegisterShape("hook", ["U_R", "R_D", "L_D", "D_L"])
}


