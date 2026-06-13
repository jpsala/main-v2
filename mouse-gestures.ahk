global mouseGestureConfig := {
    pollMs: 16,
    activateDistancePx: 22,
    stepDistancePx: 14,
    diagonalDominanceRatio: 1.5,
    cardinalTurnThresholdPx: 24,
    longPressMs: 250,
    learnSampleCount: 5,
    screenGridRows: 2,
    screenGridCols: 2,
    learnedShapesFile: A_ScriptDir . "\\mouse-gesture-shapes-learned.txt",
    debateStateFile: A_ScriptDir . "\\gesture-debate-state.ini",
    debateLogFile: A_ScriptDir . "\\gesture-debate-log.txt",
    showTrail: true,
    trailColor: 0xFF8A00,
    trailWidth: 4
}

global mouseGestureState := {
    active: false,
    button: "",
    session: 0
}

global mouseGestureShapeAliases := Map()
global mouseGestureLearning := {
    active: false,
    shapeName: "",
    remaining: 0,
    samples: []
}
global mouseGestureTrail := {
    gui: 0,
    hwnd: 0,
    visible: false,
    left: 0,
    top: 0
}
global mouseGestureDebate := {
    active: false,
    feedback: true,
    sessionId: "",
    lastStateMod: ""
}

InitMouseGestures() {
    MouseGestureLoadLearnedShapes()
    RegisterMouseGestureQuickShapes()
}

MouseGestureLog(message) {
    log("[mouse-gesture] " . message)
}

MouseGestureSendDeferred(keys, delayMs := 60) {
    SetTimer(MouseGestureExecuteSend.Bind(keys), -delayMs)
}

MouseGestureSendSequenceDeferred(firstKeys, pauseMs := 0, secondKeys := "", delayMs := 60) {
    SetTimer(MouseGestureExecuteSendSequence.Bind(firstKeys, pauseMs, secondKeys), -delayMs)
}

MouseGestureExecuteSend(keys) {
    MouseGestureLogSendContext("before-send", keys)
    SendEvent(keys)
    MouseGestureLogSendContext("after-send", keys)
}

MouseGestureExecuteSendSequence(firstKeys, pauseMs := 0, secondKeys := "") {
    MouseGestureLogSendContext("before-seq-1", firstKeys)
    SendEvent(firstKeys)
    MouseGestureLogSendContext("after-seq-1", firstKeys)
    if (pauseMs > 0)
        Sleep(pauseMs)
    if (secondKeys != "") {
        MouseGestureLogSendContext("before-seq-2", secondKeys)
        SendEvent(secondKeys)
        MouseGestureLogSendContext("after-seq-2", secondKeys)
    }
}

MouseGestureLogSendContext(phase, keys) {
    activeId := WinExist("A")
    context := MouseGestureGetWindowContext(activeId)
    MouseGestureLog(
        phase
        . " | keys=" . keys
        . " | activeExe=" . context.exe
        . " | activeTitle=" . MouseGestureSanitizeDebateText(context.title)
        . " | rbutton=" . GetKeyState("RButton", "P")
        . " | alt=" . GetKeyState("Alt", "P")
    )
}

MouseGestureShowRuleFeedback(event, label) {
    text := event.gesture . " - " . label
    if (event.window.exe != "")
        text .= " @ " . event.window.exe
    msg(text, {seconds: 1})
}

MouseGestureRunDeferredWithFeedback(action, event, label, delayMs := 30) {
    SetTimer(MouseGestureExecuteDeferredAction.Bind(action, event, label), -delayMs)
}

MouseGestureExecuteDeferredAction(action, event, label) {
    action.Call(event)
    MouseGestureShowRuleFeedback(event, label)
}

MouseGestureIsCardinalToken(token) {
    return token = "U" || token = "D" || token = "L" || token = "R"
}

MouseGestureIsSupportedGesture(gesture) {
    if (gesture = "")
        return false

    for _, token in StrSplit(gesture, "_") {
        if (!MouseGestureIsCardinalToken(token))
            return false
    }
    return true
}

