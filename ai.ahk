; AI module for prompts + providers + API calls + ListBox menu
; Hotkey:
;   Win+Ctrl+Alt+P -> open AI prompt menu

#Include ".\lib\WebViewToo.ahk"

global AI_SECTION := "ai"
global AI_PROMPTS_FILE := A_ScriptDir . "\ai-prompts.json"
global AI_PROMPTS := Map()
global AI_PROMPT_PROVIDERS := Map()
global AI_PROMPT_MODELS := Map()
global AI_PROMPT_HOTKEYS := Map()
global AI_PROMPT_NAMES := []
global AI_PROMPTS_LAST_MOD := ""

global AI_DEFAULT_PROVIDER := "openrouter"
global AI_VALID_PROVIDERS := ["openrouter", "openai", "anthropic", "xai"]
global AI_DEFAULT_MODELS := Map(
  "openrouter", "anthropic/claude-sonnet-4-5",
  "openai", "gpt-4.1-mini",
  "anthropic", "claude-3-5-sonnet-latest",
  "xai", "grok-3-mini"
)

global AI_MENU_GUI := false
global AI_MENU_PROMPTS_CTRL := false
global AI_MENU_INPUT_CTRL := false
global AI_RESULT_GUI := false
global AI_STARTUP_DEMO_GUI := false
global AI_STARTUP_DEMO_LIST_CTRL := false
global AI_WEB_GUI := ""
global AI_WEB_READY := false

AIInit() {
  AIEnsureConfigDefaults()
  AIMigrateKeysFromEnv()
  AILoadPrompts()
  SetTimer(AICheckPromptsReload, 5000)
  SetTimer(AIInitWebMainWindow, -1200)
  if (AIShouldShowStartupDemo()) {
    SetTimer(AIShowStartupDemo, -1500)
  }
}

AIEnsureConfigDefaults() {
  global AI_SECTION, AI_VALID_PROVIDERS, AI_DEFAULT_PROVIDER

  provider := StrLower(Trim(IniRead("config.ini", AI_SECTION, "provider", "")))
  if (!AIIsValidProvider(provider)) {
    provider := AI_DEFAULT_PROVIDER
    IniWrite(provider, "config.ini", AI_SECTION, "provider")
  }

  for _, p in AI_VALID_PROVIDERS {
    modelKey := "model_" . p
    if (Trim(IniRead("config.ini", AI_SECTION, modelKey, "")) = "") {
      IniWrite(AIGetProviderDefaultModel(p), "config.ini", AI_SECTION, modelKey)
    }

    apiKeyName := "api_key_" . p
    if (IniRead("config.ini", AI_SECTION, apiKeyName, "__AI_MISSING__") = "__AI_MISSING__") {
      IniWrite("", "config.ini", AI_SECTION, apiKeyName)
    }
  }

  maxTokens := Trim(IniRead("config.ini", AI_SECTION, "max_tokens", ""))
  if (!RegExMatch(maxTokens, "^\d+$")) {
    IniWrite("2048", "config.ini", AI_SECTION, "max_tokens")
  }

  if (IniRead("config.ini", AI_SECTION, "startup_demo_on_boot", "__AI_MISSING__") = "__AI_MISSING__") {
    IniWrite("1", "config.ini", AI_SECTION, "startup_demo_on_boot")
  }
}

AIShouldShowStartupDemo() {
  global AI_SECTION
  return Trim(IniRead("config.ini", AI_SECTION, "startup_demo_on_boot", "1")) = "1"
}

AIMigrateKeysFromEnv() {
  envPath := "C:\tools\ai-assistant\.env"
  if (!FileExist(envPath))
    return

  envContent := FileRead(envPath, "UTF-8")
  keyMap := Map(
    "openrouter", "OPENROUTER_KEY",
    "openai", "OPENAI_API_KEY",
    "anthropic", "ANTHROPIC_API_KEY",
    "xai", "XAI_API_KEY"
  )

  for provider, envKey in keyMap {
    currentKey := AIGetApiKey(provider)
    if (currentKey != "")
      continue
    imported := AIGetEnvValue(envContent, envKey)
    if (imported != "")
      AISetApiKey(provider, imported)
  }
}

AIGetEnvValue(envContent, key) {
  if RegExMatch(envContent, "(?m)^\s*" . key . "\s*=\s*(.*)$", &m)
    return Trim(m[1])
  return ""
}

AIProviderDisplayName(provider) {
  provider := AINormalizeProvider(provider)
  switch provider {
    case "openrouter":
      return "OpenRouter"
    case "openai":
      return "OpenAI"
    case "anthropic":
      return "Anthropic"
    case "xai":
      return "xAI"
    default:
      return provider
  }
}

