; AI WebUI module
; Full web windows: main, settings, prompt editor + dynamic hotkeys
#Include ".\lib\WebViewToo.ahk"
#Include ".\lib\chord-hotkeys.ahk"

global AI_WEBUI_MAIN_GUI := false
global AI_WEBUI_MAIN_READY := false
global AI_WEBUI_SETTINGS_GUI := false
global AI_WEBUI_SETTINGS_READY := false
global AI_WEBUI_EDITOR_GUI := false
global AI_WEBUI_EDITOR_READY := false

global AI_DYNAMIC_HOTKEYS_SUSPENDED := false
global AI_HOTKEY_MAP := Map()
global AI_HOTKEY_DEFAULTS := Map(
  ; Alt+` (US layout) => !vkC0
  "mainWindow", "!vkC0",
  "goToCommand", "",
  "promptPicker", "!q",
  "reload", ""
)
global AI_HOTKEY_LABELS := Map(
  "mainWindow", "Main window",
  "goToCommand", "Go to Command",
  "promptPicker", "Prompt Picker",
  "reload", "Reload"
)
global AI_HOTKEY_ACTIONS := Map(
  "mainWindow", AIShowMainWindow,
  "goToCommand", AIGoToCommand,
  "promptPicker", AIShowPickerWindow,
  "reload", (*) => Reload()
)

global AI_PROMPT_HOTKEY_MAP := Map()
global AI_PROMPT_HOTKEYS_SUSPENDED := false

AIWebUIInit() {
  global

  ; Prevent Alt combinations from triggering menu focus in target apps.
  A_MenuMaskKey := "vkE8"

  AIRegisterDynamicHotkeys()
  try AIRegisterPromptHotkeys(AI_PROMPT_HOTKEYS)
  ChordSetTimeout(0.9)
}

; ============================================================
; Dynamic hotkeys (configurable from settings web UI)
; ============================================================
AILoadHotkeysFromConfig() {
  global AI_SECTION, AI_HOTKEY_DEFAULTS

  loaded := Map()
  for actionId, defaultKey in AI_HOTKEY_DEFAULTS {
    iniKey := "hotkey_" . actionId
    loaded[actionId] := Trim(IniRead("config.ini", AI_SECTION, iniKey, defaultKey))
  }
  return loaded
}

AISaveHotkeyToConfig(actionId, ahkKey) {
  global AI_SECTION
  IniWrite(Trim(ahkKey), "config.ini", AI_SECTION, "hotkey_" . actionId)
}

AIRegisterDynamicHotkeys() {
  global AI_HOTKEY_MAP, AI_HOTKEY_ACTIONS

  config := AILoadHotkeysFromConfig()
  used := Map()

  for actionId, ahkKey in config {
    if (AI_HOTKEY_MAP.Has(actionId) && AI_HOTKEY_MAP[actionId] != "") {
      try Hotkey(AI_HOTKEY_MAP[actionId], "Off")
    }

    if (ahkKey != "" && AI_HOTKEY_ACTIONS.Has(actionId)) {
      if (used.Has(ahkKey)) {
        AINotify("Hotkey duplicada: " . ahkKey . " (" . actionId . ")", 4)
        ahkKey := ""
      } else {
        try Hotkey(ahkKey, AI_HOTKEY_ACTIONS[actionId])
        catch Error as e {
          AINotify("No se pudo registrar " . ahkKey . ": " . e.Message, 5)
          ahkKey := ""
        }
      }
    }

    if (ahkKey != "")
      used[ahkKey] := actionId

    AI_HOTKEY_MAP[actionId] := ahkKey
  }
}

AIRegisterSingleHotkey(actionId, newKey) {
  global AI_HOTKEY_MAP, AI_HOTKEY_ACTIONS

  if !AI_HOTKEY_ACTIONS.Has(actionId)
    throw Error("Unknown hotkey action: " . actionId)

  newKey := Trim(newKey)
  if (newKey != "") {
    for otherActionId, otherKey in AI_HOTKEY_MAP {
      if (otherActionId != actionId && otherKey = newKey)
        throw Error("Hotkey already used by " . otherActionId)
    }
  }

  if (AI_HOTKEY_MAP.Has(actionId) && AI_HOTKEY_MAP[actionId] != "")
    try Hotkey(AI_HOTKEY_MAP[actionId], "Off")

  if (newKey != "")
    Hotkey(newKey, AI_HOTKEY_ACTIONS[actionId])

  AI_HOTKEY_MAP[actionId] := newKey
  AISaveHotkeyToConfig(actionId, newKey)
}

AISuspendDynamicHotkeys() {
  global AI_DYNAMIC_HOTKEYS_SUSPENDED, AI_HOTKEY_MAP
  if (AI_DYNAMIC_HOTKEYS_SUSPENDED)
    return

  for _, ahkKey in AI_HOTKEY_MAP {
    if (ahkKey != "")
      try Hotkey(ahkKey, "Off")
  }

  AI_DYNAMIC_HOTKEYS_SUSPENDED := true
}

AIResumeDynamicHotkeys() {
  global AI_DYNAMIC_HOTKEYS_SUSPENDED, AI_HOTKEY_MAP, AI_HOTKEY_ACTIONS
  if !AI_DYNAMIC_HOTKEYS_SUSPENDED
    return

  for actionId, ahkKey in AI_HOTKEY_MAP {
    if (ahkKey != "" && AI_HOTKEY_ACTIONS.Has(actionId))
      try Hotkey(ahkKey, AI_HOTKEY_ACTIONS[actionId])
  }

  AI_DYNAMIC_HOTKEYS_SUSPENDED := false
}

AIEnsureDynamicHotkeysResumed(*) {
  global AI_DYNAMIC_HOTKEYS_SUSPENDED
  if (AI_DYNAMIC_HOTKEYS_SUSPENDED)
    AIResumeDynamicHotkeys()
}

AIGoToCommand(*) {
  global AI_WEBUI_MAIN_GUI, AI_WEBUI_MAIN_READY
  AIShowMainWindow()
  if (AI_WEBUI_MAIN_READY)
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync("focusCommands()")
}

; ============================================================
; Main web window
; ============================================================
AIInitMainWindow(*) {
  global AI_WEBUI_MAIN_GUI
  if IsObject(AI_WEBUI_MAIN_GUI)
    return

  dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
  AI_WEBUI_MAIN_GUI := WebViewGui("+AlwaysOnTop +Resize +MinSize400x400 -Caption", "AI Assistant",, {DllPath: dllPath})
  AI_WEBUI_MAIN_GUI.OnEvent("Close", AIMainWindowClose)

  if (A_IsCompiled)
    AI_WEBUI_MAIN_GUI.Control.BrowseFolder(A_ScriptDir)

  AI_WEBUI_MAIN_GUI.Control.wv.add_WebMessageReceived(AIMainMessageHandler)
  AI_WEBUI_MAIN_GUI.Navigate("ui/index.html")
}

AIShowMainWindow(*) {
  global AI_WEBUI_MAIN_GUI, AI_WEBUI_MAIN_READY

  if !IsObject(AI_WEBUI_MAIN_GUI)
    AIInitMainWindow()

  AIGetActiveMonitorWorkArea(&ml, &mt, &mr, &mb)
  w := 584
  h := 600
  x := ml + (mr - ml - w) // 2
  y := mt + (mb - mt - h) // 3
  AI_WEBUI_MAIN_GUI.Show("x" . x . " y" . y . " w" . w . " h" . h)

  if (AI_WEBUI_MAIN_READY) {
    AISendClipboardToMainUI()
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync("focusPrompt()")
  }
}

AIMainWindowClose(*) {
  global AI_WEBUI_MAIN_GUI
  AI_WEBUI_MAIN_GUI.Hide()
  return 1
}

AIMainMessageHandler(wv, msg) {
  try data := msg.WebMessageAsJson
  catch
    return

  if !RegExMatch(data, '"action"\s*:\s*"(\w+)"', &m)
    return

  SetTimer(AIHandleMainAction.Bind(m[1]), -1)
}

AIHandleMainAction(action) {
  global AI_WEBUI_MAIN_GUI, AI_WEBUI_MAIN_READY, AI_PROMPTS, AI_PROMPT_MODELS, AI_PROMPT_PROVIDERS

  switch action {
    case "ready":
      AI_WEBUI_MAIN_READY := true
      AISendClipboardToMainUI()
      AISendCommandsToMainUI()
      AISendModelToMainUI()
      AISendCommandHotkeyToMainUI()
      AI_WEBUI_MAIN_GUI.ExecuteScriptAsync("focusPrompt()")

    case "submit":
      promptText := AI_WEBUI_MAIN_GUI.ExecuteScript("document.getElementById('prompt').value")
      clipText := AI_WEBUI_MAIN_GUI.ExecuteScript("document.getElementById('clipboard-preview').value")
      cmdName := Trim(AI_WEBUI_MAIN_GUI.ExecuteScript("document.getElementById('command-input').value"))

      modelOverride := ""
      providerOverride := ""
      if (cmdName != "" && AI_PROMPT_MODELS.Has(cmdName))
        modelOverride := AI_PROMPT_MODELS[cmdName]
      if (cmdName != "" && AI_PROMPT_PROVIDERS.Has(cmdName))
        providerOverride := AI_PROMPT_PROVIDERS[cmdName]

      AIProcessMainPrompt(promptText, clipText, modelOverride, providerOverride)

    case "commandSelected":
      cmdName := Trim(AI_WEBUI_MAIN_GUI.ExecuteScript("document.getElementById('command-input').value"))
      if (cmdName != "" && AI_PROMPTS.Has(cmdName))
        AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setPromptText("' . AIEscJson(AI_PROMPTS[cmdName]) . '")')

      if (cmdName != "" && (AI_PROMPT_MODELS.Has(cmdName) || AI_PROMPT_PROVIDERS.Has(cmdName))) {
        displayProvider := AI_PROMPT_PROVIDERS.Has(cmdName) ? AINormalizeProvider(AI_PROMPT_PROVIDERS[cmdName]) : AIGetProvider()
        displayModel := AI_PROMPT_MODELS.Has(cmdName) ? AI_PROMPT_MODELS[cmdName] : AIGetDefaultModel(displayProvider)
        AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setModelDisplay("' . AIEscJson(AIProviderDisplayName(displayProvider) . " | " . displayModel) . '")')
      } else {
        AISendModelToMainUI()
      }

    case "copy":
      resultText := AI_WEBUI_MAIN_GUI.ExecuteScript("document.getElementById('result').value")
      if (Trim(resultText) != "") {
        A_Clipboard := resultText
        ClipWait(1)
        AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setStatus("Copied to clipboard")')
      }

    case "clear":
      AI_WEBUI_MAIN_GUI.ExecuteScriptAsync("clearFields()")

    case "hide":
      AI_WEBUI_MAIN_GUI.Hide()

    case "settings":
      AIShowSettingsWindow()

    case "promptEditor":
      AIShowPromptEditorWindow()
  }
}

AISendClipboardToMainUI() {
  global AI_WEBUI_MAIN_GUI
  if !IsObject(AI_WEBUI_MAIN_GUI)
    return
  AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setClipboardPreview("' . AIEscJson(A_Clipboard) . '")')
}

AISendModelToMainUI() {
  global AI_WEBUI_MAIN_GUI
  if !IsObject(AI_WEBUI_MAIN_GUI)
    return

  provider := AIGetProvider()
  model := AIGetDefaultModel(provider)
  AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setModelDisplay("' . AIEscJson(AIProviderDisplayName(provider) . " | " . model) . '")')
}

AISendCommandsToMainUI() {
  global AI_WEBUI_MAIN_GUI
  if !IsObject(AI_WEBUI_MAIN_GUI)
    return

  AI_WEBUI_MAIN_GUI.ExecuteScriptAsync("setCommands(" . AIWebUIBuildCommandsJson() . ")")
}

AISendCommandHotkeyToMainUI() {
  global AI_WEBUI_MAIN_GUI, AI_WEBUI_MAIN_READY, AI_HOTKEY_MAP
  if !IsObject(AI_WEBUI_MAIN_GUI) || !AI_WEBUI_MAIN_READY
    return

  goToCommandKey := AI_HOTKEY_MAP.Has("goToCommand") ? AI_HOTKEY_MAP["goToCommand"] : ""
  AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setCommandHotkey("' . AIEscJson(goToCommandKey) . '")')
}

AIWebUIBuildCommandsJson() {
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

AIProcessMainPrompt(promptText, clipText, modelOverride := "", providerOverride := "") {
  global AI_WEBUI_MAIN_GUI

  if (Trim(promptText) = "") {
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setStatus("Write a prompt or select a command")')
    return
  }
  if (Trim(clipText) = "") {
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setStatus("Clipboard is empty")')
    return
  }

  provider := (Trim(providerOverride) != "") ? AINormalizeProvider(providerOverride) : AIGetProvider()
  apiKey := AIGetApiKey(provider)
  if (apiKey = "") {
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setStatus("Missing API key for ' . AIEscJson(AIProviderDisplayName(provider)) . '")')
    return
  }

  if (Trim(modelOverride) != "")
    useModel := modelOverride
  else
    useModel := AIGetDefaultModel(provider)

  AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setResult("")')
  AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setStatus("Processing with ' . AIEscJson(AIProviderDisplayName(provider) . " | " . useModel) . '...")')

  userMessage := promptText . "`n`n---`n`n" . clipText
  lang := AIDetectLanguage(clipText)
  systemPrompt := AIGetSystemPrompt("fix", lang)
    . "`n`nThe user will provide instructions and text separated by --- . Return only the final text."

  try {
    result := AIRequest(userMessage, systemPrompt, provider, useModel)
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setResult("' . AIEscJson(result) . '")')
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setStatus("Done - ' . StrLen(result) . ' chars (' . AIEscJson(AIProviderDisplayName(provider) . " | " . useModel) . ')")')
  } catch Error as e {
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setResult("Error: ' . AIEscJson(e.Message) . '")')
    AI_WEBUI_MAIN_GUI.ExecuteScriptAsync('setStatus("Error")')
  }
}

; ============================================================
; Settings web window
; ============================================================
AIShowSettingsWindow(*) {
  global AI_WEBUI_SETTINGS_GUI, AI_SECTION

  if IsObject(AI_WEBUI_SETTINGS_GUI) {
    AIGetActiveMonitorWorkArea(&ml, &mt, &mr, &mb)
    WinGetPos(,, &curW, &curH, AI_WEBUI_SETTINGS_GUI.Hwnd)
    x := ml + (mr - ml - curW) // 2
    y := mt + (mb - mt - curH) // 3
    AI_WEBUI_SETTINGS_GUI.Show("x" . x . " y" . y)
    return
  }

  dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
  AI_WEBUI_SETTINGS_GUI := WebViewGui("+AlwaysOnTop +Resize +MinSize300x200 -Caption", "AI Settings",, {DllPath: dllPath})
  AI_WEBUI_SETTINGS_GUI.OnEvent("Close", AISettingsWindowClose)

  if (A_IsCompiled)
    AI_WEBUI_SETTINGS_GUI.Control.BrowseFolder(A_ScriptDir)

  AI_WEBUI_SETTINGS_GUI.Control.wv.add_WebMessageReceived(AISettingsMessageHandler)
  AI_WEBUI_SETTINGS_GUI.Navigate("ui/settings.html")

  savedW := Trim(IniRead("config.ini", AI_SECTION, "settings_w", "450"))
  savedH := Trim(IniRead("config.ini", AI_SECTION, "settings_h", "400"))
  w := RegExMatch(savedW, "^\d+$") ? Integer(savedW) : 450
  h := RegExMatch(savedH, "^\d+$") ? Integer(savedH) : 400
  if (w < 300)
    w := 450
  if (h < 200)
    h := 400

  AIGetActiveMonitorWorkArea(&ml, &mt, &mr, &mb)
  x := ml + (mr - ml - w) // 2
  y := mt + (mb - mt - h) // 3
  AI_WEBUI_SETTINGS_GUI.Show("x" . x . " y" . y . " w" . w . " h" . h)
}

AISettingsWindowClose(*) {
  global AI_WEBUI_SETTINGS_GUI, AI_SECTION
  try {
    AI_WEBUI_SETTINGS_GUI.GetPos(,, &w, &h)
    if (w > 0 && h > 0) {
      IniWrite(w, "config.ini", AI_SECTION, "settings_w")
      IniWrite(h, "config.ini", AI_SECTION, "settings_h")
    }
  }
  AI_WEBUI_SETTINGS_GUI.Hide()
  AIResumeDynamicHotkeys()
  return 1
}

AISettingsMessageHandler(wv, msg) {
  try data := msg.WebMessageAsJson
  catch
    return

  if !RegExMatch(data, '"action"\s*:\s*"(\w+)"', &m)
    return

  SetTimer(AIHandleSettingsAction.Bind(m[1], data), -1)
}

AIHandleSettingsAction(action, rawJson) {
  global AI_WEBUI_SETTINGS_GUI, AI_WEBUI_SETTINGS_READY

  switch action {
    case "ready":
      AI_WEBUI_SETTINGS_READY := true
      AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setCurrentProvider("' . AIEscJson(AIGetProvider()) . '")')
      AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setCurrentModel("' . AIEscJson(AIGetDefaultModel()) . '")')
      AISendApiKeysToSettings()
      AISendHotkeysToSettings()
      AIFetchAndSendModelsToSettings()

    case "modelSelected":
      selectedId := Trim(AI_WEBUI_SETTINGS_GUI.ExecuteScript("currentModelId"))
      if (selectedId != "") {
        AISetDefaultModel(selectedId, AIGetProvider())
        AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("Model saved for ' . AIEscJson(AIProviderDisplayName(AIGetProvider())) . ': ' . AIEscJson(selectedId) . '")')
        AISendModelToMainUI()
      }

    case "providerSelected":
      selectedProvider := AIExtractJsonString(rawJson, "provider")
      if (selectedProvider != "") {
        AISetProvider(selectedProvider)
        AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setCurrentProvider("' . AIEscJson(AIGetProvider()) . '")')
        AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setCurrentModel("' . AIEscJson(AIGetDefaultModel()) . '")')
        AIFetchAndSendModelsToSettings()
        AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("Provider saved: ' . AIEscJson(AIProviderDisplayName(AIGetProvider())) . '")')
        AISendModelToMainUI()
        AISendModelsToEditor()
      }

    case "saveApiKeys":
      AISetApiKey("openrouter", AIExtractJsonString(rawJson, "openrouterKey"))
      AISetApiKey("openai", AIExtractJsonString(rawJson, "openaiKey"))
      AISetApiKey("anthropic", AIExtractJsonString(rawJson, "anthropicKey"))
      AISetApiKey("xai", AIExtractJsonString(rawJson, "xaiKey"))

      AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setCurrentProvider("' . AIEscJson(AIGetProvider()) . '")')
      AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setCurrentModel("' . AIEscJson(AIGetDefaultModel()) . '")')
      AIFetchAndSendModelsToSettings()
      AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("API keys saved")')
      AISendModelToMainUI()
      AISendModelsToEditor()

    case "hotkeyChanged":
      actionId := AIExtractJsonString(rawJson, "id")
      ahkKey := AIExtractJsonString(rawJson, "key")
      if (actionId != "") {
        try {
          AIRegisterSingleHotkey(actionId, ahkKey)
          AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("Hotkey saved")')
          if (actionId = "goToCommand")
            AISendCommandHotkeyToMainUI()
        } catch Error as e {
          AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("Error: ' . AIEscJson(e.Message) . '")')
        }
      }

    case "startRecording":
      AISuspendDynamicHotkeys()
      SetTimer(AIEnsureDynamicHotkeysResumed, -15000)

    case "stopRecording":
      SetTimer(AIEnsureDynamicHotkeysResumed, 0)
      AIResumeDynamicHotkeys()

    case "refreshModels":
      AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("Fetching models...")')
      AIFetchAndSendModelsToSettings()

    case "close":
      AISettingsWindowClose()
  }
}

AISendApiKeysToSettings() {
  global AI_WEBUI_SETTINGS_GUI
  if !IsObject(AI_WEBUI_SETTINGS_GUI)
    return

  json := '{'
    . '"openrouter":"' . AIEscJson(AIGetApiKey("openrouter")) . '",'
    . '"openai":"' . AIEscJson(AIGetApiKey("openai")) . '",'
    . '"anthropic":"' . AIEscJson(AIGetApiKey("anthropic")) . '",'
    . '"xai":"' . AIEscJson(AIGetApiKey("xai")) . '"'
    . '}'

  AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync("setApiKeys(" . json . ")")
}

AISendHotkeysToSettings() {
  global AI_WEBUI_SETTINGS_GUI, AI_HOTKEY_MAP, AI_HOTKEY_LABELS
  if !IsObject(AI_WEBUI_SETTINGS_GUI)
    return

  json := "["
  first := true
  for actionId, ahkKey in AI_HOTKEY_MAP {
    if !first
      json .= ","
    label := AI_HOTKEY_LABELS.Has(actionId) ? AI_HOTKEY_LABELS[actionId] : actionId
    json .= '{"id":"' . AIEscJson(actionId) . '","label":"' . AIEscJson(label) . '","ahkKey":"' . AIEscJson(ahkKey) . '"}'
    first := false
  }
  json .= "]"

  AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync("setHotkeys(" . json . ")")
}

AIFetchAndSendModelsToSettings() {
  global AI_WEBUI_SETTINGS_GUI
  if !IsObject(AI_WEBUI_SETTINGS_GUI)
    return

  provider := AIGetProvider()
  apiKey := AIGetApiKey(provider)
  if (apiKey = "") {
    AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync("setModels([])")
    AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("Missing API key for ' . AIEscJson(AIProviderDisplayName(provider)) . '")')
    return
  }

  try {
    modelsJson := AIFetchModels(provider, apiKey)
    AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync("setModels(" . modelsJson . ")")
    AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("Loaded models for ' . AIEscJson(AIProviderDisplayName(provider)) . '")')
  } catch Error as e {
    AI_WEBUI_SETTINGS_GUI.ExecuteScriptAsync('setStatus("Error loading models: ' . AIEscJson(e.Message) . '")')
  }
}

; ============================================================
; Prompt editor web window
; ============================================================
AIShowPromptEditorWindow(*) {
  global AI_WEBUI_EDITOR_GUI, AI_WEBUI_EDITOR_READY

  AISuspendPromptHotkeys()

  if IsObject(AI_WEBUI_EDITOR_GUI) {
    AIGetActiveMonitorWorkArea(&ml, &mt, &mr, &mb)
    WinGetPos(,, &curW, &curH, AI_WEBUI_EDITOR_GUI.Hwnd)
    x := ml + (mr - ml - curW) // 2
    y := mt + (mb - mt - curH) // 3
    AI_WEBUI_EDITOR_GUI.Show("x" . x . " y" . y)
    if (AI_WEBUI_EDITOR_READY)
      AISendPromptsToEditor()
    return
  }

  dllPath := A_ScriptDir . "\lib\" . (A_PtrSize * 8) . "bit\WebView2Loader.dll"
  AI_WEBUI_EDITOR_GUI := WebViewGui("+AlwaysOnTop +Resize +MinSize500x400 -Caption", "AI Prompt Editor",, {DllPath: dllPath})
  AI_WEBUI_EDITOR_GUI.OnEvent("Close", AIEditorWindowClose)

  if (A_IsCompiled)
    AI_WEBUI_EDITOR_GUI.Control.BrowseFolder(A_ScriptDir)

  AI_WEBUI_EDITOR_GUI.Control.wv.add_WebMessageReceived(AIEditorMessageHandler)
  AI_WEBUI_EDITOR_GUI.Navigate("ui/prompt-editor.html")

  AIGetActiveMonitorWorkArea(&ml, &mt, &mr, &mb)
  w := 600
  h := 550
  x := ml + (mr - ml - w) // 2
  y := mt + (mb - mt - h) // 3
  AI_WEBUI_EDITOR_GUI.Show("x" . x . " y" . y . " w" . w . " h" . h)
}

AIEditorWindowClose(*) {
  global AI_WEBUI_EDITOR_GUI
  AI_WEBUI_EDITOR_GUI.Hide()
  AIResumePromptHotkeys()
  return 1
}

AIEditorMessageHandler(wv, msg) {
  try data := msg.WebMessageAsJson
  catch
    return

  if !RegExMatch(data, '"action"\s*:\s*"(\w+)"', &m)
    return

  SetTimer(AIHandleEditorAction.Bind(m[1], data), -1)
}

AIHandleEditorAction(action, rawJson := "") {
  global AI_WEBUI_EDITOR_GUI, AI_WEBUI_EDITOR_READY
  global AI_PROMPTS, AI_PROMPT_MODELS, AI_PROMPT_PROVIDERS, AI_PROMPT_HOTKEYS, AI_PROMPT_NAMES

  switch action {
    case "ready":
      AI_WEBUI_EDITOR_READY := true
      AISendPromptsToEditor()
      AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('setDefaultProvider("' . AIEscJson(AIGetProvider()) . '")')
      AISendModelsToEditor(AIGetProvider())

    case "providerChanged":
      selectedProvider := AIExtractJsonString(rawJson, "provider")
      if (selectedProvider = "")
        selectedProvider := AIGetProvider()
      AISendModelsToEditor(selectedProvider)

    case "savePrompt":
      newName := Trim(AI_WEBUI_EDITOR_GUI.ExecuteScript("document.getElementById('prompt-name').value"))
      newProvider := Trim(AI_WEBUI_EDITOR_GUI.ExecuteScript("document.getElementById('prompt-provider').value"))
      newModel := Trim(AI_WEBUI_EDITOR_GUI.ExecuteScript("document.getElementById('prompt-model').value"))
      newText := AI_WEBUI_EDITOR_GUI.ExecuteScript("document.getElementById('prompt-text').value")
      newHotkey := Trim(AI_WEBUI_EDITOR_GUI.ExecuteScript("document.getElementById('prompt-hotkey').dataset.ahkKey || ''"))
      oldName := Trim(AI_WEBUI_EDITOR_GUI.ExecuteScript("selectedName"))
      isFile := AI_WEBUI_EDITOR_GUI.ExecuteScript("isFilePrompt")

      if (newProvider != "")
        newProvider := AINormalizeProvider(newProvider)

      if (newName = "") {
        AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('setStatus("Name cannot be empty")')
        return
      }
      if (Trim(newText) = "" && isFile != "true") {
        AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('setStatus("Prompt text cannot be empty")')
        return
      }

      if (isFile = "true") {
        if (newProvider != "")
          AI_PROMPT_PROVIDERS[newName] := newProvider
        else if AI_PROMPT_PROVIDERS.Has(newName)
          AI_PROMPT_PROVIDERS.Delete(newName)

        if (newModel != "")
          AI_PROMPT_MODELS[newName] := newModel
        else if AI_PROMPT_MODELS.Has(newName)
          AI_PROMPT_MODELS.Delete(newName)

        if (newHotkey != "")
          AI_PROMPT_HOTKEYS[newName] := newHotkey
        else if AI_PROMPT_HOTKEYS.Has(newName)
          AI_PROMPT_HOTKEYS.Delete(newName)
      } else {
        if (oldName != "" && oldName != newName) {
          if AI_PROMPTS.Has(oldName)
            AI_PROMPTS.Delete(oldName)
          if AI_PROMPT_MODELS.Has(oldName)
            AI_PROMPT_MODELS.Delete(oldName)
          if AI_PROMPT_PROVIDERS.Has(oldName)
            AI_PROMPT_PROVIDERS.Delete(oldName)
          if AI_PROMPT_HOTKEYS.Has(oldName)
            AI_PROMPT_HOTKEYS.Delete(oldName)
        }

        AI_PROMPTS[newName] := newText

        if (newProvider != "")
          AI_PROMPT_PROVIDERS[newName] := newProvider
        else if AI_PROMPT_PROVIDERS.Has(newName)
          AI_PROMPT_PROVIDERS.Delete(newName)

        if (newModel != "")
          AI_PROMPT_MODELS[newName] := newModel
        else if AI_PROMPT_MODELS.Has(newName)
          AI_PROMPT_MODELS.Delete(newName)

        if (newHotkey != "")
          AI_PROMPT_HOTKEYS[newName] := newHotkey
        else if AI_PROMPT_HOTKEYS.Has(newName)
          AI_PROMPT_HOTKEYS.Delete(newName)
      }

      AIRegisterPromptHotkeys(AI_PROMPT_HOTKEYS)
      AIRebuildPromptNames()
      AISavePromptsJson()
      AISendPromptsToEditor()
      AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('onSaved("' . AIEscJson(newName) . '")')
      AIWebUIRefreshCommandSources()

    case "deletePrompt":
      delName := Trim(AI_WEBUI_EDITOR_GUI.ExecuteScript("selectedName"))
      if (delName = "" || !AI_PROMPTS.Has(delName))
        return

      AI_PROMPTS.Delete(delName)
      if AI_PROMPT_PROVIDERS.Has(delName)
        AI_PROMPT_PROVIDERS.Delete(delName)
      if AI_PROMPT_MODELS.Has(delName)
        AI_PROMPT_MODELS.Delete(delName)
      if AI_PROMPT_HOTKEYS.Has(delName)
        AI_PROMPT_HOTKEYS.Delete(delName)

      AIRegisterPromptHotkeys(AI_PROMPT_HOTKEYS)
      AIRebuildPromptNames()
      AISavePromptsJson()
      AISendPromptsToEditor()
      AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('setStatus("Deleted: ' . AIEscJson(delName) . '")')
      AIWebUIRefreshCommandSources()

    case "close":
      AI_WEBUI_EDITOR_GUI.Hide()
      AIResumePromptHotkeys()
  }
}

AISendModelsToEditor(provider := "") {
  global AI_WEBUI_EDITOR_GUI
  if !IsObject(AI_WEBUI_EDITOR_GUI)
    return

  if (Trim(provider) = "")
    provider := AIGetProvider()

  provider := AINormalizeProvider(provider)
  apiKey := AIGetApiKey(provider)

  if (apiKey = "") {
    AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync("setModels([])")
    AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('setStatus("Missing API key for ' . AIEscJson(AIProviderDisplayName(provider)) . '")')
    return
  }

  try {
    modelsJson := AIFetchModels(provider, apiKey)
    AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync("setModels(" . modelsJson . ")")
    if (provider = AIGetProvider())
      AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('setDefaultProvider("' . AIEscJson(provider) . '")')
    AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('setStatus("Models loaded from ' . AIEscJson(AIProviderDisplayName(provider)) . '")')
  } catch Error as e {
    AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync('setStatus("Error loading models: ' . AIEscJson(e.Message) . '")')
  }
}

AIStripPromptMetadata(rawValue, &bodyOut) {
  bodyOut := rawValue
  loop {
    nlPos := InStr(bodyOut, "`n")
    if (nlPos > 0) {
      line := Trim(SubStr(bodyOut, 1, nlPos - 1))
      rest := LTrim(SubStr(bodyOut, nlPos + 1))
    } else {
      line := Trim(bodyOut)
      rest := ""
    }

    lower := StrLower(line)
    if (SubStr(lower, 1, 10) = "@provider:"
     || SubStr(lower, 1, 7) = "@model:"
     || SubStr(lower, 1, 8) = "@hotkey:") {
      bodyOut := rest
      continue
    }
    break
  }
}