MouseGestureRefreshDebateState() {
    global mouseGestureConfig
    global mouseGestureDebate

    stateFile := mouseGestureConfig.debateStateFile
    if (!FileExist(stateFile)) {
        mouseGestureDebate.active := false
        mouseGestureDebate.feedback := true
        mouseGestureDebate.sessionId := ""
        mouseGestureDebate.lastStateMod := ""
        return
    }

    currentMod := FileGetTime(stateFile, "M")
    if (mouseGestureDebate.lastStateMod = currentMod)
        return

    mouseGestureDebate.lastStateMod := currentMod
    mouseGestureDebate.active := IniRead(stateFile, "debate", "active", "0") = "1"
    mouseGestureDebate.feedback := IniRead(stateFile, "debate", "feedback", "1") != "0"
    mouseGestureDebate.sessionId := IniRead(stateFile, "debate", "sessionId", "")
    MouseGestureLog("debate-state | active=" . mouseGestureDebate.active . " | feedback=" . mouseGestureDebate.feedback . " | session=" . mouseGestureDebate.sessionId)
}

MouseGestureSanitizeDebateText(value) {
    text := value
    text := StrReplace(text, "|", "/")
    text := StrReplace(text, "`r", " ")
    text := StrReplace(text, "`n", " ")
    return text
}

MouseGestureHandleDebateEvent(event, session) {
    global mouseGestureConfig
    global mouseGestureDebate

    MouseGestureRefreshDebateState()
    if (!mouseGestureDebate.active)
        return false

    historyText := session.directionHistory.Length ? ArrayJoin(session.directionHistory, ",") : ""
    line := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        . " | session=" . mouseGestureDebate.sessionId
        . " | button=" . event.triggerButton
        . " | gesture=" . event.gesture
        . " | shape=" . event.shapeName
        . " | history=" . historyText
        . " | size=" . event.sizeBucket
        . " | len=" . Round(event.lengthPx)
        . " | region=" . event.screenRegion
        . " | cell=" . event.screenCell
        . " | startMonitor=" . event.startMonitor
        . " | endMonitor=" . event.endMonitor
        . " | exe=" . event.window.exe
        . " | title=" . MouseGestureSanitizeDebateText(event.window.title)
    FileAppend(line . "`n", mouseGestureConfig.debateLogFile, "UTF-8")

    MouseGestureLog("debate-capture | " . line)
    if (mouseGestureDebate.feedback) {
        text := "debate " . event.gesture
            . (event.shapeName != "" ? " shape=" . event.shapeName : "")
            . " region=" . event.screenRegion
            . " cell=" . event.screenCell
            . " len=" . Round(event.lengthPx)
        msg(text, {seconds: 0.9})
    }
    return true
}

MouseGestureGetVirtualBounds(&left, &top, &right, &bottom) {
    left := 0
    top := 0
    right := 0
    bottom := 0

    monitorCount := MonitorGetCount()
    if (monitorCount < 1)
        return

    MonitorGet(1, &left, &top, &right, &bottom)
    loop monitorCount - 1 {
        index := A_Index + 1
        MonitorGet(index, &monitorLeft, &monitorTop, &monitorRight, &monitorBottom)
        left := Min(left, monitorLeft)
        top := Min(top, monitorTop)
        right := Max(right, monitorRight)
        bottom := Max(bottom, monitorBottom)
    }
}

MouseGestureEnsureTrailGui() {
    global mouseGestureTrail

    if (mouseGestureTrail.gui)
        return

    MouseGestureGetVirtualBounds(&left, &top, &right, &bottom)
    trailGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +LastFound -DPIScale")
    trailGui.BackColor := "FF00FF"
    trailGui.Show("Hide x" left " y" top " w" (right - left) " h" (bottom - top) " NoActivate")
    WinSetTransColor("FF00FF", trailGui)

    mouseGestureTrail.gui := trailGui
    mouseGestureTrail.hwnd := trailGui.Hwnd
    mouseGestureTrail.left := left
    mouseGestureTrail.top := top
}

MouseGestureShowTrail() {
    global mouseGestureTrail

    MouseGestureEnsureTrailGui()
    if (mouseGestureTrail.visible)
        return

    mouseGestureTrail.gui.Show("NoActivate")
    mouseGestureTrail.visible := true
}