AINormalizeProvider(provider) {
  global AI_DEFAULT_PROVIDER
  candidate := StrLower(Trim(provider))
  return AIIsValidProvider(candidate) ? candidate : AI_DEFAULT_PROVIDER
}

AIIsValidProvider(provider) {
  global AI_VALID_PROVIDERS
  for _, p in AI_VALID_PROVIDERS {
    if (p = provider)
      return true
  }
  return false
}

AIGetProviderDefaultModel(provider) {
  global AI_DEFAULT_MODELS, AI_DEFAULT_PROVIDER
  p := AINormalizeProvider(provider)
  return AI_DEFAULT_MODELS.Has(p) ? AI_DEFAULT_MODELS[p] : AI_DEFAULT_MODELS[AI_DEFAULT_PROVIDER]
}

AIGetProvider() {
  global AI_SECTION, AI_DEFAULT_PROVIDER
  return AINormalizeProvider(IniRead("config.ini", AI_SECTION, "provider", AI_DEFAULT_PROVIDER))
}

AISetProvider(provider) {
  global AI_SECTION
  provider := AINormalizeProvider(provider)
  IniWrite(provider, "config.ini", AI_SECTION, "provider")
}

AIGetDefaultModel(provider := "") {
  global AI_SECTION
  if (provider = "")
    provider := AIGetProvider()

  provider := AINormalizeProvider(provider)
  settingKey := "model_" . provider
  savedModel := Trim(IniRead("config.ini", AI_SECTION, settingKey, ""))
  return (savedModel != "") ? savedModel : AIGetProviderDefaultModel(provider)
}

AISetDefaultModel(model, provider := "") {
  global AI_SECTION
  if (provider = "")
    provider := AIGetProvider()

  provider := AINormalizeProvider(provider)
  model := Trim(model)
  if (model = "")
    return
  IniWrite(model, "config.ini", AI_SECTION, "model_" . provider)
}

AIGetApiKey(provider := "") {
  global AI_SECTION
  if (provider = "")
    provider := AIGetProvider()
  provider := AINormalizeProvider(provider)
  return Trim(IniRead("config.ini", AI_SECTION, "api_key_" . provider, ""))
}

AISetApiKey(provider, apiKey) {
  global AI_SECTION
  provider := AINormalizeProvider(provider)
  IniWrite(Trim(apiKey), "config.ini", AI_SECTION, "api_key_" . provider)
}

AIGetMaxTokens() {
  global AI_SECTION
  raw := Trim(IniRead("config.ini", AI_SECTION, "max_tokens", "2048"))
  return RegExMatch(raw, "^\d+$") ? Integer(raw) : 2048
}

AIEnsurePromptsFile() {
  global AI_PROMPTS_FILE
  if FileExist(AI_PROMPTS_FILE)
    return

  q := Chr(34)
  sample := "{`n"
  sample .= "  " q "Corregir texto" q ": " q "Corregi la gramatica, ortografia y claridad. Mantene el significado y el estilo." q ",`n"
  sample .= "  " q "Traducir a ingles" q ": " q "Translate this text to English. Keep tone and meaning." q ",`n"
  sample .= "  " q "Resumir" q ": " q "Resumi este texto en 2-3 oraciones manteniendo lo esencial." q "`n"
  sample .= "}`n"
  FileAppend(sample, AI_PROMPTS_FILE, "UTF-8")
}

AILoadPrompts() {
  global AI_PROMPTS, AI_PROMPT_PROVIDERS, AI_PROMPT_MODELS, AI_PROMPT_HOTKEYS, AI_PROMPT_NAMES, AI_PROMPTS_FILE, AI_PROMPTS_LAST_MOD

  AIEnsurePromptsFile()
  if !FileExist(AI_PROMPTS_FILE) {
    AINotify("No se encontró ai-prompts.json", 3)
    return
  }

  content := FileRead(AI_PROMPTS_FILE, "UTF-8")
  if (SubStr(content, 1, 1) = Chr(0xFEFF))
    content := SubStr(content, 2)
  if !RegExMatch(Trim(content), "^\{[\s\S]*\}$") {
    AINotify("ai-prompts.json inválido", 3)
    return
  }

  newPrompts := Map()
  newProviders := Map()
  newModels := Map()
  newHotkeys := Map()
  newNames := []

  pos := 1
  while (pos := RegExMatch(content, '"((?:[^"\\]|\\.)*?)"\s*:\s*"((?:[^"\\]|\\.)*?)"', &m, pos)) {
    key := AIJsonUnescape(m[1])
    rawValue := AIJsonUnescape(m[2])
    AIExtractPromptDirectives(rawValue, &providerId, &modelId, &hotkeyId, &bodyValue)

    if (providerId != "")
      newProviders[key] := providerId
    if (modelId != "")
      newModels[key] := modelId
    if (hotkeyId != "")
      newHotkeys[key] := hotkeyId

    newPrompts[key] := bodyValue
    newNames.Push(key)
    pos += m.Len
  }

  if (newNames.Length = 0) {
    AINotify("No hay prompts válidos en ai-prompts.json", 3)
    return
  }

  AI_PROMPTS := newPrompts
  AI_PROMPT_PROVIDERS := newProviders
  AI_PROMPT_MODELS := newModels
  AI_PROMPT_HOTKEYS := newHotkeys
  AI_PROMPT_NAMES := newNames
  AI_PROMPTS_LAST_MOD := FileGetTime(AI_PROMPTS_FILE, "M")
}

