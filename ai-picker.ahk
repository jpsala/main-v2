; AI picker module (WebUI list of prompts)
; -------------------------------------------------------------------
; Configuracion del picker.
; La hotkey se recomienda manejarla desde Settings WebUI.
; -------------------------------------------------------------------
#Include ".\lib\WebViewToo.ahk"

global AI_PICKER_CFG := Map(
  ; Nota: la hotkey principal del picker ahora la maneja Settings WebUI.
  ; Dejalo en "" para evitar conflicto con hotkeys dinamicas.
  "hotkey", "",

  ; Fallback manual opcional (normalmente vacio cuando usas Settings WebUI).
  "fallback_hotkey", "",

  ; Precarga el WebView al iniciar para que abra mas rapido.
  ; Nota: esto puede consumir recursos al arranque.
  "preload_on_startup", false,
  "preload_delay_ms", 600,

  ; Delay para asegurar foco despues de mostrar la ventana.
  "focus_delay_ms", 50,

  ; Tamaño de ventana del picker.
  "width", 420,
  "height", 320,

  ; Posicion vertical: 3 = tercio superior, 2 = centro aprox.
  "vertical_divisor", 3,

  ; Archivo HTML del picker (ruta relativa al script).
  "ui_file", "ui/picker.html"
)

global AI_PICKER_GUI := false
global AI_PICKER_READY := false
global AI_PICKER_PREV_WIN := 0
global AI_PICKER_ACTIVE_HOTKEY := ""

AIPickerInit() {
  hotkey := Trim(AIPickerCfg("hotkey", "^q"))
  if (hotkey != "") {
    if !AIPickerTryRegisterHotkey(hotkey) {
      fallbackHotkey := Trim(AIPickerCfg("fallback_hotkey", "^!q"))
      if (fallbackHotkey != "" && AIPickerTryRegisterHotkey(fallbackHotkey)) {
        AINotify("Picker hotkey fallback activo: " . AI_PICKER_ACTIVE_HOTKEY, 4)
      } else {
        AINotify("No se pudo registrar hotkey del picker. Revisa conflictos de hotkeys.", 5)
      }
    }
  }

  if AIPickerCfgBool("preload_on_startup", true) {
    delayMs := AIPickerCfgInt("preload_delay_ms", 600)
    if (delayMs < 0)
      delayMs := -delayMs
    SetTimer(AIInitPickerWindow, -delayMs)
  }
}

AIPickerTryRegisterHotkey(hotkeySpec) {
  global AI_PICKER_ACTIVE_HOTKEY

  ; Intento normal
  try {
    Hotkey(hotkeySpec, AIShowPickerWindow)
    AI_PICKER_ACTIVE_HOTKEY := hotkeySpec
    return true
  } catch Error as e1 {
    ; Si falla, reintento forzando hook con "$".
    if (SubStr(hotkeySpec, 1, 1) != "$") {
      hookHotkey := "$" . hotkeySpec
      try {
        Hotkey(hookHotkey, AIShowPickerWindow)
        AI_PICKER_ACTIVE_HOTKEY := hookHotkey
        AINotify("Picker hotkey en modo hook: " . hookHotkey, 4)
        return true
      } catch Error as e2 {
        AINotify("Hotkey picker '" . hotkeySpec . "' fallo: " . e2.Message, 5)
        return false
      }
    }

    AINotify("Hotkey picker '" . hotkeySpec . "' fallo: " . e1.Message, 5)
    return false
  }
}

AIInitPickerWindow(*) {
  global AI_PICKER_GUI
  if IsObject(AI_PICKER_GUI)
    return

  dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
  AI_PICKER_GUI := WebViewGui("+AlwaysOnTop -Caption", "AI Prompt Picker",, {DllPath: dllPath})
  AI_PICKER_GUI.OnEvent("Close", (*) => AI_PICKER_GUI.Hide())

  if (A_IsCompiled)
    AI_PICKER_GUI.Control.BrowseFolder(A_ScriptDir)

  AI_PICKER_GUI.Control.wv.add_WebMessageReceived(AIPickerMessageHandler)
  AI_PICKER_GUI.Navigate(AIPickerCfg("ui_file", "ui/picker.html"))
}