MouseGestureTrailColorRef(rgbColor) {
    red := (rgbColor >> 16) & 0xFF
    green := (rgbColor >> 8) & 0xFF
    blue := rgbColor & 0xFF
    return red | (green << 8) | (blue << 16)
}

MouseGestureDrawTrailSegment(x1, y1, x2, y2) {
    global mouseGestureConfig
    global mouseGestureTrail

    if (!mouseGestureConfig.showTrail)
        return

    MouseGestureShowTrail()
    if (!mouseGestureTrail.hwnd)
        return

    dc := DllCall("GetDC", "Ptr", mouseGestureTrail.hwnd, "Ptr")
    if (!dc)
        return

    pen := DllCall(
        "CreatePen",
        "Int", 0,
        "Int", mouseGestureConfig.trailWidth,
        "UInt", MouseGestureTrailColorRef(mouseGestureConfig.trailColor),
        "Ptr"
    )
    oldPen := DllCall("SelectObject", "Ptr", dc, "Ptr", pen, "Ptr")
    DllCall("MoveToEx", "Ptr", dc, "Int", x1 - mouseGestureTrail.left, "Int", y1 - mouseGestureTrail.top, "Ptr", 0)
    DllCall("LineTo", "Ptr", dc, "Int", x2 - mouseGestureTrail.left, "Int", y2 - mouseGestureTrail.top)
    DllCall("SelectObject", "Ptr", dc, "Ptr", oldPen)
    DllCall("DeleteObject", "Ptr", pen)
    DllCall("ReleaseDC", "Ptr", mouseGestureTrail.hwnd, "Ptr", dc)
}

MouseGestureResetTrail() {
    global mouseGestureTrail

    if (!mouseGestureTrail.gui)
        return

    mouseGestureTrail.gui.Destroy()
    mouseGestureTrail.gui := 0
    mouseGestureTrail.hwnd := 0
    mouseGestureTrail.visible := false
    mouseGestureTrail.left := 0
    mouseGestureTrail.top := 0
}

MouseGestureStartShapeLearning() {
    global mouseGestureLearning
    global mouseGestureConfig

    result := InputBox("Shape name to learn", "Mouse Gesture Learning", "", "")
    if (result.Result != "OK")
        return

    shapeName := Trim(result.Value)
    if (shapeName = "") {
        msg("Mouse gesture learning canceled: empty name", {seconds: 1.5})
        return
    }

    mouseGestureLearning.active := true
    mouseGestureLearning.shapeName := shapeName
    mouseGestureLearning.remaining := mouseGestureConfig.learnSampleCount
    mouseGestureLearning.samples := []

    MouseGestureLog("learn-start | shape=" . shapeName . " | samples=" . mouseGestureLearning.remaining)
    msg("Learn shape " . shapeName . ": draw it " . mouseGestureLearning.remaining . " times", {seconds: 2})
}

MouseGestureLoadLearnedShapes() {
    global mouseGestureConfig

    filePath := mouseGestureConfig.learnedShapesFile
    if (!FileExist(filePath))
        return

    content := FileRead(filePath, "UTF-8")
    if (Trim(content) = "")
        return

    for _, rawLine in StrSplit(content, "`n", "`r") {
        line := Trim(rawLine)
        if (line = "")
            continue

        shapeName := ""
        registered := ""
        parts := StrSplit(line, " | ")
        for _, part in parts {
            if (InStr(part, "shape=") = 1)
                shapeName := SubStr(part, 7)
            else if (InStr(part, "registered=") = 1)
                registered := SubStr(part, 12)
        }

        if (shapeName = "" || registered = "")
            continue

        variants := []
        for _, variant in StrSplit(registered, ",") {
            variant := Trim(variant)
            if (variant != "" && MouseGestureIsSupportedGesture(variant))
                variants.Push(variant)
        }

        if (variants.Length = 0)
            continue

        MouseGestureRegisterShape(shapeName, variants)
        MouseGestureLog("learn-load | shape=" . shapeName . " | registered=" . ArrayJoin(variants, ","))
    }
}

MouseGestureCancelShapeLearning() {
    global mouseGestureLearning

    if (!mouseGestureLearning.active)
        return

    MouseGestureLog("learn-cancel | shape=" . mouseGestureLearning.shapeName)
    mouseGestureLearning.active := false
    mouseGestureLearning.shapeName := ""
    mouseGestureLearning.remaining := 0
    mouseGestureLearning.samples := []
    msg("Mouse gesture learning canceled", {seconds: 1.2})
}