AISendPromptsToEditor() {
  global AI_WEBUI_EDITOR_GUI
  global AI_PROMPTS, AI_PROMPT_MODELS, AI_PROMPT_PROVIDERS, AI_PROMPT_HOTKEYS, AI_PROMPT_NAMES, AI_PROMPTS_FILE

  if !IsObject(AI_WEBUI_EDITOR_GUI)
    return

  fileEntries := Map()
  if FileExist(AI_PROMPTS_FILE) {
    raw := FileRead(AI_PROMPTS_FILE, "UTF-8")
    pos := 1
    while (pos := RegExMatch(raw, '"((?:[^"\\]|\\.)*?)"\s*:\s*"((?:[^"\\]|\\.)*?)"', &m, pos)) {
      key := AIJsonUnescape(m[1])
      val := AIJsonUnescape(m[2])
      AIStripPromptMetadata(val, &body)
      if (SubStr(body, 1, 6) = "@file:")
        fileEntries[key] := true
      pos += m.Len
    }
  }

  json := "["
  for i, name in AI_PROMPT_NAMES {
    if (i > 1)
      json .= ","
    promptVal := AI_PROMPTS.Has(name) ? AI_PROMPTS[name] : ""
    providerVal := AI_PROMPT_PROVIDERS.Has(name) ? AI_PROMPT_PROVIDERS[name] : ""
    modelVal := AI_PROMPT_MODELS.Has(name) ? AI_PROMPT_MODELS[name] : ""
    hotkeyVal := AI_PROMPT_HOTKEYS.Has(name) ? AI_PROMPT_HOTKEYS[name] : ""
    isFile := fileEntries.Has(name) ? "true" : "false"
    json .= '{"name":"' . AIEscJson(name) . '","prompt":"' . AIEscJson(promptVal) . '","provider":"' . AIEscJson(providerVal) . '","model":"' . AIEscJson(modelVal) . '","hotkey":"' . AIEscJson(hotkeyVal) . '","isFile":' . isFile . '}'
  }
  json .= "]"

  AI_WEBUI_EDITOR_GUI.ExecuteScriptAsync("setPrompts(" . json . ")")
}