AIExtractPromptDirectives(rawValue, &providerOut, &modelOut, &hotkeyOut, &bodyOut) {
  providerOut := ""
  modelOut := ""
  hotkeyOut := ""
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
    if (SubStr(lower, 1, 10) = "@provider:") {
      candidate := StrLower(Trim(SubStr(line, 11)))
      if AIIsValidProvider(candidate)
        providerOut := candidate
      bodyOut := rest
      continue
    }
    if (SubStr(lower, 1, 7) = "@model:") {
      modelOut := Trim(SubStr(line, 8))
      bodyOut := rest
      continue
    }
    if (SubStr(lower, 1, 8) = "@hotkey:") {
      hotkeyOut := Trim(SubStr(line, 9))
      bodyOut := rest
      continue
    }
    break
  }

  if (SubStr(bodyOut, 1, 6) = "@file:") {
    promptFile := A_ScriptDir . "\" . Trim(SubStr(bodyOut, 7))
    if FileExist(promptFile)
      bodyOut := FileRead(promptFile, "UTF-8")
    else
      bodyOut := "ERROR: Prompt file not found: " . promptFile
  }
}

AICheckPromptsReload() {
  global AI_PROMPTS_FILE, AI_PROMPTS_LAST_MOD, AI_PROMPT_NAMES
  if !FileExist(AI_PROMPTS_FILE)
    return

  currentMod := FileGetTime(AI_PROMPTS_FILE, "M")
  if (currentMod != AI_PROMPTS_LAST_MOD) {
    AILoadPrompts()
    AIRefreshPromptMenuList()
    AINotify("AI prompts recargados (" . AI_PROMPT_NAMES.Length . ")", 1.5)
  }
}

; Public function: send text to model and return response.
AISendTextToModel(text, provider := "", model := "", systemPrompt := "") {
  return AIRequest(text, systemPrompt, provider, model)
}

AIRequest(userMessage, systemPrompt := "", provider := "", model := "") {
  provider := (Trim(provider) = "") ? AIGetProvider() : AINormalizeProvider(provider)
  apiKey := AIGetApiKey(provider)
  if (apiKey = "")
    throw Error("Missing API key for " . AIProviderDisplayName(provider))

  if (Trim(model) = "")
    model := AIGetDefaultModel(provider)

  payload := AIBuildPayload(provider, userMessage, systemPrompt, model)

  whr := ComObject("WinHttp.WinHttpRequest.5.1")
  whr.Open("POST", AIGetProviderChatUrl(provider), false)
  whr.SetRequestHeader("Content-Type", "application/json")
  AIApplyProviderHeaders(whr, provider, apiKey)
  whr.Send(payload)

  if (whr.Status < 200 || whr.Status >= 300) {
    throw Error("HTTP " . whr.Status . ": " . SubStr(AIReadUTF8(whr), 1, 300))
  }

  return AIParseContent(provider, AIReadUTF8(whr))
}

AIRunPrompt(promptName, inputText, provider := "", model := "") {
  global AI_PROMPTS, AI_PROMPT_PROVIDERS, AI_PROMPT_MODELS

  if !AI_PROMPTS.Has(promptName)
    throw Error("Prompt not found: " . promptName)

  promptText := AI_PROMPTS[promptName]
  if (provider = "" && AI_PROMPT_PROVIDERS.Has(promptName))
    provider := AI_PROMPT_PROVIDERS[promptName]
  if (model = "" && AI_PROMPT_MODELS.Has(promptName))
    model := AI_PROMPT_MODELS[promptName]

  systemPrompt := "You are a concise assistant. Follow user instructions exactly. Return only the final text."
  userMessage := promptText . "`n`n---`n`n" . inputText
  return AIRequest(userMessage, systemPrompt, provider, model)
}