AIShowPickerWindow(*) {
  global AI_PICKER_GUI, AI_PICKER_PREV_WIN

  if !IsObject(AI_PICKER_GUI)
    AIInitPickerWindow()

  ; Guardamos ventana activa para volver el foco al cerrar/seleccionar.
  AI_PICKER_PREV_WIN := WinExist("A")

  AIPickerGetActiveMonitorWorkArea(&ml, &mt, &mr, &mb)
  w := AIPickerCfgInt("width", 420)
  h := AIPickerCfgInt("height", 320)
  vDiv := AIPickerCfgInt("vertical_divisor", 3)
  if (vDiv < 1)
    vDiv := 1

  x := ml + (mr - ml - w) // 2
  y := mt + (mb - mt - h) // vDiv
  AI_PICKER_GUI.Show("x" . x . " y" . y . " w" . w . " h" . h)

  focusDelay := AIPickerCfgInt("focus_delay_ms", 50)
  if (focusDelay < 0)
    focusDelay := -focusDelay
  SetTimer(AIPickerActivateFocus, -focusDelay)
}

AIPickerActivateFocus(*) {
  global AI_PICKER_GUI, AI_PICKER_READY
  if !IsObject(AI_PICKER_GUI)
    return

  hwnd := AI_PICKER_GUI.Hwnd
  if (hwnd) {
    try WinShow("ahk_id " . hwnd)
    try WinActivateFast("ahk_id " . hwnd)
    if !WinActive("ahk_id " . hwnd)
      try WinActivate("ahk_id " . hwnd)
  }

  if (AI_PICKER_READY)
    AI_PICKER_GUI.ExecuteScriptAsync("resetAndFocus()")
}

AIPickerMessageHandler(wv, msg) {
  try data := msg.WebMessageAsJson
  catch
    return

  if !RegExMatch(data, '"action"\s*:\s*"(\w+)"', &m)
    return

  SetTimer(AIHandlePickerAction.Bind(m[1], data), -1)
}

AIHandlePickerAction(action, rawJson) {
  global AI_PICKER_GUI, AI_PICKER_READY, AI_PICKER_PREV_WIN

  switch action {
    case "ready":
      AI_PICKER_READY := true
      AISendCommandsToPickerUI()

    case "pick":
      promptName := ""
      if RegExMatch(rawJson, '"name"\s*:\s*"((?:[^"\\]|\\.)*)"', &mName)
        promptName := AIJsonUnescape(mName[1])

      AI_PICKER_GUI.Hide()
      if (AI_PICKER_PREV_WIN)
        try WinActivateFast("ahk_id " . AI_PICKER_PREV_WIN)

      if (promptName != "")
        SetTimer(AIExecutePromptSilently.Bind(promptName), -100)

    case "close":
      AI_PICKER_GUI.Hide()
      if (AI_PICKER_PREV_WIN)
        try WinActivateFast("ahk_id " . AI_PICKER_PREV_WIN)
  }
}

AISendCommandsToPickerUI() {
  global AI_PICKER_GUI, AI_PICKER_READY
  if !IsObject(AI_PICKER_GUI) || !AI_PICKER_READY
    return

  AI_PICKER_GUI.ExecuteScriptAsync("setCommands(" . AIBuildCommandsJson() . ")")
}

AIBuildCommandsJson() {
  global AI_PROMPT_NAMES, AI_PROMPT_MODELS, AI_PROMPT_HOTKEYS

  json := "["
  for i, name in AI_PROMPT_NAMES {
    if (i > 1)
      json .= ","

    model := AI_PROMPT_MODELS.Has(name) ? AIEscJson(AI_PROMPT_MODELS[name]) : ""
    hotkey := AI_PROMPT_HOTKEYS.Has(name) ? AIEscJson(AI_PROMPT_HOTKEYS[name]) : ""
    json .= '{"name":"' . AIEscJson(name) . '","model":"' . model . '","hotkey":"' . hotkey . '"}'
  }
  json .= "]"
  return json
}