AIRebuildPromptNames() {
  global AI_PROMPTS, AI_PROMPT_NAMES

  newNames := []
  for _, name in AI_PROMPT_NAMES {
    if AI_PROMPTS.Has(name)
      newNames.Push(name)
  }

  for name, _ in AI_PROMPTS {
    found := false
    for _, existing in newNames {
      if (existing = name) {
        found := true
        break
      }
    }
    if !found
      newNames.Push(name)
  }

  AI_PROMPT_NAMES := newNames
}

AISavePromptsJson() {
  global AI_PROMPTS, AI_PROMPT_MODELS, AI_PROMPT_PROVIDERS, AI_PROMPT_HOTKEYS, AI_PROMPT_NAMES, AI_PROMPTS_FILE, AI_PROMPTS_LAST_MOD

  fileRefs := Map()
  if FileExist(AI_PROMPTS_FILE) {
    raw := FileRead(AI_PROMPTS_FILE, "UTF-8")
    pos := 1
    while (pos := RegExMatch(raw, '"((?:[^"\\]|\\.)*?)"\s*:\s*"((?:[^"\\]|\\.)*?)"', &m, pos)) {
      key := AIJsonUnescape(m[1])
      val := AIJsonUnescape(m[2])
      AIStripPromptMetadata(val, &body)
      if (SubStr(body, 1, 6) = "@file:")
        fileRefs[key] := body
      pos += m.Len
    }
  }

  json := "{`n"
  for i, name in AI_PROMPT_NAMES {
    if (i > 1)
      json .= ",`n"

    providerPrefix := AI_PROMPT_PROVIDERS.Has(name) ? Trim(AI_PROMPT_PROVIDERS[name]) : ""
    modelPrefix := AI_PROMPT_MODELS.Has(name) ? Trim(AI_PROMPT_MODELS[name]) : ""
    hotkeyPrefix := AI_PROMPT_HOTKEYS.Has(name) ? Trim(AI_PROMPT_HOTKEYS[name]) : ""

    prefix := ""
    if (providerPrefix != "")
      prefix .= "@provider:" . providerPrefix . "`n"
    if (modelPrefix != "")
      prefix .= "@model:" . modelPrefix . "`n"
    if (hotkeyPrefix != "")
      prefix .= "@hotkey:" . hotkeyPrefix . "`n"

    if fileRefs.Has(name) {
      val := prefix . fileRefs[name]
      json .= '  "' . AIEscJsonFile(name) . '": "' . AIEscJsonFile(val) . '"'
    } else {
      promptVal := AI_PROMPTS.Has(name) ? AI_PROMPTS[name] : ""
      val := prefix . promptVal
      json .= '  "' . AIEscJsonFile(name) . '": "' . AIEscJsonFile(val) . '"'
    }
  }
  json .= "`n}`n"

  try FileDelete(AI_PROMPTS_FILE)
  FileAppend(json, AI_PROMPTS_FILE, "UTF-8")
  AI_PROMPTS_LAST_MOD := FileGetTime(AI_PROMPTS_FILE, "M")
}

