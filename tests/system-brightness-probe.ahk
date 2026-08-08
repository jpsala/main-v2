#Requires AutoHotkey v2.0
#ErrorStdOut "UTF-8"
#Warn All, Off

OnError(SystemBrightnessProbeUnhandledError)

SaveAppInstanceMap(*) {
}

LoadAppInstanceMap(*) {
}

volChange(*) {
}

brightness(*) {
}

#Include ..\system.ahk

try {
    AssertEdgePoint(100, -200, 0, -200, 1920, 880, true, "top edge with negative coordinates")
    AssertEdgePoint(100, -191, 0, -200, 1920, 880, true, "last pixel of top edge")
    AssertEdgePoint(100, -190, 0, -200, 1920, 880, false, "point below top edge")
    AssertEdgePoint(100, 869, 0, -200, 1920, 880, false, "point above bottom edge")
    AssertEdgePoint(100, 870, 0, -200, 1920, 880, true, "first pixel of bottom edge")
    AssertEdgePoint(1920, -200, 0, -200, 1920, 880, false, "right boundary is exclusive")
    AssertEdgePoint(100, 880, 0, -200, 1920, 880, false, "bottom boundary is exclusive")

    FileAppend("PASS`n", "*")
    ExitApp(0)
} catch Error as e {
    SystemBrightnessProbeFail(e)
}

AssertEdgePoint(x, y, left, top, right, bottom, expected, label) {
    actual := IsPointAtMonitorTopOrBottomEdge(x, y, left, top, right, bottom)
    if (actual != expected)
        throw Error(label . ": expected " . expected . ", got " . actual)
}

SystemBrightnessProbeUnhandledError(error, mode) {
    SystemBrightnessProbeFail(error)
    return true
}

SystemBrightnessProbeFail(error) {
    message := error.Message
    if (error.Stack != "")
        message .= "`n" . error.Stack
    FileAppend(message . "`n", "**")
    ExitApp(1)
}
