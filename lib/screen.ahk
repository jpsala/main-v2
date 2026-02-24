;===============================================================================
; SCREEN & MONITOR MODULE
; Mouse operations, monitor detection, and screen grid management
;===============================================================================

;===============================================================================
; MOUSE & CURSOR MANAGEMENT
;===============================================================================

mouseClickAndSave(x, y) {
    mousePos := saveMouse()
    mouseClick('L', x, y,,0)
    return mousePos
}

saveMouse() {
    MouseGetPosWithCoordMode(&x, &y, 'Screen')
    mouseSaved := { x: x, y: y }
    return mouseSaved
}

restoreMouse(mouseInfo) {
    coorMode := CoordMode('Mouse', 'Screen')
    MouseMove(mouseInfo.x, mouseInfo.y, 0)
    CoordMode('Mouse', coorMode)
}

clickOnCurrenPos() {
    MouseGetPosWithCoordMode(&xpos, &ypos, 'Screen')
    MouseClick('Left', xpos, ypos, 1, 0, 'Down',)
    sleep(200)
}

MouseGetPosWithCoordMode(&X, &Y, _coordMode := 'Screen') {
    cm := CoordMode('Mouse', _coordMode)
    MouseGetPos(&X, &Y)
    CoordMode('Mouse', cm)
}

mousePosX(_coordMode := 'Screen') {
    cm := CoordMode('Mouse', _coordMode)
    MouseGetPos(&X, &Y)
    CoordMode('Mouse', cm)
    return X
}

mousePosY(_coordMode := 'Screen') {
    cm := CoordMode('Mouse', _coordMode)
    MouseGetPos(&X, &Y)
    CoordMode('Mouse', cm)
    return Y
}

;===============================================================================
; MONITOR & SCREEN MANAGEMENT
;===============================================================================

getMonitorInfo() {
    ; Set mouse coordinate mode to screen
    _coorMode := CoordMode('Mouse', 'Screen')
    monitor := 0
    ; Get current mouse position
    MouseGetPos(&X, &Y)
    found := false
    ; Loop through all monitors to find which one the mouse is in
    loop MonitorGetCount() {
        MonitorGet(A_Index, &MonLeft, &MonTop, &MonRight, &MonBottom)
        ; Check if mouse is within the current monitor's bounds
        found := (X >= MonLeft && X <= MonRight && Y >= MonTop && Y <= MonBottom)
        coords := getMouseCoords('Screen')
        if (found) {
            monitor := {
                monitor: A_Index,
                top: 0,
                left: 0,
                right: MonRight - MonLeft,
                bottom: MonBottom - MonTop,
                top_screen: 0,
                left_screen: MonLeft,
                right_screen: MonRight,
                bottom_screen: MonBottom,
                x: X - MonLeft,
                y: Y - MonTop,
                x_screen: X,
                y_screen: Y
            }
            break
        }
    }
    if (!found) {
        {
            monitor := {
                monitor: A_Index,
                top: MonTop,
                left: MonLeft,
                right: MonRight,
                bottom: MonBottom,
                top_screen: MonTop,
                left_screen: MonLeft,
                right_screen: MonRight,
                bottom_screen: MonBottom,
                x: 10,
                y: 10,
                x_screen: 10,
                y_screen: 10
            }
        }
        log(monitor.monitor, monitor.top, monitor.left, monitor.right, monitor.bottom, monitor.x, monitor.y)
    }
    ; Restore previous mouse coordinate mode
    CoordMode('Mouse', _coorMode)
    return monitor
}

getMouseCoords(_coordMode := 'Screen') {
    __coorMode := CoordMode('Mouse', _coordMode)
    MouseGetPos(&X, &Y)
    CoordMode('Mouse', __coorMode)
    return { x: X, y: Y, coordMode: __coorMode }
}

