;===============================================================================
; Natural Calendar WebView
; Tray dashboard for C:\dev\corta\chats\calendar\events.json.
; Integrates with Windows Task Scheduler for independent notifications.
;===============================================================================

#Include ".\lib\WebViewToo.ahk"

global CALENDAR_GUI := false
global CALENDAR_READY := false
global CALENDAR_ROOT := "C:\dev\corta\chats\calendar"
global CALENDAR_EVENTS_FILE := CALENDAR_ROOT . "\events.json"
global CALENDAR_LOG := A_ScriptDir . "\calendar-window.log"
global CALENDAR_NOTIFIED := Map()
global CALENDAR_LAST_MOD := ""
global CALENDAR_TASK_PREFIX := "NaturalCalendar_"

CalendarStartReminderTimer() {
    CalendarCheckReminders()
    SetTimer(CalendarCheckReminders, 60000)
    CalendarSyncToTaskScheduler()
    SetTimer(CalendarFileWatcher, 30000)
}

CalendarSyncToTaskScheduler() {
    global CALENDAR_EVENTS_FILE, CALENDAR_TASK_PREFIX
    CalendarLog("Syncing to Task Scheduler")
    
    events := CalendarReadEvents()
    
    ; Get existing tasks
    existingTasks := []
    try {
        psCommand := '$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "' . CALENDAR_TASK_PREFIX . '*" }; $tasks | ForEach-Object { $_.TaskName }'
        outFile := A_Temp . "\calendar-ts-list-" . A_Now . ".txt"
        psScript := A_Temp . "\calendar-ts-list-" . A_Now . ".ps1"
        FileAppend(psCommand, psScript, "UTF-8")
        RunWait('pwsh -NoProfile -ExecutionPolicy Bypass -File "' . psScript . '" > "' . outFile . '"', , "Hide")
        if (FileExist(outFile)) {
            for line in FileRead(outFile, "UTF-8") {
                if (Trim(line) != "")
                    existingTasks.Push(Trim(line))
            }
            FileDelete(outFile)
        }
        FileDelete(psScript)
    } catch {
        CalendarLog("Error listing tasks: " . Error.Message)
    }
    
    ; Track which task names we need
    neededTasks := []
    
    ; Create/update tasks for pending events
    for event in events {
        if (CalendarMapGet(event, "status", "pending") != "pending")
            continue
        eventId := CalendarMapGet(event, "id", "")
        if (eventId = "")
            continue
        
        ; Get reminder minutes (supports number or array)
        reminderMinutes := CalendarMapGet(event, "reminder_minutes", 0)
        if (!IsObject(reminderMinutes)) {
            reminderMinutes := [reminderMinutes]
        }
        
        ; Create task for each reminder
        for _, minutes in reminderMinutes {
            if (minutes <= 0)
                continue
            taskName := CALENDAR_TASK_PREFIX . eventId . "_" . minutes . "min"
            neededTasks.Push(taskName)
            
            ; Check if task already exists
            needsUpdate := true
            for _, existingTask in existingTasks {
                if (existingTask = taskName) {
                    needsUpdate := false
                    break
                }
            }
            
            if (needsUpdate) {
                CalendarCreateTask(event, minutes)
            }
        }
        
        ; Always create exact-time task
        exactTaskName := CALENDAR_TASK_PREFIX . eventId . "_exact"
        neededTasks.Push(exactTaskName)
        exactNeedsUpdate := true
        for _, existingTask in existingTasks {
            if (existingTask = exactTaskName) {
                exactNeedsUpdate := false
                break
            }
        }
        if (exactNeedsUpdate) {
            CalendarCreateTask(event, 0)
        }
    }
    
    ; Delete tasks that are no longer needed
    for _, taskName in existingTasks {
        isNeeded := false
        for _, needed in neededTasks {
            if (needed = taskName) {
                isNeeded := true
                break
            }
        }
        if (!isNeeded) {
            CalendarDeleteTask(taskName)
        }
    }
    
    CalendarLog("Task Scheduler sync complete")
}