MouseGestureLearnSample(event) {
    global mouseGestureLearning

    sample := {
        gesture: event.gesture,
        shapeName: mouseGestureLearning.shapeName,
        size: event.sizeBucket,
        lengthPx: event.lengthPx,
        button: event.triggerButton,
        exe: event.window.exe,
        region: event.screenRegion,
        cell: event.screenCell
    }
    mouseGestureLearning.samples.Push(sample)
    mouseGestureLearning.remaining -= 1

    MouseGestureLog(
        "learn-sample"
        . " | shape=" . mouseGestureLearning.shapeName
        . " | gesture=" . event.gesture
        . " | size=" . event.sizeBucket
        . " | len=" . event.lengthPx
        . " | remaining=" . mouseGestureLearning.remaining
    )

    if (mouseGestureLearning.remaining > 0) {
        msg(
            "Learn " . mouseGestureLearning.shapeName
            . ": " . mouseGestureLearning.remaining . " left"
            . " | last=" . event.gesture,
            {seconds: 1.2}
        )
        return
    }

    MouseGestureFinishShapeLearning()
}

MouseGestureFinishShapeLearning() {
    global mouseGestureLearning
    global mouseGestureConfig

    shapeName := mouseGestureLearning.shapeName
    samples := mouseGestureLearning.samples
    if (samples.Length = 0) {
        MouseGestureCancelShapeLearning()
        return
    }

    counts := Map()
    for _, sample in samples {
        if (!counts.Has(sample.gesture))
            counts[sample.gesture] := 0
        counts[sample.gesture] += 1
    }

    variantsToRegister := []
    topGesture := ""
    topCount := 0
    summary := []

    for gesture, count in counts {
        if (MouseGestureIsSupportedGesture(gesture))
            summary.Push(gesture . " x" . count)
        if (count > topCount) {
            topCount := count
            topGesture := gesture
        }
        if (count >= 2 && MouseGestureIsSupportedGesture(gesture))
            variantsToRegister.Push(gesture)
    }

    if (variantsToRegister.Length = 0 && topGesture != "" && MouseGestureIsSupportedGesture(topGesture))
        variantsToRegister.Push(topGesture)

    if (variantsToRegister.Length = 0) {
        msg("Learned shape ignored: no cardinal-only variants", {seconds: 1.8})
        mouseGestureLearning.active := false
        mouseGestureLearning.shapeName := ""
        mouseGestureLearning.remaining := 0
        mouseGestureLearning.samples := []
        return
    }

    MouseGestureRegisterShape(shapeName, variantsToRegister)
    MouseGesturePersistLearnedShape(shapeName, variantsToRegister, summary)
    MouseGestureLog(
        "learn-finish"
        . " | shape=" . shapeName
        . " | registered=" . ArrayJoin(variantsToRegister, ",")
        . " | summary=" . ArrayJoin(summary, "; ")
    )

    msg(
        "Learned " . shapeName
        . ": " . ArrayJoin(variantsToRegister, ", "),
        {seconds: 2}
    )

    mouseGestureLearning.active := false
    mouseGestureLearning.shapeName := ""
    mouseGestureLearning.remaining := 0
    mouseGestureLearning.samples := []
}

MouseGesturePersistLearnedShape(shapeName, variantsToRegister, summary) {
    global mouseGestureConfig

    line := A_Now
        . " | shape=" . shapeName
        . " | registered=" . ArrayJoin(variantsToRegister, ",")
        . " | summary=" . ArrayJoin(summary, "; ")
        . "`n"
    FileAppend(line, mouseGestureConfig.learnedShapesFile, "UTF-8")
}

MouseGestureRegisterShape(shapeName, variants) {
    global mouseGestureShapeAliases

    for _, variant in variants {
        mouseGestureShapeAliases[variant] := shapeName
    }
}

MouseGestureClassifyShape(gestureRaw) {
    global mouseGestureShapeAliases

    if (gestureRaw = "")
        return ""
    if (mouseGestureShapeAliases.Has(gestureRaw))
        return mouseGestureShapeAliases[gestureRaw]

    return ""
}