AIEscJsonFile(s) {
  s := StrReplace(s, "\", "\\")
  s := StrReplace(s, '"', '\"')
  s := StrReplace(s, "`n", "\\n")
  s := StrReplace(s, "`r", "\r")
  s := StrReplace(s, "`t", "\t")
  return s
}

; ============================================================
; Prompt hotkeys (single and chord)
; ============================================================
AIRegisterPromptHotkeys(newHotkeys) {
  global AI_PROMPT_HOTKEY_MAP, AI_PROMPT_HOTKEYS_SUSPENDED, AI_PROMPT_HOTKEYS

  for _, key in AI_PROMPT_HOTKEY_MAP {
    if (key != "")
      try Hotkey(key, "Off")
  }

  AI_PROMPT_HOTKEY_MAP := Map()
  AI_PROMPT_HOTKEYS := newHotkeys
  ChordUnregisterAll()

  if (AI_PROMPT_HOTKEYS_SUSPENDED)
    return

  chordPrefixMap := Map()
  for name, key in newHotkeys {
    key := Trim(key)
    if (key = "")
      continue

    prefixHotkey := ""
    suffixKey := ""
    if ChordTryParseHotkeySpec(key, &prefixHotkey, &suffixKey) {
      if !chordPrefixMap.Has(prefixHotkey)
        chordPrefixMap[prefixHotkey] := Map()
      chordPrefixMap[prefixHotkey][suffixKey] := name
      continue
    }

    try {
      Hotkey(key, AIExecutePromptSilently.Bind(name))
      AI_PROMPT_HOTKEY_MAP[name] := key
    }
  }

  ChordRegister(chordPrefixMap, AIExecutePromptSilently)
}

AISuspendPromptHotkeys() {
  global AI_PROMPT_HOTKEY_MAP, AI_PROMPT_HOTKEYS_SUSPENDED
  if (AI_PROMPT_HOTKEYS_SUSPENDED)
    return

  for _, key in AI_PROMPT_HOTKEY_MAP {
    if (key != "")
      try Hotkey(key, "Off")
  }

  ChordUnregisterAll()
  AI_PROMPT_HOTKEYS_SUSPENDED := true
}

AIResumePromptHotkeys() {
  global AI_PROMPT_HOTKEYS_SUSPENDED, AI_PROMPT_HOTKEYS
  if !AI_PROMPT_HOTKEYS_SUSPENDED
    return

  AI_PROMPT_HOTKEYS_SUSPENDED := false
  AIRegisterPromptHotkeys(AI_PROMPT_HOTKEYS)
}

; ============================================================
; Shared refresh hooks
; ============================================================
AIWebUIRefreshCommandSources() {
  AISendCommandsToMainUI()
  try AISendCommandsToPickerUI()
  AISendPromptsToEditor()
}

AIWebUIOnPromptsReload() {
  AIRegisterPromptHotkeys(AI_PROMPT_HOTKEYS)
  AIWebUIRefreshCommandSources()
}

; ============================================================
; Provider model list fetch
; ============================================================
AIFetchModels(provider, apiKey) {
  provider := AINormalizeProvider(provider)
  if (Trim(apiKey) = "")
    throw Error("Missing API key for provider: " . provider)

  whr := ComObject("WinHttp.WinHttpRequest.5.1")
  whr.Open("GET", AIGetProviderModelsUrl(provider), false)
  AIApplyProviderHeaders(whr, provider, apiKey)
  whr.Send()

  if (whr.Status < 200 || whr.Status >= 300)
    throw Error("HTTP " . whr.Status . " fetching models")

  rawJson := AIReadUTF8(whr)
  return AIParseModels(provider, rawJson)
}

AIGetProviderModelsUrl(provider) {
  switch provider {
    case "openrouter":
      return "https://openrouter.ai/api/v1/models"
    case "openai":
      return "https://api.openai.com/v1/models"
    case "anthropic":
      return "https://api.anthropic.com/v1/models"
    case "xai":
      return "https://api.x.ai/v1/models"
    default:
      throw Error("Unsupported provider: " . provider)
  }
}

AIParseModels(provider, rawJson) {
  result := "["
  pos := 1
  first := true

  while (pos := RegExMatch(rawJson, '"id"\s*:\s*"((?:[^"\\]|\\.)*)"', &mId, pos)) {
    modelId := AIJsonUnescape(mId[1])
    modelName := modelId
    nearby := SubStr(rawJson, pos, 700)

    if (provider = "openrouter") {
      if RegExMatch(nearby, '"name"\s*:\s*"((?:[^"\\]|\\.)*)"', &mName)
        modelName := AIJsonUnescape(mName[1])
    } else if (provider = "anthropic") {
      if RegExMatch(nearby, '"display_name"\s*:\s*"((?:[^"\\]|\\.)*)"', &mDisplay)
        modelName := AIJsonUnescape(mDisplay[1])
    }

    if !first
      result .= ","

    result .= '{"id":"' . AIEscJson(modelId) . '","name":"' . AIEscJson(modelName) . '"}'
    first := false
    pos += mId.Len
  }

  result .= "]"
  return result
}

; ============================================================
; Prompt style helpers (same behavior as source project)
; ============================================================
AIDetectLanguage(text) {
  spanishChars := ["a", "e", "i", "o", "u", "n", "u", "?", "!"]
  ; Keep this simple and deterministic. Accented letters are normalized in many sources.
  for _, marker in [" que ", " una ", " para ", " pero ", " como ", " con ", " por ", " los ", " las ", " del "] {
    if InStr(" " . StrLower(text) . " ", marker)
      return "es"
  }
  return "en"
}

AIGetSystemPrompt(mode, lang) {
  styleEs := "Escribi en estilo natural de developer argentino. Usa voseo y tono directo."
  styleEn := "Write in a concise and natural non-native developer style."

  taskFixEs := "Corregi gramatica, ortografia y claridad. Devolve solo el texto corregido."
  taskFixEn := "Fix grammar, spelling and clarity. Return only corrected text."

  taskWriteEs := "Escribi el texto solicitado y devolve solo el resultado."
  taskWriteEn := "Write the requested text and return only the result."

  style := (lang = "es") ? styleEs : styleEn
  task := (mode = "fix")
    ? ((lang = "es") ? taskFixEs : taskFixEn)
    : ((lang = "es") ? taskWriteEs : taskWriteEn)

  return style . "`n`n" . task
}

; ============================================================
; Utility helpers
; ============================================================
AIExtractJsonString(rawJson, key) {
  pattern := '"' . key . '"\s*:\s*"((?:[^"\\]|\\.)*)"'
  if RegExMatch(rawJson, pattern, &m) {
    value := m[1]
    value := StrReplace(value, "\\n", "`n")
    value := StrReplace(value, "\\r", "")
    value := StrReplace(value, "\\t", "`t")
    value := StrReplace(value, '\\"', '"')
    value := StrReplace(value, "\\\\", "\")
    return value
  }
  return ""
}

AIGetActiveMonitorWorkArea(&outLeft, &outTop, &outRight, &outBottom) {
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

; Hotkeys for AI windows
#HotIf AIMainWindowIsActive()
Escape::AIMainWindowClose()
#HotIf

AIMainWindowIsActive() {
  global AI_WEBUI_MAIN_GUI
  return IsObject(AI_WEBUI_MAIN_GUI) && WinActive("ahk_id " . AI_WEBUI_MAIN_GUI.Hwnd)
}

; Bootstrap web UI layer
AIWebUIInit()