CalendarCreateTask(event, offsetMinutes := 0) {
    global CALENDAR_TASK_PREFIX
    eventId := CalendarMapGet(event, "id", "")
    title := CalendarMapGet(event, "title", "Event")
    description := CalendarMapGet(event, "description", "")
    eventDate := CalendarMapGet(event, "date", "")
    
    if (eventId = "" || eventDate = "")
        return false
    
    ; Parse event date: 2026-05-18T13:30:00
    datePart := StrSplit(eventDate, "T")
    timePart := StrSplit(datePart[2], ":")
    
    ; Build YYYYMMDDHH24MISS string for DateAdd
    year := SubStr(datePart[1], 1, 4)
    month := SubStr(datePart[1], 6, 2)
    day := SubStr(datePart[1], 9, 2)
    hour := timePart[1]
    minute := SubStr(timePart[2], 1, 2)
    baseStamp := year . month . day . hour . minute . "00"
    
    ; Apply offset
    if (offsetMinutes != 0) {
        adjustedStamp := DateAdd(baseStamp, -offsetMinutes, "Minutes")
    } else {
        adjustedStamp := baseStamp
    }
    
    ; Parse adjusted stamp
    adjYear := SubStr(adjustedStamp, 1, 4)
    adjMonth := SubStr(adjustedStamp, 5, 2)
    adjDay := SubStr(adjustedStamp, 7, 2)
    adjHour := SubStr(adjustedStamp, 9, 2)
    adjMinute := SubStr(adjustedStamp, 11, 2)
    
    taskDate := adjYear . "-" . adjMonth . "-" . adjDay
    taskTime := adjHour . ":" . adjMinute
    
    if (offsetMinutes = 0) {
        taskName := CALENDAR_TASK_PREFIX . eventId . "_exact"
        notifyDesc := description
    } else {
        taskName := CALENDAR_TASK_PREFIX . eventId . "_" . offsetMinutes . "min"
        if (offsetMinutes < 60) {
            notifyDesc := "[En " . offsetMinutes . " min] " . description
        } else if (offsetMinutes < 1440) {
            notifyDesc := "[En " . Round(offsetMinutes / 60, 1) . " h] " . description
        } else {
            notifyDesc := "[En " . Round(offsetMinutes / 1440, 1) . " d] " . description
        }
    }
    
    notifyScript := A_Temp . "\calendar-notify-" . eventId . "-" . offsetMinutes . ".ps1"
    
    ; Escape quotes for PowerShell double-quoted strings
    safeTitle := StrReplace(title, '"', '""')
    safeDesc := StrReplace(notifyDesc, '"', '""')
    
    notifyContent := '$title = "' . safeTitle . '"' . "`r`n"
    notifyContent .= '$desc = "' . safeDesc . '"' . "`r`n"
    notifyContent .= 'Add-Type -AssemblyName System.Windows.Forms' . "`r`n"
    notifyContent .= '[System.Windows.Forms.MessageBox]::Show($desc, "Calendar: $title")' . "`r`n"
    FileAppend(notifyContent, notifyScript, "UTF-8")
    
    ; Create scheduled task
    try {
        RunWait('Schtasks /Delete /TN "' . taskName . '" /F', , "Hide")
    } catch {
        ; Ignore errors
    }
    
    try {
        psCommand := 'Schtasks /Create /TN "' . taskName . '" /TR "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File \"' . notifyScript . '\"" /SC ONCE /SD ' . taskDate . ' /ST ' . taskTime
        RunWait(psCommand, , "Hide")
        CalendarLog("Created task: " . taskName)
        return true
    } catch Error as e {
        CalendarLog("Error creating task " . taskName . ": " . e.Message)
        return false
    }
}

CalendarDeleteTask(taskName) {
    try {
        RunWait('Schtasks /Delete /TN "' . taskName . '" /F', , "Hide")
        CalendarLog("Deleted task: " . taskName)
        return true
    } catch Error as e {
        CalendarLog("Error deleting task " . taskName . ": " . e.Message)
        return false
    }
}

CalendarFileWatcher() {
    global CALENDAR_EVENTS_FILE, CALENDAR_LAST_MOD
    if (!FileExist(CALENDAR_EVENTS_FILE))
        return
    currentMod := FileGetTime(CALENDAR_EVENTS_FILE, "M")
    if (currentMod != CALENDAR_LAST_MOD) {
        CALENDAR_LAST_MOD := currentMod
        CalendarSyncToTaskScheduler()
        ; Also refresh UI if open
        CalendarSendState()
    }
}