MouseGestureClassifySize(lengthPx) {
    if (lengthPx < 120)
        return "small"
    if (lengthPx < 280)
        return "medium"

    return "large"
}

MouseGestureHandleSpecialCases(button) {
    if (button = "RButton" && mousePosY() < 2) {
        MouseGestureLog("special-case top-edge | button=" . button)
        Send("#!{space}")
        WinWaitActive("ahk_exe Microsoft.CmdPal.UI.exe")
        return true
    }

    return false
}

MouseGestureNotifyInteractionStart(button) {
    try VimNotifyMouseInteraction(button)
}

MouseGestureGetMousePos(&x, &y) {
    coordModeSaved := CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    CoordMode("Mouse", coordModeSaved)
}

MouseGestureNewSession(button) {
    MouseGestureGetMousePos(&startX, &startY)
    MouseGetPos(, , &winId)
    startMonitor := MouseGestureGetMonitorIndex(startX, startY)

    session := {
        button: button,
        startedAt: A_TickCount,
        startX: startX,
        startY: startY,
        lastX: startX,
        lastY: startY,
        endX: startX,
        endY: startY,
        totalDistance: 0,
        becameGesture: false,
        direction: "",
        directionHistory: [],
        segmentAnchorX: startX,
        segmentAnchorY: startY,
        window: MouseGestureGetWindowContext(winId),
        startMonitor: startMonitor,
        endMonitor: startMonitor,
        screenRegion: MouseGestureGetScreenRegion(startX, startY, startMonitor),
        screenCell: MouseGestureGetScreenCell(startX, startY, startMonitor)
    }

    MouseGestureLog(
        "start"
        . " | button=" . session.button
        . " | start=" . session.startX . "," . session.startY
        . " | monitor=" . session.startMonitor
        . " | region=" . session.screenRegion
        . " | cell=" . session.screenCell
        . " | exe=" . session.window.exe
    )

    return session
}

MouseGestureDistance(x1, y1, x2, y2) {
    dx := x2 - x1
    dy := y2 - y1
    return Sqrt(dx * dx + dy * dy)
}

MouseGestureGetWindowContext(winId) {
    context := {
        hwnd: winId,
        exe: "",
        class: "",
        title: ""
    }

    if (!winId)
        return context

    try context.exe := WinGetProcessName(winId)
    try context.class := WinGetClass(winId)
    try context.title := WinGetTitle(winId)

    return context
}

MouseGestureGetMonitorIndex(x, y) {
    loop MonitorGetCount() {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        if (x >= left && x <= right && y >= top && y <= bottom)
            return A_Index
    }

    return 0
}

MouseGestureGetScreenRegion(x, y, monitorIndex) {
    if (!monitorIndex)
        return "unknown"

    MonitorGet(monitorIndex, &left, &top, &right, &bottom)
    width := right - left
    height := bottom - top
    if (width <= 0 || height <= 0)
        return "unknown"

    relX := (x - left) / width
    relY := (y - top) / height

    col := relX < 0.33 ? "left" : relX < 0.66 ? "center" : "right"
    row := relY < 0.33 ? "top" : relY < 0.66 ? "center" : "bottom"

    if (row = "center" && col = "center")
        return "center"
    if (row = "center")
        return col
    if (col = "center")
        return row

    return row . "-" . col
}

MouseGestureGetScreenCell(x, y, monitorIndex, rows := 0, cols := 0) {
    global mouseGestureConfig

    if (!monitorIndex)
        return ""

    if (rows <= 0)
        rows := mouseGestureConfig.screenGridRows
    if (cols <= 0)
        cols := mouseGestureConfig.screenGridCols
    if (rows <= 0 || cols <= 0)
        return ""

    MonitorGet(monitorIndex, &left, &top, &right, &bottom)
    width := right - left
    height := bottom - top
    if (width <= 0 || height <= 0)
        return ""

    relX := x - left
    relY := y - top
    colIndex := Floor(relX * cols / width) + 1
    rowIndex := Floor(relY * rows / height) + 1

    if (colIndex < 1)
        colIndex := 1
    else if (colIndex > cols)
        colIndex := cols

    if (rowIndex < 1)
        rowIndex := 1
    else if (rowIndex > rows)
        rowIndex := rows

    return rowIndex . "," . colIndex
}

