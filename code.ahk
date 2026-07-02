; ********************************************
; vscode hotkeys
; ********************************************
#HotIf (WinActive("ahk_exe Code.exe") or WinActive("ahk_exe Cursor.exe",)) and (activeGroup == "")
!g:: {
  VSCode_StartGoChord()
}

!b:: {
  VSCode_StartBookmarksChord()
}

!t:: {
  VSCode_StartToggleChord()
}

!s:: {
  VSCode_StartSettingsChord()
}

!z:: {
  VSCode_StartFoldingChord()
}

!f:: {
  VSCode_StartFileChord()
}

!1:: {
  KeyWait('Alt')
  VSCode_RunCommand('claude-vscode.focus')
}

!2:: {
  KeyWait('Alt')
  VSCode_RunCommand('chatgpt.sidebarSecondaryView.focus')
}

^!x:: {
  VSCode_ShowContextProbe()
}

^+e:: { ; focus on folders view
  send('^+!e')
}

includeInContext(fileName, label) {
  sleep(100)
  send('>>>> Begin ' label '{Enter}')
  sleep(500)
  send('{Enter}')
  send('^p')
  Sleep(100)
  send(fileName)
  Sleep(100)
  send('{Enter}')
  Sleep(100)
  send('^a')
  Sleep(100)
  content := ctrlC()
  send('^p')
  Sleep(100)
  send('context.md')
  Sleep(100)
  send('{Enter}')
  Sleep(100)
  send('^v')
  Sleep(100)
  send('>>>> End ' label '{Enter}')
  Sleep(400)
}

; #!p:: {
;   KeyWait("Alt")
;   KeyWait("LWin")
;   send('^p%')
; }

:*:.c :: {
  Send('console.log(')
}
:*:clogc:: {
  Send("console.log(" . "' " . A_Clipboard . "',){left} " . A_Clipboard)
}

; #!r:: {
;   cm := CoordMode('Mouse', 'Screen')
;   mouseSaved := saveMouse()
;   KeyWait("Alt", 'T1')
;   KeyWait("LWin", 'T1')
;   KeyWait("r", 'T1')
;   try {
;     WinActivate("[Debug] or chrome-debug")
;   } catch Error as e {
;     MsgBox('Open debug browser')
;     return
;   }
;   WinGetPos(&x, &y, &width, &height, "A")
;   MouseClick('Middle', x + 300, y + 300, 1, 0)
;   Sleep(100)
;   Send("^l")
;   Sleep(200)
;   Send("{enter}")
;   Sleep(100)
;   WinActivate("ahk_exe " cursorExe)
;   CoordMode('Mouse', cm)
;   restoreMouse(mouseSaved)
; }

F1::
toggleLog(hk)
{
  global toggleCodeDebug
  toggleCodeDebug := !toggleCodeDebug
  if (toggleCodeDebug) {
    msgV1('Deb', 100000, 20, 1, 1)
  } else {
    ToolTip(, , , 20)
  }
}
#HotIf


; ***********************
; Hotstrings
; ***********************