CalendarCheckReminders() {
    global CALENDAR_NOTIFIED
    events := CalendarReadEvents()
    nowStamp := A_Now
    
    for event in events {
        id := CalendarMapGet(event, "id", "")
        if (id = "" || CalendarMapGet(event, "status", "pending") != "pending")
            continue
        
        eventStamp := CalendarIsoToStamp(CalendarMapGet(event, "date", ""))
        if (eventStamp = "")
            continue
        
        ; Get reminder minutes (supports number or array)
        reminderMinutes := CalendarMapGet(event, "reminder_minutes", 0)
        if (!IsObject(reminderMinutes)) {
            reminderMinutes := [reminderMinutes]
        }
        
        ; Check each reminder
        for _, minutes in reminderMinutes {
            if (minutes <= 0)
                continue
            
            reminderStamp := DateAdd(eventStamp, -minutes, "Minutes")
            if (nowStamp < reminderStamp)
                continue
            
            notifyKey := id . ":" . minutes . "min"
            if (CALENDAR_NOTIFIED.Has(notifyKey))
                continue
            
            CALENDAR_NOTIFIED[notifyKey] := true
            CalendarNotifyEvent(event, "reminder_" . minutes)
        }
        
        ; Check exact time
        if (nowStamp >= eventStamp) {
            notifyKey := id . ":exact"
            if (!CALENDAR_NOTIFIED.Has(notifyKey)) {
                CALENDAR_NOTIFIED[notifyKey] := true
                CalendarNotifyEvent(event, "due")
            }
        }
    }
}

CalendarNotifyEvent(event, phase) {
    title := CalendarMapGet(event, "title", "Evento")
    dateText := StrReplace(SubStr(CalendarMapGet(event, "date", ""), 1, 16), "T", " ")
    prefix := phase = "due" ? "Vence ahora" : "Recordatorio"
    payload := Map(
        "windowTitle", "Natural Calendar",
        "icon", "!",
        "badge", prefix,
        "title", title,
        "message", dateText,
        "detail", CalendarMapGet(event, "description", ""),
        "eventId", CalendarMapGet(event, "id", ""),
        "buttons", [
            Map("action", "dismiss", "label", "Cerrar", "variant", "primary", "close", true),
            Map("action", "openCalendar", "label", "Abrir calendario", "variant", "", "close", false),
            Map("action", "completeEvent", "label", "Marcar hecho", "variant", "good", "close", true)
        ]
    )
    if (!ShowNotification(payload, CalendarNotificationAction, true))
        CalendarFallbackNotify(event, phase)
    CalendarLog("Notify " . CalendarMapGet(event, "id", "") . " phase=" . phase)
}

CalendarNotificationAction(action, data) {
    eventId := CalendarMapGet(NOTIFICATION_PAYLOAD, "eventId", "")
    switch action {
        case "openCalendar":
            ShowCalendarWindow()
        case "completeEvent":
            CalendarSetEventStatus(eventId, "completed")
            CalendarSendState("Evento completado")
    }
}

CalendarFallbackNotify(event, phase) {
    title := CalendarMapGet(event, "title", "Evento")
    dateText := StrReplace(SubStr(CalendarMapGet(event, "date", ""), 1, 16), "T", " ")
    prefix := phase = "due" ? "Vence ahora" : "Recordatorio"
    body := prefix . ": " . title . "`n" . dateText
    description := CalendarMapGet(event, "description", "")
    if (description != "")
        body .= "`n" . description
    
    try TrayTip(body, "Natural Calendar")
    try msg(body, { seconds: 20, topLeft: true })
}