MouseGestureEventCellMatches(event, row, col, rows := 0, cols := 0) {
    targetCell := row . "," . col
    return MouseGestureGetScreenCell(event.start.x, event.start.y, event.startMonitor, rows, cols) = targetCell
}

MouseGestureEventMatchesAnyCell(event, rows, cols, cells*) {
    actualCell := MouseGestureGetScreenCell(event.start.x, event.start.y, event.startMonitor, rows, cols)
    for _, cell in cells {
        if (actualCell = cell)
            return true
    }
    return false
}

MouseGestureHandleButtonDown(button) {
    global mouseGestureState
    global mouseGestureConfig

    if (!IsSet(mouseGestureState) || mouseGestureState.active)
        return

    MouseGestureNotifyInteractionStart(button)

    if (MouseGestureHandleSpecialCases(button))
        return

    mouseGestureState.active := true
    mouseGestureState.button := button
    mouseGestureState.session := MouseGestureNewSession(button)
    SetTimer(MouseGesturePoll, mouseGestureConfig.pollMs)
}

MouseGestureHandleButtonUp(button) {
    global mouseGestureState

    if (!IsSet(mouseGestureState) || !mouseGestureState.active || mouseGestureState.button != button)
        return

    SetTimer(MouseGesturePoll, 0)
    MouseGestureFinalizeSession(mouseGestureState.session)
    mouseGestureState.active := false
    mouseGestureState.button := ""
    mouseGestureState.session := 0
}

ATan2(y, x) {
    return DllCall("msvcrt\atan2", "Double", y, "Double", x, "CDECL Double")
}

MouseGestureVectorToDirection(dx, dy) {
    angle := Mod(ATan2(-dy, dx) * 180 / 3.141592653589793 + 360, 360)

    if (angle >= 337.5 || angle < 22.5)
        return "R"
    if (angle < 67.5)
        return "UR"
    if (angle < 112.5)
        return "U"
    if (angle < 157.5)
        return "UL"
    if (angle < 202.5)
        return "L"
    if (angle < 247.5)
        return "DL"
    if (angle < 292.5)
        return "D"

    return "DR"
}

MouseGestureCollapseDirection(dx, dy, direction) {
    global mouseGestureConfig

    if (!MouseGestureIsDiagonal(direction))
        return direction

    absDx := Abs(dx)
    absDy := Abs(dy)
    ratio := mouseGestureConfig.diagonalDominanceRatio

    if (absDy >= absDx * ratio)
        return dy > 0 ? "D" : "U"
    if (absDx >= absDy * ratio)
        return dx > 0 ? "R" : "L"

    return direction
}

MouseGestureShouldAppendDirection(history, direction, dx, dy) {
    global mouseGestureConfig

    if (history.Length = 0)
        return true
    if (history[history.Length] = direction)
        return false

    previous := history[history.Length]
    if (!MouseGestureIsDiagonal(previous) && !MouseGestureIsDiagonal(direction)) {
        if ((previous = "U" || previous = "D") && (direction = "L" || direction = "R") && Abs(dx) < mouseGestureConfig.cardinalTurnThresholdPx)
            return false
        if ((previous = "L" || previous = "R") && (direction = "U" || direction = "D") && Abs(dy) < mouseGestureConfig.cardinalTurnThresholdPx)
            return false
    }

    return true
}

MouseGestureCaptureDirection(session, x1, y1, x2, y2) {
    dx := x2 - x1
    dy := y2 - y1
    direction := MouseGestureVectorToDirection(dx, dy)
    direction := MouseGestureCollapseDirection(dx, dy, direction)
    history := session.directionHistory

    if (MouseGestureShouldAppendDirection(history, direction, dx, dy))
        history.Push(direction)
    else
        return

    session.direction := MouseGestureSimplifyDirectionHistory(history)
    session.segmentAnchorX := x2
    session.segmentAnchorY := y2
    MouseGestureLog(
        "direction"
        . " | button=" . session.button
        . " | dir=" . session.direction
        . " | len=" . Round(session.totalDistance)
        . " | pos=" . x2 . "," . y2
    )
}