getMonitor() {
    cm := CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    monitorCount := MonitorGetCount()

    if (monitorCount == 1) {
        CoordMode("Mouse", cm)
        return 1
    }

    loop monitorCount {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        if (x >= left && x <= right && y >= top && y <= bottom) {
            CoordMode("Mouse", cm)
            return A_Index
        }
    }

    CoordMode("Mouse", cm)
    return 1 ; Default to the first monitor if the mouse is not found on any monitor
}

;===============================================================================
; SCREEN AREAS & GRID MANAGEMENT
;===============================================================================

getAreaYX(y := 4, x := 4, areas := "", withMonitor := false, showLog := false, showTickCount := false, labelForDebug := false) {

    tc := A_TickCount
    winUnderMouse := GetWindowUnderMouse()
    WinActivateFast(winUnderMouse.id)
    tit := WinGetTitle('A')
    monitor := getMonitor()
    cm := CoordMode("Mouse", "Window")
    MouseGetPos(&xpos, &ypos)
    CoordMode('Mouse', 'Screen')
    MonitorGet(0, &Mon0L, &Mon0T, &Mon0R, &Mon0B)
    MonitorGet(1, &Mon1L, &Mon1T, &Mon1R, &Mon1B)
    ; monitor := (xpos <= Mon0R) ? 1 : 2

    ; Passing the monitor number only if withMonitor is true
    ret := calculateGridArea(xpos, ypos, (monitor == 1) ? Mon0L : Mon1L, (monitor == 1) ? Mon0R : Mon1R, (monitor == 1) ? Mon0B : Mon1B, y, x, areas, withMonitor ? monitor : "", showLog, labelForDebug)
    CoordMode("Mouse", cm)
    ticks := A_TickCount - tc
    if (showTickCount or (ticks > 5))
        msg('getAreaYX ticks', ticks, { seconds: 5 })
    return ret
}

calculateGridArea(x, y, l, r, b, rows, cols, areas, monitor := "", showLog := false, labelForDebug := false) {
    ; Adjust the x-coordinate relative to the left boundary of the active monitor
    x := x - l
    ctrl := GetKeyState("Ctrl", "P")
    currentX := Floor(x / ((r - l) / cols)) + 1
    currentY := Floor(y / (b / rows)) + 1
    currentArea := currentY . ":" . currentX
    if (monitor != "") {
        currentArea := currentArea
    }
    if (areas) {
        areaArray := StrSplit(areas, ",")
        found := 0
        foundArea := 'not found'
        for each, area in areaArray {
            if (showLog) {
                log(area . " " . currentArea)
            }
            if (area = currentArea || (monitor != "" && area = currentArea . "." . monitor) and !found) {
                found := 1
                foundArea := currentArea
            }
            if (showLog and found) {
                log(currentArea)
            }
        }
        if (showLog) {
            label := labelForDebug ? ' Label:' . labelForDebug : ''
            log('getAreaYX ' areas, 'Found: ' foundArea, label)
        }
        return found
    }

    if (monitor != "")  ; If a monitor number is provided, append it to the area
        return currentArea . "." . monitor
    if (showLog or ctrl) {
        label := labelForDebug ? ' Label:' . labelForDebug : ''
        log('getAreaYX ' areas, 'Found: ' currentArea, label)
    }
    return currentArea
}

showArea(area) {
    if (Type(area) == 'String' and (InStr(area, ',') > 1)) {
        area := StrSplit(area, ',')
    } else if (Type(area) != 'Array') {
        MsgBox('Area has to be a string sepparated by comma or an array')
        return
    }
    area := getAreaYX(area[1], area[2])
    msgV1(area, 1)
    notifu(area, , 1, 'sp.ahk', true)

    return
}

inArea(area, areas, inMonitor := 0) {
    if (!area) {
        throw "Area is null"
    }
    monitor := getMonitor()
    if (inMonitor !== 0 && inMonitor != monitor) {
        return false
    }
    currentArea := area ?? getAreaYX()
    for each, area in areas {
        if (currentArea = area) {
            return true
        }
    }
    return false
}

inSec(sec) {
    curSec := getAreaYX()
    sec := sec
    ret := (sec == curSec)
    return ret
}
