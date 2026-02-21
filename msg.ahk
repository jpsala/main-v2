global msgTimerIDsPool := []
global msgQueue := []
SetTimer(ProcessMsgQueue, 200)

/**
 * Displays a customizable tooltip message on the screen.
 * 
 * @param {...(string|Object)} params - Variable number of parameters.
 *   The strings passed, they are concatenated to form the message.
 *   If an object is passed, it can contain the following properties:
 * @param {number} [params.seconds=1] - Duration in seconds for the tooltip to remain visible.
 * @param {number} [params.id] - Unique identifier for the tooltip. If not provided, a random ID is generated.
 * @param {number} [params.x] - X-coordinate for the tooltip position. If not provided, current mouse X position is used.
 * @param {number} [params.y] - Y-coordinate for the tooltip position. If not provided, current mouse Y position is used.
 * @param {string} [params.separator=' | '] - Separator string used between multiple message parts.
 * @param {boolean} [params.topLeft=false] - If true, the tooltip will be displayed in the top left corner of the screen.
 * 
 * @example
 * msg("Hello", "World") // Displays "Hello | World"
 * msg("Custom", "Message", {seconds: 3, separator: " - "}) // Displays "Custom - Message" for 3 seconds
 */

msg(params*) {

    savedCoordMode := CoordMode('Mouse', 'Screen')
    
    MouseGetPos(&x, &y)

    static defaultOptions := { seconds: 1, separator: ' | ', topLeft: false }
    options := defaultOptions.Clone()
    options.id := GetRandomMessageId()
    options.x := x
    options.y := y
    
    tooltipContent := []
    hasObject := false

    for i, param in params {
        if (IsObject(param)) {
            hasObject := true
            for key, value in param.OwnProps() {
                if(key == 'id' and value == false) {
                    continue
                }
                options.%key% := value
            }
        } else if (Type(param) == "Number" && i == params.Length && !hasObject) {
            options.seconds := param
        } else {
            tooltipContent.Push(param)
        }
    }
    
    ; Apply topLeft after all options have been set
    if (options.topLeft) {
        ; Get monitor information using the existing helper function
        monitorInfo := getMonitorInfo()
        options.x := monitorInfo.left_screen + 5
        options.y := monitorInfo.top_screen + 5
    }
    
    resultText := ArrayJoin(tooltipContent, options.separator)

    MouseMove(options.x, options.y, 0)
    BlockInput('on')
    ToolTip(resultText, , , options.id)
    MouseMove(x, y, 0)
    BlockInput('off')
    CoordMode('Mouse', savedCoordMode)

    durationMs := Round(options.seconds * 1000)
    msgTimerIDsPool.Push(options.id)
    msgQueue.Push({
        finishInTicks: A_TickCount + durationMs,
        id: options.id,
        seconds: options.seconds,
        msg: resultText
    })
    return options.id
}

GetRandomMessageId() {
    static maxAttempts := 10
    Loop maxAttempts {
        randomID := Random(1, 20)
        if (!InArray(msgTimerIDsPool, randomID)) {
            return randomID
        }
            
    }
    log('Failed to find unique ID after ' . maxAttempts . ' attempts')
    throw 'Failed to find unique ID after ' . maxAttempts . ' attempts'
}

ProcessMsgQueue() {
    global msgQueue, msgTimerIDsPool

    for idx, msg in msgQueue {
        if (A_TickCount >= msg.finishInTicks) {
            arrayRemoveElByID(msgTimerIDsPool, msg.id)
            ToolTip(, , , msg.id)
            msgQueue.RemoveAt(idx)
        }
    }
}