MouseGestureIsDiagonal(direction) {
    return direction = "UL" || direction = "UR" || direction = "DL" || direction = "DR"
}

MouseGestureDirectionHasComponent(direction, component) {
    return InStr(direction, component) > 0
}

MouseGestureIsHorizontal(direction) {
    return direction = "L" || direction = "R"
}

MouseGestureIsVertical(direction) {
    return direction = "U" || direction = "D"
}

MouseGestureDiagonalVerticalComponent(direction) {
    if (MouseGestureDirectionHasComponent(direction, "U"))
        return "U"
    if (MouseGestureDirectionHasComponent(direction, "D"))
        return "D"
    return ""
}

MouseGestureDiagonalHorizontalComponent(direction) {
    if (MouseGestureDirectionHasComponent(direction, "L"))
        return "L"
    if (MouseGestureDirectionHasComponent(direction, "R"))
        return "R"
    return ""
}

MouseGesturePushCanonicalDirection(result, direction) {
    if (direction = "")
        return
    if (result.Length && result[result.Length] = direction)
        return
    result.Push(direction)
}

MouseGestureCanonicalizeDirectionHistory(history) {
    canonical := []

    for index, current in history {
        prev := canonical.Length ? canonical[canonical.Length] : ""
        next := index < history.Length ? history[index + 1] : ""

        if (!MouseGestureIsDiagonal(current)) {
            MouseGesturePushCanonicalDirection(canonical, current)
            continue
        }

        vertical := MouseGestureDiagonalVerticalComponent(current)
        horizontal := MouseGestureDiagonalHorizontalComponent(current)

        if (prev != "" && next != "") {
            if (MouseGestureIsHorizontal(prev) && MouseGestureIsHorizontal(next) && prev != next) {
                MouseGesturePushCanonicalDirection(canonical, vertical)
                continue
            }
            if (MouseGestureIsVertical(prev) && MouseGestureIsVertical(next) && prev != next) {
                MouseGesturePushCanonicalDirection(canonical, horizontal)
                continue
            }
            if (MouseGestureIsHorizontal(prev) && MouseGestureIsVertical(next) && MouseGestureDirectionHasComponent(current, next)) {
                MouseGesturePushCanonicalDirection(canonical, next)
                continue
            }
            if (MouseGestureIsVertical(prev) && MouseGestureIsHorizontal(next) && MouseGestureDirectionHasComponent(current, next)) {
                MouseGesturePushCanonicalDirection(canonical, next)
                continue
            }
        }

        if (prev != "") {
            if (MouseGestureDirectionHasComponent(current, prev))
                continue
            if (MouseGestureIsHorizontal(prev)) {
                MouseGesturePushCanonicalDirection(canonical, vertical)
                continue
            }
            if (MouseGestureIsVertical(prev)) {
                MouseGesturePushCanonicalDirection(canonical, horizontal)
                continue
            }
        }

        if (next != "") {
            if (MouseGestureDirectionHasComponent(current, next)) {
                MouseGesturePushCanonicalDirection(canonical, next)
                continue
            }
            MouseGesturePushCanonicalDirection(canonical, vertical != "" ? vertical : horizontal)
            continue
        }

        MouseGesturePushCanonicalDirection(canonical, vertical != "" ? vertical : horizontal)
    }

    return canonical
}

MouseGestureSimplifyDirectionHistory(history) {
    canonical := MouseGestureCanonicalizeDirectionHistory(history)
    return ArrayJoin(canonical, "_")
}