ShowCalendarWindow() {
    global CALENDAR_GUI, CALENDAR_READY
    
    if (CALENDAR_GUI) {
        try {
            CALENDAR_GUI.Show()
            WinActivate(CALENDAR_GUI.Hwnd)
            CalendarSendState()
            return true
        } catch {
            CALENDAR_GUI := false
        }
    }
    
    CALENDAR_READY := false
    try {
        dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
        CALENDAR_GUI := WebViewGui("+Resize -Caption", "Natural Calendar",, {DllPath: dllPath, DefaultWidth: 880, DefaultHeight: 620})
        CALENDAR_GUI.BackColor := "111827"
        CALENDAR_GUI.OnEvent("Close", (*) => CloseCalendarWindow())
        CALENDAR_GUI.OnEvent("Escape", (*) => CloseCalendarWindow())
        CALENDAR_GUI.Control.wv.add_WebMessageReceived(CalendarHandleMessage)
        CALENDAR_GUI.Control.wv.add_NavigationCompleted(CalendarNavigationCompleted)
        CALENDAR_GUI.Navigate("ui/calendar.html")
        CALENDAR_GUI.Show("w880 h620 Hide")
        WebViewWindowStateRestoreOrCenter(CALENDAR_GUI, "naturalCalendar", 880, 620, true, true)
        CALENDAR_GUI.Show()
        WinActivate(CALENDAR_GUI.Hwnd)
        return true
    } catch Error as e {
        CALENDAR_GUI := false
        MsgBox("Error creando Natural Calendar: " . e.Message, "Natural Calendar", "Icon!")
        return false
    }
}

CalendarNavigationCompleted(wv, args) {
    global CALENDAR_READY
    CALENDAR_READY := true
    CalendarSendState()
}

CalendarHandleMessage(wv, args) {
    global CALENDAR_GUI
    try {
        json := args.WebMessageAsJson
        data := JsonLoad(&json)
        action := data.Has("action") ? data["action"] : ""
        
        switch action {
            case "ready", "refresh":
                CalendarSendState()
            case "deleteEvent":
                CalendarDeleteEvent(data.Has("id") ? data["id"] : "")
                CalendarSendState("Evento eliminado")
            case "completeEvent":
                CalendarSetEventStatus(data.Has("id") ? data["id"] : "", "completed")
                CalendarSendState("Evento completado")
            case "cancelEvent":
                CalendarSetEventStatus(data.Has("id") ? data["id"] : "", "cancelled")
                CalendarSendState("Evento cancelado")
            case "reopenEvent":
                CalendarSetEventStatus(data.Has("id") ? data["id"] : "", "pending")
                CalendarSendState("Evento reabierto")
            case "deleteReminder":
                CalendarDeleteReminder(data.Has("id") ? data["id"] : "", data.Has("minutes") ? data["minutes"] : 0)
                CalendarSendState("Recordatorio eliminado")
            case "addReminder":
                CalendarAddReminder(data.Has("id") ? data["id"] : "", data.Has("minutes") ? data["minutes"] : 0)
                CalendarSendState("Recordatorio agregado")
            case "openEventsFile":
                Run('"' . CALENDAR_EVENTS_FILE . '"')
            case "openFolder":
                Run('"' . CALENDAR_ROOT . '"')
            case "minimize":
                if (CALENDAR_GUI)
                    CALENDAR_GUI.Minimize()
            case "close":
                CloseCalendarWindow()
        }
    } catch Error as e {
        CalendarLog("HandleMessage error: " . e.Message)
        CalendarSendState("Error: " . e.Message)
    }
}

CalendarSendState(message := "") {
    global CALENDAR_GUI, CALENDAR_READY
    if (!CALENDAR_GUI || !CALENDAR_READY)
        return false
    
    try {
        CALENDAR_GUI.Control.wv.PostWebMessageAsJson(CalendarGetStateJson(message))
        return true
    } catch Error as e {
        CalendarLog("SendState error: " . e.Message)
        return false
    }
}

CloseCalendarWindow() {
    global CALENDAR_GUI, CALENDAR_READY
    if (CALENDAR_GUI) {
        try WebViewWindowStateSave(CALENDAR_GUI.Hwnd)
        try WebViewWindowStateForget(CALENDAR_GUI.Hwnd)
        try CALENDAR_GUI.Destroy()
    }
    CALENDAR_GUI := false
    CALENDAR_READY := false
}

CalendarGetStateJson(message := "") {
    events := CalendarReadEvents()
    nowIso := FormatTime(, "yyyy-MM-ddTHH:mm:ss")
    summary := CalendarBuildSummary(events, nowIso)
    
    payload := Map(
        "action", "state",
        "message", message,
        "generatedAt", FormatTime(, "yyyy-MM-dd HH:mm:ss"),
        "nowIso", nowIso,
        "root", CALENDAR_ROOT,
        "eventsFile", CALENDAR_EVENTS_FILE,
        "summary", summary,
        "events", events
    )
    return JsonDump(payload)
}