AIBuildPayload(provider, userMessage, systemPrompt, model) {
  maxTokens := AIGetMaxTokens()
  switch provider {
    case "anthropic":
      return '{"model":"' . model . '","max_tokens":' . maxTokens
        . ',"system":"' . AIEscJson(systemPrompt) . '","messages":['
        . '{"role":"user","content":"' . AIEscJson(userMessage) . '"}'
        . ']}'
    default:
      return '{"model":"' . model . '","max_tokens":' . maxTokens . ',"messages":['
        . '{"role":"system","content":"' . AIEscJson(systemPrompt) . '"},'
        . '{"role":"user","content":"' . AIEscJson(userMessage) . '"}'
        . ']}'
  }
}

AIApplyProviderHeaders(whr, provider, apiKey) {
  switch provider {
    case "openrouter":
      whr.SetRequestHeader("Authorization", "Bearer " . apiKey)
      whr.SetRequestHeader("HTTP-Referer", "https://ai-assistant.local")
      whr.SetRequestHeader("X-Title", "AHK Main Script")
    case "openai", "xai":
      whr.SetRequestHeader("Authorization", "Bearer " . apiKey)
    case "anthropic":
      whr.SetRequestHeader("x-api-key", apiKey)
      whr.SetRequestHeader("anthropic-version", "2023-06-01")
    default:
      throw Error("Unsupported provider: " . provider)
  }
}

AIGetProviderChatUrl(provider) {
  switch provider {
    case "openrouter":
      return "https://openrouter.ai/api/v1/chat/completions"
    case "openai":
      return "https://api.openai.com/v1/chat/completions"
    case "anthropic":
      return "https://api.anthropic.com/v1/messages"
    case "xai":
      return "https://api.x.ai/v1/chat/completions"
    default:
      throw Error("Unsupported provider: " . provider)
  }
}

AIParseContent(provider, json) {
  if (provider = "anthropic") {
    if RegExMatch(json, '"text"\s*:\s*"((?:[^"\\]|\\.)*)"', &mText)
      return Trim(AIJsonUnescape(mText[1]))
  } else {
    if RegExMatch(json, '"content"\s*:\s*"((?:[^"\\]|\\.)*)"', &mContent)
      return Trim(AIJsonUnescape(mContent[1]))
  }
  throw Error("Could not parse API response")
}

AIReadUTF8(whr) {
  oADO := ComObject("ADODB.Stream")
  oADO.Type := 1
  oADO.Open()
  oADO.Write(whr.ResponseBody)
  oADO.Position := 0
  oADO.Type := 2
  oADO.Charset := "UTF-8"
  text := oADO.ReadText()
  oADO.Close()
  return text
}