MouseGesturePoll() {
    global mouseGestureState
    global mouseGestureConfig

    if (!IsSet(mouseGestureState) || !mouseGestureState.active)
        return

    if (!GetKeyState(mouseGestureState.button, "P")) {
        SetTimer(MouseGesturePoll, 0)
        return
    }

    session := mouseGestureState.session
    MouseGestureGetMousePos(&x, &y)
    stepDistance := MouseGestureDistance(session.lastX, session.lastY, x, y)
    if (stepDistance < 1)
        return

    session.totalDistance += stepDistance
    session.endX := x
    session.endY := y
    session.endMonitor := MouseGestureGetMonitorIndex(x, y)

    if (!session.becameGesture && session.totalDistance >= mouseGestureConfig.activateDistancePx) {
        session.becameGesture := true
        session.directionHistory := []
        session.direction := ""
        session.segmentAnchorX := session.startX
        session.segmentAnchorY := session.startY
        MouseGestureDrawTrailSegment(session.startX, session.startY, x, y)
        MouseGestureLog(
            "activate"
            . " | button=" . session.button
            . " | len=" . Round(session.totalDistance)
            . " | pos=" . x . "," . y
        )
    }

    if (session.becameGesture) {
        MouseGestureDrawTrailSegment(session.lastX, session.lastY, x, y)
        segmentDistance := MouseGestureDistance(session.segmentAnchorX, session.segmentAnchorY, x, y)
        if (segmentDistance >= mouseGestureConfig.stepDistancePx)
            MouseGestureCaptureDirection(session, session.segmentAnchorX, session.segmentAnchorY, x, y)
    }

    session.lastX := x
    session.lastY := y
}

MouseGestureReplayClick(button) {
    SendEvent("{" . button . " down}")
    SendEvent("{" . button . " up}")
}

MouseGestureBuildEvent(session) {
    lengthPx := Round(session.totalDistance)
    shapeName := MouseGestureClassifyShape(session.direction)

    return {
        triggerButton: session.button,
        gesture: session.direction,
        gestureRaw: session.direction,
        shapeName: shapeName,
        durationMs: A_TickCount - session.startedAt,
        lengthPx: lengthPx,
        sizeBucket: MouseGestureClassifySize(lengthPx),
        start: {x: session.startX, y: session.startY},
        end: {x: session.endX, y: session.endY},
        screenRegion: session.screenRegion,
        screenCell: session.screenCell,
        startMonitor: session.startMonitor,
        endMonitor: session.endMonitor,
        window: session.window
    }
}

MouseGestureShowDebug(event) {
    text := event.triggerButton
        . " " . event.gesture
        . (event.shapeName != "" ? " shape=" . event.shapeName : "")
        . " size=" . event.sizeBucket
        . " len=" . event.lengthPx
        . " start=" . event.start.x . "," . event.start.y
        . " end=" . event.end.x . "," . event.end.y
        . " mon=" . event.startMonitor
        . " region=" . event.screenRegion
        . " cell=" . event.screenCell
        . " exe=" . event.window.exe
    msg(text, {seconds: 1.2})
}

MouseGestureFinalizeSession(session) {
    global mouseGestureLearning

    if (!session.becameGesture || session.direction = "") {
        MouseGestureResetTrail()
        MouseGestureLog(
            "click"
            . " | button=" . session.button
            . " | len=" . Round(session.totalDistance)
            . " | end=" . session.endX . "," . session.endY
            . " | monitor=" . session.endMonitor
        )
        MouseGestureReplayClick(session.button)
        return
    }

    event := MouseGestureBuildEvent(session)
    MouseGestureResetTrail()
    MouseGestureLog(
        "gesture"
        . " | button=" . event.triggerButton
        . " | dir=" . event.gesture
        . " | shape=" . event.shapeName
        . " | size=" . event.sizeBucket
        . " | len=" . event.lengthPx
        . " | start=" . event.start.x . "," . event.start.y
        . " | end=" . event.end.x . "," . event.end.y
        . " | startMonitor=" . event.startMonitor
        . " | endMonitor=" . event.endMonitor
        . " | region=" . event.screenRegion
        . " | cell=" . event.screenCell
        . " | exe=" . event.window.exe
    )

    if (mouseGestureLearning.active) {
        MouseGestureLearnSample(event)
        return
    }

    if (MouseGestureHandleDebateEvent(event, session))
        return

    if (HandleMouseGestureQuickAction(event))
        return

    MouseGestureShowDebug(event)
}

*RButton::MouseGestureHandleButtonDown("RButton")
*RButton Up::MouseGestureHandleButtonUp("RButton")
*MButton::MouseGestureHandleButtonDown("MButton")
*MButton Up::MouseGestureHandleButtonUp("MButton")

#F1::MouseGestureStartShapeLearning()
#Esc::MouseGestureCancelShapeLearning()