; Ejecuta un prompt en silencio:
; 1) toma texto seleccionado (o clipboard si no hay seleccion)
; 2) envia al provider/model configurado
; 3) pega la respuesta en la app activa
AIExecutePromptSilently(promptName, *) {
  global AI_PROMPTS, AI_PROMPT_MODELS, AI_PROMPT_PROVIDERS

  if !AI_PROMPTS.Has(promptName) {
    AINotify("Prompt no encontrado: " . promptName, 3)
    return
  }

  savedClip := ClipboardAll()
  A_Clipboard := ""
  Send("^c")
  hasSelection := ClipWait(0.5)

  if (hasSelection && Trim(A_Clipboard) != "") {
    inputText := A_Clipboard
  } else {
    A_Clipboard := savedClip
    ClipWait(0.8)
    inputText := A_Clipboard
  }

  if (Trim(inputText) = "") {
    AINotify("No hay texto para procesar", 2.5)
    A_Clipboard := savedClip
    return
  }

  providerOverride := AI_PROMPT_PROVIDERS.Has(promptName) ? AI_PROMPT_PROVIDERS[promptName] : ""
  modelOverride := AI_PROMPT_MODELS.Has(promptName) ? AI_PROMPT_MODELS[promptName] : ""
  runProvider := (providerOverride != "") ? AINormalizeProvider(providerOverride) : AIGetProvider()
  runModel := (modelOverride != "") ? modelOverride : AIGetDefaultModel(runProvider)

  AINotify(promptName . " - " . AIProviderDisplayName(runProvider) . " | " . runModel, 4)
  try {
    result := AIRunPrompt(promptName, inputText, providerOverride, modelOverride)
    A_Clipboard := result
    ClipWait(1)
    Send("^v")
    Sleep(120)
    AINotify("Prompt aplicado", 1.8)
  } catch Error as e {
    AINotify("Error: " . e.Message, 4)
  }

  A_Clipboard := savedClip
}

AIPickerCfg(key, defaultValue := "") {
  global AI_PICKER_CFG
  return AI_PICKER_CFG.Has(key) ? AI_PICKER_CFG[key] : defaultValue
}

AIPickerCfgInt(key, defaultValue := 0) {
  raw := AIPickerCfg(key, defaultValue)
  raw := Trim(raw)
  if RegExMatch(raw, "^-?\d+$")
    return Integer(raw)
  return defaultValue
}

AIPickerCfgBool(key, defaultValue := false) {
  raw := AIPickerCfg(key, defaultValue)
  if (Type(raw) = "Integer")
    return raw != 0
  text := StrLower(Trim(raw))
  if (text = "1" || text = "true" || text = "yes" || text = "on")
    return true
  if (text = "0" || text = "false" || text = "no" || text = "off")
    return false
  return defaultValue
}

; Devuelve el work area del monitor donde esta la ventana activa.
; Si no encuentra una ventana activa valida, usa el monitor primario.
AIPickerGetActiveMonitorWorkArea(&outLeft, &outTop, &outRight, &outBottom) {
  try {
    WinGetPos(&wx, &wy, &ww, &wh, "A")
    cx := wx + ww // 2
    cy := wy + wh // 2
  } catch {
    cx := -99999
    cy := -99999
  }

  loop MonitorGetCount() {
    MonitorGetWorkArea(A_Index, &ml, &mt, &mr, &mb)
    if (cx >= ml && cx < mr && cy >= mt && cy < mb) {
      outLeft := ml
      outTop := mt
      outRight := mr
      outBottom := mb
      return
    }
  }

  MonitorGetWorkArea(MonitorGetPrimary(), &ml, &mt, &mr, &mb)
  outLeft := ml
  outTop := mt
  outRight := mr
  outBottom := mb
}

; Bootstrap del picker (hotkey + preload)
AIPickerInit()