; prompts
:*:.pr.step:: {
  Send('Ok, let`'s do it step by step, let`'s do the first one and when I finish it, I will ask you for the next one')
}
; end prompts

:*:.debug.:: {
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\{Enter}")
  Sleep(200)
  Send(".\Scripts\activate{Enter}")
  Sleep(200)
  Send("python -c `" import os; print(os.environ['VIRTUAL_ENV']) `" {Enter}")
  Sleep(500)
  Send('^1')
  Sleep(500)
  Send('^p')
  Sleep(500)
  Send('url.py')
  Sleep(500)
  Send('{enter}')
  Sleep(300)
  Send('{F5}')
  Sleep(500)
  Send('^1')
  Sleep(100)
  Send('^w')
}
:*:.watch.:: {
  SoundBeepWithVol
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\irc-directory-react-app\\{Enter}")
  Sleep(200)
  Send("npm run dev-watch{enter}")
  SoundBeepWithVol
  ToolTip(, , , 18)
}
:*:.cov.:: {
  SoundBeepWithVol
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\{Enter}")
  Sleep(200)
  Send(".\Scripts\activate{Enter}")
  Sleep(200)
  Send("python -c `" import os; print(os.environ['VIRTUAL_ENV']) `" {Enter}")
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src{Enter}")
  Send("coverage  run --source='.'  manage.py test --keepdb --no-input && coverage lcov && coverage html{Enter}")
}
:*:.run.:: {
  ToolTip('Wait, dont`t touch the keyboard/mouse', , , 18)
  SoundBeepWithVol
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\{Enter}")
  Sleep(200)
  Send(".\Scripts\activate{Enter}")
  Sleep(200)
  Send("python -c `" import os; print(os.environ['VIRTUAL_ENV']) `" {Enter}")
  Sleep(500)
  Send('^p')
  Sleep(200)
  Send('url.py')
  Sleep(100)
  Send('{enter}')
  Sleep(300)
  Send('{F5}')
  Sleep(500)
  Send('^1')
  Sleep(300)
  Send('^w')
  Sleep(1000)
  Send('^+``')
  Send('^{pgdn}')
  Sleep(100)
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\irc-directory-react-app\\{Enter}")
  Sleep(200)
  Send("npm run dev-watch{enter}")
  SoundBeepWithVol
  ToolTip(, , , 18)
}
:*:.runi.:: {
  Sleep(200)
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\{Enter}")
  Send("python manage.py shell_plus --ipython{Enter}")
  Sleep(1000)
  Send("^+``")
  Sleep(500)
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\irc-directory-react-app\\{Enter}")
  Sleep(200)
  Send("npm run dev-watch{enter}")
  Sleep(500)
  Send('^p')
  Sleep(200)
  Send('url.py')
  Sleep(100)
  Send('{enter}')
  Sleep(300)
  Send('{F5}')
  Sleep(500)
}
:*:.import.:: {
  Send("from django.forms.models import model_to_dict{Enter}")
  Sleep(200)
  Send("log=model_to_dict{Enter}")
}

:*:.debug.:: {
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\{Enter}")
  sleep(200)
  Send("python manage.py shell_plus --ipython{Enter}")
  Sleep(400)
  send("{enter}")
  Send("^l")
  Send("from django.forms.models import model_to_dict")
  Sleep(400)
  Send("{Enter}")
  Send("log=model_to_dict")
  Sleep(400)
  Send("{Enter}")
}
:*:.shell:: {
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\{Enter}")
  Send("python manage.py shell_plus --tpython{Enter}")
}
#HotIf

; ============================================================
;   VSCode Controller — http://127.0.0.1:7777
; ============================================================

; ── Helpers ──────────────────────────────────────────────────────────────────

global VSCode_BaseUrl := 'http://127.0.0.1:7777'
global VSCode_ControllerChordsInitialized := false

VSCode_Cmd(command, args := '[]') {
  if (Type(args) != 'String') {
    args := '[]'
  }
  body := '{"command":"' VSCode_JsonEscape(command) '","args":' args '}'
  return VSCode_Post('/command', body)
}

VSCode_Get(path) {
  return VSCode_Request('GET', path)
}

VSCode_Context() {
  return VSCode_Get('/context')
}

VSCode_ContextKeys(filter := '') {
  path := '/context-keys'
  if (filter != '') {
    path .= '?filter=' . filter
  }
  return VSCode_Get(path)
}

VSCode_Post(path, body := '') {
  return VSCode_Request('POST', path, body)
}

VSCode_Request(method, path, body := '') {
  if (SubStr(path, 1, 1) != '/') {
    path := '/' path
  }

  req := ComObject('WinHttp.WinHttpRequest.5.1')
  req.SetTimeouts(1000, 1000, 3000, 3000)
  req.Open(method, VSCode_BaseUrl path, false)

  if (method = 'POST') {
    req.SetRequestHeader('Content-Type', 'application/json')
  }

  req.Send(body)

  status := req.Status
  response := req.ResponseText
  if (status < 200 or status >= 300) {
    throw Error('VSCode Controller request failed (' status '): ' response)
  }

  return response
}

VSCode_Str(json, key) {
  pattern := '"' key '"\s*:\s*"((?:\\.|[^"\\])*)"'
  if RegExMatch(json, pattern, &m) {
    return VSCode_JsonUnescape(m[1])
  }
  return ''
}

VSCode_Num(json, key) {
  pattern := '"' key '"\s*:\s*(-?\d+(?:\.\d+)?)'
  if RegExMatch(json, pattern, &m) {
    return Number(m[1])
  }
  return ''
}

VSCode_Bool(json, key) {
  pattern := '"' key '"\s*:\s*(true|false|null)'
  if RegExMatch(json, pattern, &m) {
    if (m[1] = 'true') {
      return true
    }
    if (m[1] = 'false') {
      return false
    }
  }
  return ''
}

VSCode_KeyPressed(keyName) {
  return GetKeyState(keyName, 'P')
}

VSCode_BoolText(value) {
  if (value = true) {
    return 'true'
  }
  if (value = false) {
    return 'false'
  }
  return 'null'
}

VSCode_JsonEscape(text) {
  slash := Chr(92)
  text := StrReplace(text, slash, slash slash)
  text := StrReplace(text, '"', slash '"')
  text := StrReplace(text, '`r', slash 'r')
  text := StrReplace(text, '`n', slash 'n')
  text := StrReplace(text, '`t', slash 't')
  return text
}

VSCode_JsonUnescape(text) {
  slash := Chr(92)
  text := StrReplace(text, slash 'r', '`r')
  text := StrReplace(text, slash 'n', '`n')
  text := StrReplace(text, slash 't', '`t')
  text := StrReplace(text, slash '"', '"')
  text := StrReplace(text, slash slash, slash)
  return text
}

VSCodeChordHotIf(*) {
  global activeGroup
  try {
    return (WinActive("ahk_exe Code.exe") or WinActive("ahk_exe Cursor.exe")) and (activeGroup == "")
  } catch {
    return false
  }
}

VSCode_ShowTip(message, timeoutMs := 3000) {
  ToolTip(message, , , 5)
  SetTimer(() => ToolTip(, , , 5), -timeoutMs)
}

VSCode_ShowContextProbe() {
  title := WinGetTitle('A')
  altPressed := VSCode_KeyPressed('Alt')
  ctrlPressed := VSCode_KeyPressed('Ctrl')
  xPressed := VSCode_KeyPressed('x')

  try {
    raw := VSCode_Context()
    report := 'AHK Probe`n'
      . 'windowTitle=' . title . '`n'
      . 'altPressed=' . VSCode_BoolText(altPressed) . '`n'
      . 'ctrlPressed=' . VSCode_BoolText(ctrlPressed) . '`n'
      . 'xPressed=' . VSCode_BoolText(xPressed) . '`n`n'
      . 'VSCode /context`n'
      . raw
    A_Clipboard := report
    log('[vscode-context] probe | ' . report)
    MsgBox(report, 'VS Code Context Probe')
  } catch Error as err {
    message := 'No pude leer /context.`n'
      . 'windowTitle=' . title . '`n'
      . 'altPressed=' . VSCode_BoolText(altPressed) . '`n'
      . 'ctrlPressed=' . VSCode_BoolText(ctrlPressed) . '`n'
      . 'xPressed=' . VSCode_BoolText(xPressed) . '`n`n'
      . err.Message
    log({ isError: true }, '[vscode-context] probe error | ' . message)
    MsgBox(message, 'VS Code Context Probe Error')
  }
}

VSCodeChordDebugLogger(message) {
  log('[vscode-chord] ' . message)
}

VSCode_RunCommand(command, args := '[]') {
  log('[vscode-controller] command start | ' . command . ' | args=' . args)
  try {
    result := VSCode_Cmd(command, args)
    log('[vscode-controller] command ok | ' . command . ' | response=' . result)
    return result
  } catch Error as err {
    log('[vscode-controller] command error | ' . command . ' | ' . err.Message)
    VSCode_ShowTip('VSCode command failed: ' command, 4000)
    return ''
  }
}

VSCode_StartChord(prefixHotkey) {
  log('[vscode-chord] start prefix | ' . prefixHotkey)
  ChordHandlePrefix(prefixHotkey)
  log('[vscode-chord] end prefix | ' . prefixHotkey)
}

VSCode_StartGoChord() {
  KeyWait('Alt')
  log('[vscode-chord] Alt+G launcher fired')
  VSCode_StartChord('^!g')
}

VSCode_StartBookmarksChord() {
  KeyWait('Alt')
  log('[vscode-chord] Alt+B launcher fired')
  VSCode_StartChord('^!b')
}

VSCode_StartToggleChord() {
  KeyWait('Alt')
  log('[vscode-chord] Alt+T launcher fired')
  VSCode_StartChord('^!t')
}

VSCode_StartSettingsChord() {
  KeyWait('Alt')
  log('[vscode-chord] Alt+S launcher fired')
  VSCode_StartChord('^!s')
}

VSCode_StartFoldingChord() {
  KeyWait('Alt')
  log('[vscode-chord] Alt+Z launcher fired')
  VSCode_StartChord('^!z')
}

VSCode_StartFileChord() {
  KeyWait('Alt')
  log('[vscode-chord] Alt+F launcher fired')
  VSCode_StartChord('!f')
}

VSCode_RunCommandSequence(commandSpecs) {
  for _, spec in commandSpecs {
    if (Type(spec) = 'String') {
      VSCode_RunCommand(spec)
    } else if (IsObject(spec) && spec.HasOwnProp('command')) {
      VSCode_RunCommand(spec.command, spec.HasOwnProp('args') ? spec.args : '[]')
    }
  }
}

GetVSCodeGoChordOptions() {
  return {
    chordPrefixLabel: 'Alt+G',
    showDelaySeconds: 0.2,
    idleTimeoutSeconds: 14,
    items: [
      { key: 't', label: 'Focus Terminal', action: () => VSCode_RunCommand('terminal.focus') },
      { key: 'e', label: 'Focus Editor', action: () => VSCode_RunCommand('workbench.action.focusFirstEditorGroup') },
      { key: 'f', label: 'Focus Explorer', action: () => VSCode_RunCommand('workbench.explorer.fileView.focus') },
      { key: 's', label: 'Focus Source Control', action: () => VSCode_RunCommand('workbench.scm.focus') },
      { key: 'r', label: 'Focus Problems', action: () => VSCode_RunCommand('workbench.panel.markers.view.focus') },
      { key: 'g', label: 'Go to Line', action: () => VSCode_RunCommand('workbench.action.gotoLine') },
      { key: 'q', label: 'Quick Open View', action: () => VSCode_RunCommand('workbench.action.quickOpenView') },
      { key: 'w', label: 'Go Forward', action: () => VSCode_RunCommand('workbench.action.navigateForward') },
      { key: 'b', label: 'Go Back', action: () => VSCode_RunCommand('workbench.action.navigateBack') },
      { key: 'j', label: 'FindJump', items: [
        { key: 'j', label: 'Jump', action: () => VSCode_RunCommand('findJump.activate') },
        { key: 's', label: 'Jump With Selection', action: () => VSCode_RunCommand('findJump.activateWithSelection') },
      ] },
      { key: 'x', label: 'Codex', items: [
        { key: 's', label: 'Codex Chat', action: () => VSCode_RunCommand('chatgpt.sidebarSecondaryView.focus') },
        { key: 'w', label: 'New Codex Panel', action: () => VSCode_RunCommand('chatgpt.newCodexPanel') },
        { key: 'c', label: 'New Chat', action: () => VSCode_RunCommand('chatgpt.newChat') },
      ] },
      { key: 'a', label: 'Claude', items: [
        { key: 'f', label: 'Focus Claude Input', action: () => VSCode_RunCommand('claude-vscode.focus') },
      ] },
      { key: 'v', label: 'Copilot', items: [
        { key: 'c', label: 'Copilot Chat', action: () => VSCode_RunCommand('workbench.panel.chat.view.copilot.focus') },
        { key: 'w', label: 'New Chat', action: () => VSCode_RunCommand('workbench.action.chat.open') },
        { key: 't', label: 'Toggle Copilot', action: () => VSCode_RunCommand('github.copilot.toggleCopilot') },
      ] },
      { key: '1', label: 'Claude Chat', action: () => VSCode_RunCommand('claude-vscode.focus') },
      { key: '2', label: 'Codex Chat', action: () => VSCode_RunCommand('chatgpt.sidebarSecondaryView.focus') },
      { key: '3', label: 'Focus Claude Input', action: () => VSCode_RunCommand('claude-vscode.focus') },
    ]
  }
}

GetVSCodeBookmarksChordOptions() {
  return {
    chordPrefixLabel: 'Alt+B',
    showDelaySeconds: 0.2,
    idleTimeoutSeconds: 14,
    items: [
      { key: 't', label: 'Toggle Bookmark', action: () => VSCode_RunCommand('bookmarks.toggle') },
      { key: 'l', label: 'List Bookmarks', action: () => VSCode_RunCommand('bookmarks.list') },
      { key: 'a', label: 'List All Files', action: () => VSCode_RunCommand('bookmarks.listFromAllFiles') },
      { key: 'n', label: 'Toggle Labeled Bookmark', action: () => VSCode_RunCommand('bookmarks.toggleLabeled') },
    ]
  }
}

GetVSCodeReferencesChordOptions() {
  return {
    showDelaySeconds: 0.2,
    idleTimeoutSeconds: 14,
    items: [
      { key: 'r', label: 'Show References', action: () => VSCode_RunCommand('references-view.findReferences') },
      { key: 'i', label: 'Show Implementations', action: () => VSCode_RunCommand('references-view.findImplementations') },
      { key: 'b', label: 'Filtered References', action: () => VSCode_RunCommand('better-references.showFilteredReferences') },
      { key: 't', label: 'Peek Type Definition', action: () => VSCode_RunCommand('editor.action.peekTypeDefinition') },
      { key: 'x', label: 'Clear History', action: () => VSCode_RunCommand('references-view.clearHistory') },
    ]
  }
}

GetVSCodeToggleChordOptions() {
  return {
    chordPrefixLabel: 'Alt+T',
    showDelaySeconds: 0.2,
    idleTimeoutSeconds: 14,
    items: [
      { key: 'a', label: 'Toggle Primary Side Bar', action: () => VSCode_RunCommand('workbench.action.toggleSidebarVisibility') },
      { key: 'f', label: 'Toggle Secondary Side Bar', action: () => VSCode_RunCommand('workbench.action.toggleAuxiliaryBar') },
      { key: 'b', label: 'Toggle Both Side Bars', action: () => VSCode_RunCommandSequence([
        { command: 'workbench.action.toggleSidebarVisibility' },
        { command: 'workbench.action.toggleAuxiliaryBar' }
      ]) },
      { key: 't', label: 'Toggle Terminal', action: () => VSCode_RunCommand('workbench.action.terminal.toggleTerminal') },
      { key: 'q', label: 'Toggle Panel', action: () => VSCode_RunCommand('workbench.action.togglePanel') },
      { key: 'x', label: 'Toggle Maximize Panel', action: () => VSCode_RunCommand('workbench.action.toggleMaximizedPanel') },
      { key: 's', label: 'Toggle Maximize Secondary Side Bar', action: () => VSCode_RunCommand('workbench.action.toggleMaximizedAuxiliaryBar') },
      { key: 'w', label: 'Toggle Word Wrap', action: () => VSCode_RunCommand('editor.action.toggleWordWrap') },
      { key: 'c', label: 'Toggle Continue Console', action: () => VSCode_RunCommand('workbench.view.extension.continueConsole') },
      { key: 'r', label: 'Reopen With Editor', action: () => VSCode_RunCommand('workbench.action.reopenWithEditor') },
      { key: 'v', label: 'Markdown Preview', action: () => VSCode_RunCommand('markdown.showPreview') },
      { key: 'd', label: 'Markdown Double Click Switch', action: () => VSCode_RunCommand('vscode-settings-keybindings.setSetting', '[{"toggle":true,"key":"markdown.preview.doubleClickToSwitchToEditor","value":true,"toggleValue":false}]') },
    ]
  }
}

GetVSCodeFileChordOptions() {
  return {
    chordPrefixLabel: 'Alt+F',
    showDelaySeconds: 0.2,
    idleTimeoutSeconds: 14,
    items: [
      { key: 'n', label: 'New File', action: () => VSCode_RunCommand('filebunny.createFile') },
      { key: 't', label: 'New Untitled File', action: () => VSCode_RunCommand('workbench.action.files.newUntitledFile') },
      { key: 'a', label: 'Advanced New File', action: () => VSCode_RunCommand('extension.advancedNewFile') },
      { key: 'c', label: 'Compare With Clipboard', action: () => VSCode_RunCommand('workbench.files.action.compareWithClipboard') },
      { key: 'r', label: 'Copy Relative Path', action: () => VSCode_RunCommand('copyRelativeFilePath') },
      { key: 'w', label: 'Close All Editors', action: () => VSCode_RunCommand('workbench.action.closeAllEditors') },
    ]
  }
}

GetVSCodeFoldingChordOptions() {
  return {
    chordPrefixLabel: 'Alt+Z',
    showDelaySeconds: 0.2,
    idleTimeoutSeconds: 14,
    items: [
      { key: 'c', label: 'Fold Level At Cursor', action: () => VSCode_RunCommand('dakara-foldplus.levelAtCursor') },
      { key: 'f', label: 'Fold', action: () => VSCode_RunCommand('editor.fold') },
      { key: 'd', label: 'Unfold', action: () => VSCode_RunCommand('editor.unfold') },
      { key: 't', label: 'Toggle Fold', action: () => VSCode_RunCommand('editor.toggleFold') },
      { key: 'r', label: 'Fold Recursively', action: () => VSCode_RunCommand('editor.foldRecursively') },
      { key: 'e', label: 'Unfold Recursively', action: () => VSCode_RunCommand('editor.unfoldRecursively') },
    ]
  }
}

GetVSCodeSettingsChordOptions() {
  return {
    chordPrefixLabel: 'Alt+S',
    showDelaySeconds: 0.2,
    idleTimeoutSeconds: 14,
    items: [
      { key: 's', label: 'User Settings JSON', action: () => VSCode_RunCommand('workbench.action.openSettingsJson') },
      { key: 'p', label: 'Project Settings', action: () => VSCode_RunCommand('workbench.action.openWorkspaceSettingsFile') },
      { key: 'u', label: 'Settings UI', action: () => VSCode_RunCommand('workbench.action.openSettings2') },
      { key: 'a', label: 'Application Settings', action: () => VSCode_RunCommand('workbench.action.openApplicationSettingsJson') },
      { key: 'o', label: 'Open App + User + Project Settings', action: () => VSCode_RunCommandSequence([
        { command: 'workbench.action.openApplicationSettingsJson' },
        { command: 'workbench.action.keepEditor' },
        { command: 'workbench.action.openSettingsJson' },
        { command: 'workbench.action.keepEditor' },
        { command: 'workbench.action.openWorkspaceSettingsFile' },
        { command: 'workbench.action.keepEditor' }
      ]) },
      { key: 'f', label: 'Folder Settings', action: () => VSCode_RunCommand('workbench.action.openFolderSettingsFile') },
      { key: 'k', label: 'Keyboard Shortcuts JSON', action: () => VSCode_RunCommand('workbench.action.openGlobalKeybindingsFile') },
      { key: 'i', label: 'Keyboard Shortcuts UI', action: () => VSCode_RunCommand('workbench.action.openGlobalKeybindings') },
    ]
  }
}

InitVSCodeControllerChords() {
  global VSCode_ControllerChordsInitialized

  if (VSCode_ControllerChordsInitialized) {
    log('[vscode-chord] init skipped')
    return
  }

  ChordSetDebugLogger(VSCodeChordDebugLogger)
  HotIf(VSCodeChordHotIf)
  MenuWhichKeyRegisterWithActions('^!g', GetVSCodeGoChordOptions())
  MenuWhichKeyRegisterWithActions('^!b', GetVSCodeBookmarksChordOptions())
  MenuWhichKeyRegisterWithActions('^!c', GetVSCodeReferencesChordOptions())
  MenuWhichKeyRegisterWithActions('^!t', GetVSCodeToggleChordOptions())
  MenuWhichKeyRegisterWithActions('!f', GetVSCodeFileChordOptions())
  MenuWhichKeyRegisterWithActions('^!z', GetVSCodeFoldingChordOptions())
  MenuWhichKeyRegisterWithActions('^!s', GetVSCodeSettingsChordOptions())
  HotIf()

  VSCode_ControllerChordsInitialized := true
  log('[vscode-chord] init complete | prefixes=^!g,^!b,^!c,^!t,!f,^!z,^!s')
}


; ── Hotkeys (VSCode/Cursor focused) ──────────────────────────────────────────

#HotIf (WinActive("ahk_exe Code.exe") or WinActive("ahk_exe Cursor.exe")) and (activeGroup == "")

#HotIf

; ── Hotkeys (VSCode/Cursor running anywhere) ─────────────────────────────────

#HotIf WinExist("ahk_exe Code.exe") or WinExist("ahk_exe Cursor.exe")

#HotIf

;*********************************
;   End vscode
;*************************************