CalendarBuildSummary(events, nowIso) {
    pending := 0
    overdue := 0
    completed := 0
    cancelled := 0
    
    for event in events {
        status := CalendarMapGet(event, "status", "pending")
        date := CalendarMapGet(event, "date", "")
        if (status = "pending") {
            pending++
            if (date != "" && StrCompare(date, nowIso) < 0)
                overdue++
        } else if (status = "completed") {
            completed++
        } else if (status = "cancelled") {
            cancelled++
        }
    }
    
    return Map(
        "pending", pending,
        "overdue", overdue,
        "completed", completed,
        "cancelled", cancelled,
        "total", events.Length
    )
}

CalendarReadEvents() {
    global CALENDAR_EVENTS_FILE
    if (!FileExist(CALENDAR_EVENTS_FILE))
        return []
    
    text := FileRead(CALENDAR_EVENTS_FILE, "UTF-8")
    if (Trim(text) = "")
        return []
    
    try {
        events := JsonLoad(&text)
        return (events is Array) ? events : []
    } catch Error as e {
        CalendarLog("ReadEvents error: " . e.Message)
        return []
    }
}

CalendarWriteEvents(events) {
    global CALENDAR_EVENTS_FILE
    json := JsonDump(events, "  ") . "`n"
    FileDelete(CALENDAR_EVENTS_FILE)
    FileAppend(json, CALENDAR_EVENTS_FILE, "UTF-8")
    CalendarSyncToTaskScheduler()
}

CalendarDeleteEvent(id) {
    if (id = "")
        return false
    
    events := CalendarReadEvents()
    for index, event in events {
        if (CalendarMapGet(event, "id", "") = id) {
            events.RemoveAt(index)
            CalendarWriteEvents(events)
            return true
        }
    }
    return false
}

CalendarSetEventStatus(id, status) {
    if (id = "")
        return false
    
    events := CalendarReadEvents()
    for event in events {
        if (CalendarMapGet(event, "id", "") = id) {
            event["status"] := status
            CalendarWriteEvents(events)
            return true
        }
    }
    return false
}

CalendarDeleteReminder(id, minutes) {
    if (id = "" || minutes = 0)
        return false
    
    events := CalendarReadEvents()
    for event in events {
        if (CalendarMapGet(event, "id", "") = id) {
            rm := CalendarMapGet(event, "reminder_minutes", 0)
            if (IsObject(rm) && rm is Array) {
                newRm := []
                for _, m in rm {
                    if (m != minutes)
                        newRm.Push(m)
                }
                event["reminder_minutes"] := newRm.Length > 0 ? newRm : 0
            } else if (rm = minutes) {
                event["reminder_minutes"] := 0
            }
            CalendarWriteEvents(events)
            return true
        }
    }
    return false
}

CalendarAddReminder(id, minutes) {
    if (id = "" || minutes = 0)
        return false
    
    events := CalendarReadEvents()
    for event in events {
        if (CalendarMapGet(event, "id", "") = id) {
            rm := CalendarMapGet(event, "reminder_minutes", 0)
            if (IsObject(rm) && rm is Array) {
                ; Check if already exists
                for _, m in rm {
                    if (m = minutes)
                        return false
                }
                rm.Push(minutes)
            } else if (rm = 0 || rm = "") {
                event["reminder_minutes"] := [minutes]
            } else {
                event["reminder_minutes"] := [rm, minutes]
            }
            CalendarWriteEvents(events)
            return true
        }
    }
    return false
}

CalendarMapGet(valueMap, key, defaultValue := "") {
    return (valueMap is Map && valueMap.Has(key)) ? valueMap[key] : defaultValue
}

CalendarIsoToStamp(value) {
    if (value = "")
        return ""
    stamp := StrReplace(value, "-", "")
    stamp := StrReplace(stamp, "T", "")
    stamp := StrReplace(stamp, ":", "")
    stamp := SubStr(stamp . "000000", 1, 14)
    return RegExMatch(stamp, "^\d{14}$") ? stamp : ""
}

CalendarLog(message) {
    global CALENDAR_LOG
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . " | " . message . "`n", CALENDAR_LOG, "UTF-8")
}