AIEscJson(s) {
  s := StrReplace(s, "\", "\\")
  s := StrReplace(s, '"', '\"')
  s := StrReplace(s, "`n", "\n")
  s := StrReplace(s, "`r", "\r")
  s := StrReplace(s, "`t", "\t")
  return s
}

AIJsonUnescape(s) {
  s := StrReplace(s, "\\/", "/")
  s := StrReplace(s, "\\n", "`n")
  s := StrReplace(s, "\\r", "`r")
  s := StrReplace(s, "\\t", "`t")
  s := StrReplace(s, '\\"', '"')
  s := StrReplace(s, "\\\\", "\")
  return s
}

AIReadTextFromSelectionOrClipboard() {
  savedClip := ClipboardAll()
  A_Clipboard := ""
  Send("^c")
  hasSelection := ClipWait(0.4)
  selectedText := ""

  if (hasSelection && Trim(A_Clipboard) != "") {
    selectedText := A_Clipboard
  } else {
    A_Clipboard := savedClip
    ClipWait(0.4)
    selectedText := A_Clipboard
  }

  A_Clipboard := savedClip
  return selectedText
}

AIShowPromptMenu() {
  global AI_MENU_GUI, AI_MENU_PROMPTS_CTRL, AI_MENU_INPUT_CTRL

  if (!IsObject(AI_MENU_GUI)) {
    AI_MENU_GUI := Gui("+AlwaysOnTop +Resize +MinSize560x360", "AI Prompts")
    AI_MENU_GUI.SetFont("s10", "Segoe UI")

    AI_MENU_GUI.Add("Text", "xm", "Prompt")
    AI_MENU_PROMPTS_CTRL := AI_MENU_GUI.Add("ListBox", "xm w520 r10 vAiPromptList")
    AI_MENU_GUI.Add("Text", "xm y+10", "Texto")
    AI_MENU_INPUT_CTRL := AI_MENU_GUI.Add("Edit", "xm w520 r8 vAiInputText")

    btnFromClipboard := AI_MENU_GUI.Add("Button", "xm y+10 w130", "Desde Clipboard")
    btnRun := AI_MENU_GUI.Add("Button", "x+8 w130 Default", "Ejecutar")
    btnReload := AI_MENU_GUI.Add("Button", "x+8 w130", "Recargar prompts")
    btnClose := AI_MENU_GUI.Add("Button", "x+8 w120", "Cerrar")

    btnFromClipboard.OnEvent("Click", AIOnMenuLoadClipboard)
    btnRun.OnEvent("Click", AIOnMenuRun)
    btnReload.OnEvent("Click", AIOnMenuReloadPrompts)
    btnClose.OnEvent("Click", (*) => AI_MENU_GUI.Hide())
  }

  AIRefreshPromptMenuList()
  AIOnMenuLoadClipboard()
  AIShowAndActivate(AI_MENU_GUI)
}

AIRefreshPromptMenuList() {
  global AI_MENU_PROMPTS_CTRL, AI_PROMPT_NAMES
  if (!IsObject(AI_MENU_PROMPTS_CTRL))
    return

  AI_MENU_PROMPTS_CTRL.Delete()
  for _, name in AI_PROMPT_NAMES {
    AI_MENU_PROMPTS_CTRL.Add([name])
  }
  if (AI_PROMPT_NAMES.Length > 0)
    AI_MENU_PROMPTS_CTRL.Choose(1)
}

AIOnMenuLoadClipboard(*) {
  global AI_MENU_INPUT_CTRL
  if (!IsObject(AI_MENU_INPUT_CTRL))
    return

  txt := AIReadTextFromSelectionOrClipboard()
  if (Trim(txt) != "")
    AI_MENU_INPUT_CTRL.Value := txt
}

AIOnMenuReloadPrompts(*) {
  AILoadPrompts()
  AIRefreshPromptMenuList()
}

AIOnMenuRun(*) {
  global AI_MENU_PROMPTS_CTRL, AI_MENU_INPUT_CTRL, AI_PROMPT_NAMES, AI_PROMPT_PROVIDERS, AI_PROMPT_MODELS

  idx := AI_MENU_PROMPTS_CTRL.Value
  if (idx < 1 || idx > AI_PROMPT_NAMES.Length) {
    AINotify("Seleccioná un prompt", 2)
    return
  }

  promptName := AI_PROMPT_NAMES[idx]
  inputText := Trim(AI_MENU_INPUT_CTRL.Value)
  if (inputText = "") {
    AINotify("No hay texto para procesar", 2.5)
    return
  }

  providerOverride := AI_PROMPT_PROVIDERS.Has(promptName) ? AI_PROMPT_PROVIDERS[promptName] : ""
  modelOverride := AI_PROMPT_MODELS.Has(promptName) ? AI_PROMPT_MODELS[promptName] : ""
  runProvider := (providerOverride != "") ? AINormalizeProvider(providerOverride) : AIGetProvider()
  runModel := (modelOverride != "") ? modelOverride : AIGetDefaultModel(runProvider)

  AINotify("Procesando: " . AIProviderDisplayName(runProvider) . " · " . runModel, 4)
  try {
    result := AIRunPrompt(promptName, inputText, providerOverride, modelOverride)
    A_Clipboard := result
    AIShowResultWindow(promptName, result, runProvider, runModel)
    AINotify("Listo. Respuesta copiada a clipboard.", 2)
  } catch Error as e {
    AINotify("Error: " . e.Message, 4)
  }
}

AIShowResultWindow(promptName, resultText, provider, model) {
  global AI_RESULT_GUI

  if (IsObject(AI_RESULT_GUI)) {
    try AI_RESULT_GUI.Destroy()
  }

  AI_RESULT_GUI := Gui("+AlwaysOnTop +Resize +MinSize640x420", "AI Result")
  AI_RESULT_GUI.SetFont("s10", "Segoe UI")
  AI_RESULT_GUI.Add("Text", "xm w760", promptName . " | " . AIProviderDisplayName(provider) . " | " . model)
  resultCtrl := AI_RESULT_GUI.Add("Edit", "xm w760 r20 vAiResultEdit", resultText)

  btnCopy := AI_RESULT_GUI.Add("Button", "xm y+10 w120 Default", "Copiar")
  btnClose := AI_RESULT_GUI.Add("Button", "x+8 w120", "Cerrar")
  btnCopy.OnEvent("Click", AIOnResultCopy.Bind(resultCtrl))
  btnClose.OnEvent("Click", (*) => AI_RESULT_GUI.Hide())

  AIShowAndActivate(AI_RESULT_GUI)
}

AIOnResultCopy(resultCtrl, *) {
  A_Clipboard := resultCtrl.Value
  AINotify("Respuesta copiada", 1.5)
}

AINotify(text, seconds := 2) {
  ; Intentar usar msg() si existe, sino usar TrayTip
  try {
    if (IsSet(msg) && Type(msg) == "Func") {
      msg(text, {seconds: seconds})
      return
    }
  }
  try TrayTip("AI", text)
}

AIShowStartupDemo() {
  global AI_STARTUP_DEMO_GUI, AI_STARTUP_DEMO_LIST_CTRL

  if (!IsObject(AI_STARTUP_DEMO_GUI)) {
    AI_STARTUP_DEMO_GUI := Gui("+AlwaysOnTop +ToolWindow", "AI Startup Demo")
    AI_STARTUP_DEMO_GUI.SetFont("s10", "Segoe UI")
    AI_STARTUP_DEMO_GUI.Add("Text", "xm w520", "Demo de arranque: ListBox + AI")
    AI_STARTUP_DEMO_GUI.Add("Text", "xm w520 y+4", "Provider default: " . AIProviderDisplayName(AIGetProvider()) . " | Model: " . AIGetDefaultModel())
    AI_STARTUP_DEMO_LIST_CTRL := AI_STARTUP_DEMO_GUI.Add("ListBox", "xm w520 r4")
    AI_STARTUP_DEMO_LIST_CTRL.Add(["1) Validar ListBox"])
    AI_STARTUP_DEMO_LIST_CTRL.Add(["2) Probar AI (ping)"])
    AI_STARTUP_DEMO_LIST_CTRL.Add(["3) Abrir menu de prompts"])
    AI_STARTUP_DEMO_LIST_CTRL.Add(["4) Abrir UI web (como Ctrl+Q)"])
    AI_STARTUP_DEMO_LIST_CTRL.Choose(1)

    btnRun := AI_STARTUP_DEMO_GUI.Add("Button", "xm y+10 w140 Default", "Ejecutar")
    btnDisable := AI_STARTUP_DEMO_GUI.Add("Button", "x+8 w170", "No mostrar al iniciar")
    btnClose := AI_STARTUP_DEMO_GUI.Add("Button", "x+8 w120", "Cerrar")

    btnRun.OnEvent("Click", AIOnStartupDemoRun)
    btnDisable.OnEvent("Click", AIOnStartupDemoDisable)
    btnClose.OnEvent("Click", (*) => AI_STARTUP_DEMO_GUI.Hide())
  }

  AIShowAndActivate(AI_STARTUP_DEMO_GUI, "AutoSize")
}

AIShowAndActivate(guiObj, showOptions := "") {
  if (!IsObject(guiObj))
    return

  if (showOptions = "")
    guiObj.Show()
  else
    guiObj.Show(showOptions)

  hwnd := guiObj.Hwnd
  if (hwnd) {
    try WinShow("ahk_id " hwnd)
    try WinRestore("ahk_id " hwnd)
    try WinActivateFast("ahk_id " hwnd)
    if !WinActive("ahk_id " hwnd)
      try WinActivate("ahk_id " hwnd)
  }
}

AIOnStartupDemoRun(*) {
  global AI_STARTUP_DEMO_LIST_CTRL
  if (!IsObject(AI_STARTUP_DEMO_LIST_CTRL))
    return

  selected := AI_STARTUP_DEMO_LIST_CTRL.Value
  if (selected = 1) {
    AINotify("ListBox OK. Seleccion actual: " . AI_STARTUP_DEMO_LIST_CTRL.Text, 2.5)
    return
  }

  if (selected = 2) {
    provider := AIGetProvider()
    model := AIGetDefaultModel(provider)
    AINotify("Probando AI con " . AIProviderDisplayName(provider) . " | " . model, 4)
    try {
      result := AISendTextToModel("Respond only with: OK", provider, model, "You are a test assistant. Keep answers short.")
      A_Clipboard := result
      AIShowResultWindow("Startup AI test", result, provider, model)
      AINotify("AI OK. Respuesta copiada al clipboard.", 2)
    } catch Error as e {
      AINotify("AI error: " . e.Message, 4)
    }
    return
  }

  if (selected = 3) {
    AIShowPromptMenu()
    return
  }

  if (selected = 4) {
    AIGoToCommandWeb()
    return
  }

  AINotify("Selecciona una opcion del ListBox", 2)
}

AIOnStartupDemoDisable(*) {
  global AI_SECTION, AI_STARTUP_DEMO_GUI
  IniWrite("0", "config.ini", AI_SECTION, "startup_demo_on_boot")
  if (IsObject(AI_STARTUP_DEMO_GUI))
    AI_STARTUP_DEMO_GUI.Hide()
  AINotify("Startup demo desactivado (config.ini)", 2)
}

AIInitWebMainWindow(*) {
  global AI_WEB_GUI
  if IsObject(AI_WEB_GUI)
    return

  try {
    dllPath := A_ScriptDir "\lib\" (A_PtrSize * 8) "bit\WebView2Loader.dll"
    AI_WEB_GUI := WebViewGui("+AlwaysOnTop +Resize +MinSize400x400 -Caption", "AI Assistant",, {DllPath: dllPath})
    AI_WEB_GUI.OnEvent("Close", AIWebMainWindowClose)
    if (A_IsCompiled)
      AI_WEB_GUI.Control.BrowseFolder(A_ScriptDir)
    AI_WEB_GUI.Control.wv.add_WebMessageReceived(AIWebMessageHandler)
    AI_WEB_GUI.Navigate("ui/index.html")
  } catch Error as e {
    AINotify("Error inicializando UI web: " . e.Message, 4)
  }
}

AIShowWebMainWindow(focusCommands := false) {
  global AI_WEB_GUI, AI_WEB_READY

  if !IsObject(AI_WEB_GUI)
    AIInitWebMainWindow()
  if !IsObject(AI_WEB_GUI)
    return

  MonitorGetWorkArea(MonitorGetPrimary(), &ml, &mt, &mr, &mb)
  w := 584
  h := 600
  x := ml + (mr - ml - w) // 2
  y := mt + (mb - mt - h) // 3

  AIShowAndActivate(AI_WEB_GUI, "x" . x . " y" . y . " w" . w . " h" . h)
  if (AI_WEB_READY) {
    AIWebSendClipboardToUI()
    if (focusCommands)
      AI_WEB_GUI.ExecuteScriptAsync("focusCommands()")
    else
      AI_WEB_GUI.ExecuteScriptAsync("focusPrompt()")
  }
}

AIGoToCommandWeb(*) {
  AIShowWebMainWindow(true)
}

AIWebMainWindowClose(*) {
  global AI_WEB_GUI
  if IsObject(AI_WEB_GUI)
    AI_WEB_GUI.Hide()
  return 1
}

AIWebMessageHandler(wv, msg) {
  try data := msg.WebMessageAsJson
  catch
    return

  if !RegExMatch(data, '"action"\s*:\s*"(\w+)"', &m)
    return

  SetTimer(AIHandleWebAction.Bind(m[1]), -1)
}

AIHandleWebAction(action) {
  global AI_WEB_GUI, AI_WEB_READY, AI_PROMPTS, AI_PROMPT_MODELS, AI_PROMPT_PROVIDERS

  switch action {
    case "ready":
      AI_WEB_READY := true
      AIWebSendClipboardToUI()
      AIWebSendCommandsToUI()
      AIWebSendModelToUI()
      AIWebSendCommandHotkeyToUI()
      AI_WEB_GUI.ExecuteScriptAsync("focusCommands()")

    case "submit":
      promptText := AI_WEB_GUI.ExecuteScript("document.getElementById('prompt').value")
      clipText := AI_WEB_GUI.ExecuteScript("document.getElementById('clipboard-preview').value")
      cmdName := Trim(AI_WEB_GUI.ExecuteScript("document.getElementById('command-input').value"))
      modelOverride := ""
      providerOverride := ""
      if (cmdName != "" && AI_PROMPT_MODELS.Has(cmdName))
        modelOverride := AI_PROMPT_MODELS[cmdName]
      if (cmdName != "" && AI_PROMPT_PROVIDERS.Has(cmdName))
        providerOverride := AI_PROMPT_PROVIDERS[cmdName]
      AIWebProcessPrompt(promptText, clipText, modelOverride, providerOverride)

    case "commandSelected":
      cmdName := Trim(AI_WEB_GUI.ExecuteScript("document.getElementById('command-input').value"))
      if AI_PROMPTS.Has(cmdName) {
        promptText := AI_PROMPTS[cmdName]
        AI_WEB_GUI.ExecuteScriptAsync('setPromptText("' . AIEscJson(promptText) . '")')
      }
      if (cmdName != "" && (AI_PROMPT_MODELS.Has(cmdName) || AI_PROMPT_PROVIDERS.Has(cmdName))) {
        displayProvider := AI_PROMPT_PROVIDERS.Has(cmdName) ? AINormalizeProvider(AI_PROMPT_PROVIDERS[cmdName]) : AIGetProvider()
        displayModel := AI_PROMPT_MODELS.Has(cmdName) ? AI_PROMPT_MODELS[cmdName] : AIGetDefaultModel(displayProvider)
        AI_WEB_GUI.ExecuteScriptAsync('setModelDisplay("' . AIEscJson(AIProviderDisplayName(displayProvider) . " · " . displayModel) . '")')
      } else {
        AIWebSendModelToUI()
      }

    case "copy":
      resultText := AI_WEB_GUI.ExecuteScript("document.getElementById('result').value")
      if (Trim(resultText) != "") {
        A_Clipboard := resultText
        ClipWait(2)
        AI_WEB_GUI.ExecuteScriptAsync('setStatus("Copied to clipboard!")')
      }

    case "clear":
      AI_WEB_GUI.ExecuteScriptAsync("clearFields()")

    case "hide":
      AI_WEB_GUI.Hide()

    case "settings":
      AINotify("Settings web aun no integrado en main", 2.5)

    case "promptEditor":
      AINotify("Prompt editor web aun no integrado en main", 2.5)
  }
}

AIWebProcessPrompt(promptText, clipText, modelOverride := "", providerOverride := "") {
  global AI_WEB_GUI

  if (Trim(promptText) = "") {
    AI_WEB_GUI.ExecuteScriptAsync('setStatus("Write a prompt or select a command")')
    return
  }
  if (Trim(clipText) = "") {
    AI_WEB_GUI.ExecuteScriptAsync('setStatus("Clipboard is empty — copy some text first")')
    return
  }

  provider := (Trim(providerOverride) != "") ? AINormalizeProvider(providerOverride) : AIGetProvider()
  apiKey := AIGetApiKey(provider)
  if (apiKey = "") {
    AI_WEB_GUI.ExecuteScriptAsync('setStatus("Missing API key for ' . AIEscJson(AIProviderDisplayName(provider)) . '")')
    return
  }

  if (Trim(modelOverride) != "")
    useModel := modelOverride
  else
    useModel := AIGetDefaultModel(provider)

  AI_WEB_GUI.ExecuteScriptAsync('setResult("")')
  AI_WEB_GUI.ExecuteScriptAsync('setStatus("Processing with ' . AIEscJson(AIProviderDisplayName(provider) . " · " . useModel) . '...")')

  userMessage := promptText . "`n`n---`n`n" . clipText
  systemPrompt := "You are a concise assistant. Follow user instructions exactly. Return only the final text."

  try {
    result := AIRequest(userMessage, systemPrompt, provider, useModel)
    AI_WEB_GUI.ExecuteScriptAsync('setResult("' . AIEscJson(result) . '")')
    AI_WEB_GUI.ExecuteScriptAsync('setStatus("Done — ' . StrLen(result) . ' chars (' . AIEscJson(AIProviderDisplayName(provider) . " · " . useModel) . ')")')
  } catch Error as e {
    AI_WEB_GUI.ExecuteScriptAsync('setResult("Error: ' . AIEscJson(e.Message) . '")')
    AI_WEB_GUI.ExecuteScriptAsync('setStatus("Error")')
  }
}

AIWebSendClipboardToUI() {
  global AI_WEB_GUI
  clipText := A_Clipboard
  AI_WEB_GUI.ExecuteScriptAsync('setClipboardPreview("' . AIEscJson(clipText) . '")')
}

AIWebSendModelToUI() {
  global AI_WEB_GUI
  provider := AIGetProvider()
  model := AIGetDefaultModel(provider)
  AI_WEB_GUI.ExecuteScriptAsync('setModelDisplay("' . AIEscJson(AIProviderDisplayName(provider) . " · " . model) . '")')
}

AIWebSendCommandsToUI() {
  global AI_WEB_GUI
  AI_WEB_GUI.ExecuteScriptAsync("setCommands(" . AIWebBuildCommandsJson() . ")")
}

AIWebSendCommandHotkeyToUI() {
  global AI_WEB_GUI
  AI_WEB_GUI.ExecuteScriptAsync('setCommandHotkey("' . AIEscJson("^q") . '")')
}

AIWebBuildCommandsJson() {
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

; Open AI prompt menu (ListBox UI)
#!^p:: AIShowPromptMenu()
^q:: AIGoToCommandWeb()

; Bootstrap
AIInit()
