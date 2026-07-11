; Load centralized global variables
#Include 'lib\globals.ahk'
#Include 'lib\path-validator.ahk'

; Ensure the script exits cleanly when terminated
OnExit exitScript

; Load persistent window alias mappings from config.ini for Roa() function
; Enables alias-based window management (e.g., "code" -> specific VS Code window)
LoadAliasMap()

;===============================================================================
; PATH VALIDATION & AUTO-DETECTION
; Validates paths from config.ini, auto-detects common locations,
; and handles missing paths gracefully
;===============================================================================

; OPTIONAL APPLICATION PATHS (script works without these, features disabled)
whatsappExe     := ValidatePath(deviceSection, "whatsapp_path", "WhatsApp", false)
cursorExe       := ValidatePath(deviceSection, "cursor_path", "Cursor", false, GetCommonPaths("cursor"))
vscodeExe       := ValidatePath(deviceSection, "vscode_path", "VS Code", false, GetCommonPaths("vscode"))
vivaldiExe      := ValidatePath(deviceSection, "vivaldi_path", "Vivaldi", false, GetCommonPaths("vivaldi"))
vivaldiLocalExe := ValidatePath(deviceSection, "vivaldi_local_path", "Vivaldi (local)", false)
chromeExe       := ValidatePath(deviceSection, "chrome_path", "Chrome", false, GetCommonPaths("chrome"))
zenExe          := ValidatePath(deviceSection, "zen_path", "Zen Browser", false)
xyplorerExe     := ValidatePath(deviceSection, "xyplorer_path", "XYplorer", false, GetCommonPaths("xyplorer"))
strokesplusExe  := ValidatePath(deviceSection, "strokesplus_exe", "StrokesPlus", false)
strokesplusDir  := ValidatePath(deviceSection, "strokesplus_dir", "StrokesPlus (folder)", false)

; CRITICAL TOOLS (optional but recommended)
nircmdExe := ValidatePath("desktop", "nircmd_exe", "NirCmd", false, GetCommonPaths("nircmd"))
if (nircmdExe) {
    ; Update config cache if auto-detected
    IniWrite(nircmdExe, "config.ini", "desktop", "nircmd_exe")
}

; Show summary of missing paths if any
ShowMissingPathsSummary()

;===============================================================================
; BROWSER PROFILES (loaded from config.ini)
; Profile configurations loaded from [vivaldi-profiles], [chrome-profiles],
; [vivaldi-local-profiles] sections. Seeded with defaults on first run.
;===============================================================================

SeedDefaultProfiles()

; Vivaldi profiles
vivaldiWithMainProfile := EnsureRemoteDebuggingPort(BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "main"), 9333)
vivaldiWithCarnivalProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "carnival")
vivaldiWithYoutubeProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "youtube")
vivaldiAltWithMainProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "mainalt")
vivaldiWithGeminProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "gemin")
vivaldiWithAIProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "ai")
vivaldiWithTradingProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "trading")
vivaldiWithGordosProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "gordos")
vivaldiWithBooksProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "books")
vivaldiWithDebugProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "debug")
vivaldiWithJpsalaAiProfile  := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "jpsala-ai")
vivaldiWithJpsalaWorkProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "jpsala-work")
vivaldiWithJpsalaAltProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "jpsala-alt")
vivaldiWithJpsalaDevProfile := BuildProfileCmd(vivaldiExe, "vivaldi-profiles", "jpsala-dev")

; Chrome profiles
chromeWithWorkProfile := BuildProfileCmd(chromeExe, "chrome-profiles", "work")
chromeWithDebugProfile := BuildProfileCmd(chromeExe, "chrome-profiles", "debug")
browserWithChromeMainProfile := BuildProfileCmd(chromeExe, "chrome-profiles", "main")

; Vivaldi Local profiles
vivaldiLocalWithMainProfile := BuildProfileCmd(vivaldiLocalExe, "vivaldi-local-profiles", "main")
vivaldiLocalWithAIProfile := BuildProfileCmd(vivaldiLocalExe, "vivaldi-local-profiles", "ai")
vivaldiLocalWithGordosProfile := BuildProfileCmd(vivaldiLocalExe, "vivaldi-local-profiles", "gordos")

browserWindow := "ahk_exe vivaldi.exe ahk_exe chrome.exe ahk_exe msedge.exe ahk_exe firefox.exe ahk_exe brave.exe"

; Check if all paths in config.ini exist
CheckConfigPaths(deviceSection)

; Hot-reload feature (development only)
if (!A_IsCompiled) {
  Global filesToCheckForReload := [
    {path: './main.ahk', lastModVar: FileGetTime('./main.ahk', "M")},
    {path: './msg.ahk', lastModVar: FileGetTime('./msg.ahk', "M")},
    {path: './functions.ahk', lastModVar: FileGetTime('./functions.ahk', "M")},
    {path: './init.ahk', lastModVar: FileGetTime('./init.ahk', "M")},
    {path: './bookmarks.ahk', lastModVar: FileGetTime('./bookmarks.ahk', "M")},
    {path: './menu-actions.ahk', lastModVar: FileGetTime('./menu-actions.ahk', "M")},
    {path: './copy-q.ahk', lastModVar: FileGetTime('./copy-q.ahk', "M")},
    {path: './menus.ahk', lastModVar: FileGetTime('./menus.ahk', "M")},
    {path: './menus-whichkey.ahk', lastModVar: FileGetTime('./menus-whichkey.ahk', "M")},
    {path: './code.ahk', lastModVar: FileGetTime('./code.ahk', "M")},
    {path: './settings-window.ahk', lastModVar: FileGetTime('./settings-window.ahk', "M")},
    {path: './web-clipboard-host.ahk', lastModVar: FileGetTime('./web-clipboard-host.ahk', "M")},
    {path: './hotstrings.ahk', lastModVar: FileGetTime('./hotstrings.ahk', "M")},
    {path: './system.ahk', lastModVar: FileGetTime('./system.ahk', "M")},
    {path: './chrome.ahk', lastModVar: FileGetTime('./chrome.ahk', "M")},
    {path: './mouse-gestures.ahk', lastModVar: FileGetTime('./mouse-gestures.ahk', "M")},
    {path: './mouse-gestures-wizard.ahk', lastModVar: FileGetTime('./mouse-gestures-wizard.ahk', "M")},
    {path: './mouse-gestures-conditions.ahk', lastModVar: FileGetTime('./mouse-gestures-conditions.ahk', "M")},
    {path: './lib/chord-hotkeys.ahk', lastModVar: FileGetTime('./lib/chord-hotkeys.ahk', "M")},
    {path: './lib/webview-window-state.ahk', lastModVar: FileGetTime('./lib/webview-window-state.ahk', "M")},
    {path: './lib/audio.ahk', lastModVar: FileGetTime('./lib/audio.ahk', "M")},
    {path: './hotkeys-global.ahk', lastModVar: FileGetTime('./hotkeys-global.ahk', "M")},
    {path: './chord-examples.ahk', lastModVar: FileGetTime('./chord-examples.ahk', "M")},
    {path: './ui/chord-hint.html', lastModVar: FileGetTime('./ui/chord-hint.html', "M")},
    {path: './ui/settings.html', lastModVar: FileGetTime('./ui/settings.html', "M")},
    {path: './ui/audio-devices.html', lastModVar: FileGetTime('./ui/audio-devices.html', "M")},
    {path: './ui/web-clipboard-compose.html', lastModVar: FileGetTime('./ui/web-clipboard-compose.html', "M")},
    {path: './ui/menu.html', lastModVar: FileGetTime('./ui/menu.html', "M")},
    {path: './ui/command-palette.html', lastModVar: FileGetTime('./ui/command-palette.html', "M")},
    {path: './roa.ahk', lastModVar: FileGetTime('./roa.ahk', "M")},
    {path: './menu.ahk', lastModVar: FileGetTime('./menu.ahk', "M")},
    {path: './menu-webview.ahk', lastModVar: FileGetTime('./menu-webview.ahk', "M")},
    {path: './command-palette.ahk', lastModVar: FileGetTime('./command-palette.ahk', "M")},
    {path: './command-palette-catalog.ahk', lastModVar: FileGetTime('./command-palette-catalog.ahk', "M")},
    {path: './tray-menu.ahk', lastModVar: FileGetTime('./tray-menu.ahk', "M")},
  ]
}
emptylog()



msg('init.ahk loaded', { seconds: 2, X: 10, Y: 10 })
if (ProcessExist('StrokesPlus.net.exe') == 0 and !isWork and !isCarnival) {
  Run(strokesplusExe, strokesplusDir)
}


; ***********************************************
; init some global variables from ini file
; ***********************************************
global cursorKeysEnabled := false
global terminalShiftVPasteEnabled := false
variablesToPersist := ['cursorKeysEnabled', 'logVisibility', 'terminalShiftVPasteEnabled']
for variable in variablesToPersist {
   try {
      if (InStr(variable, ".")) {
         ; Handle nested object properties
         parts := StrSplit(variable, ".")
         parentVar := parts[1]
         childProp := parts[2]

         if (IsSet(%parentVar%) && %parentVar%.HasProp(childProp)) {
            value := IniRead("config.ini", "variables", variable, "")
            if (value == "true") {
               %parentVar%[childProp] := true
            } else if (value == "false") {
               %parentVar%[childProp] := false
            } else if (value != "") {
               %parentVar%[childProp] := value
            }
         }
      } else {
         value := IniRead("config.ini", "variables", variable, "")
         if (value != "")
            %variable% := value
      }
   } catch Error as e {
      log("Error loading variable " variable ": " e.Message)
   }
}

; ***********************************************

exitScript(exireason, exitcode){
  CurrentDate := FormatTime(A_Now, "yyyy-MM-dd")
  IniWrite(CurrentDate, "config.ini", "general", 'lastDate')
  msg('exiting script, saving variables')
  for variable in variablesToPersist {
    try {
      if (InStr(variable, ".")) {
        ; Handle nested object properties
        parts := StrSplit(variable, ".")
        parentVar := parts[1]
        childProp := parts[2]

        if (IsSet(%parentVar%) && %parentVar%.HasProp(childProp)) {
          IniWrite(%parentVar%[childProp], "config.ini", "variables", variable)
        }
      } else {
        IniWrite(%variable%, "config.ini", "variables", variable)
      }
    } catch Error as e {
      log("Error saving variable " variable ": " e.Message)
    }
  }
}

monitorInfo := getMonitorInfo()

; setting timers

; Run low priority tasks every 5 seconds (optimized from 1s to reduce disk I/O) - development only
if (!A_IsCompiled) {
  SetTimer(CheckTimeForFileModification, 5000)
}

; let make some noise when the script is loaded


if(isGordos) {
  SetTimer(chequearLaHoraParaElBrillo, 60000*5)
}

CheckTimeForFileModification() {
  for index, file in filesToCheckForReload
  {
      currentModTime := FileGetTime(file.path, "M")
      if (currentModTime != file.lastModVar)
      {
        soundHigh('50%', 1, 100)
        Reload()
        msgV1("Script error and in pause, fix it and press alt+shift+r", 1, 10, 1, 1)
        Pause()
      }
      filesToCheckForReload[index].lastModVar := currentModTime ; update the lastModVar directly
  }
}

chequearLaHoraParaElBrillo() {
  CurrentHour := Number(FormatTime(A_Now, "HH"))
  if (CurrentHour >= 20 || CurrentHour < 5) {
      Send('{F12}')
  }
}


soundHigh('50%', 1, 100)
msg("Loaded...", {seconds: .3})

;===============================================================================
; BROWSER PROFILE FUNCTIONS
;===============================================================================

BuildProfileCmd(exePath, section, key) {
  if (!exePath)
    return ""
  value := IniRead("config.ini", section, key, "")
  if (!value)
    return ""

  pipeParts := StrSplit(value, "|")
  profileDir := pipeParts[1]
  userDataDir := pipeParts.Length >= 2 ? pipeParts[2] : ""
  extraFlags := pipeParts.Length >= 3 ? pipeParts[3] : ""

  if (userDataDir)
    userDataDir := ExpandEnvVars(userDataDir)

  ; Backward compatibility: old main Vivaldi setup uses explicit Main profile
  ; and dedicated user-data-dir under C:\tools\vivaldi\main\User Data.
  if (section = "vivaldi-profiles" && key = "main" && profileDir = "Profile 1" && !userDataDir) {
    profileDir := "Main"
    userDataDir := "C:\tools\vivaldi\main\User Data"
  }

  ; These launchers must never expose a remote debugging port, even if config.ini
  ; still contains an older flag.
  if (section = "chrome-profiles" && key = "debug") {
    extraFlags := StripRemoteDebuggingPort(extraFlags)
  }

  if (!profileDir)
    return ""

  cmd := exePath
  if (userDataDir)
    cmd .= ' --user-data-dir="' . userDataDir . '"'
  cmd .= ' --profile-directory="' . profileDir . '"'
  if (extraFlags)
    cmd .= ' ' . extraFlags
  return cmd . ' '
}

StripRemoteDebuggingPort(flags) {
  if (!flags)
    return ""
  cleaned := RegExReplace(flags, "\s*--remote-debugging-port=\d+")
  return Trim(cleaned)
}

EnsureRemoteDebuggingPort(cmd, port) {
  if (!cmd)
    return ""
  if RegExMatch(cmd, "--remote-debugging-port=\d+")
    return cmd
  return RTrim(cmd) . " --remote-debugging-port=" . port . " "
}

SeedDefaultProfiles() {
  vivaldiUserDataDir := EnvGet("LOCALAPPDATA") . "\Vivaldi\User Data"
  chromeUserDataDir := EnvGet("LOCALAPPDATA") . "\Google\Chrome\User Data"
  chromeDebugUserDataDir := EnvGet("LOCALAPPDATA") . "\Chrome Debug"
  userProfileDir := EnvGet("USERPROFILE")
  booksProfileDir := userProfileDir ? userProfileDir . "\vivaldi-profiles" : ""

  if (IniRead("config.ini", "vivaldi-profiles",, "") = "") {
    defaults := Map(
      "main", "Profile 1||",
      "carnival", "Carnival|" . vivaldiUserDataDir . "|",
      "youtube", "Youtube|" . vivaldiUserDataDir . "|",
      "mainalt", "Main.alt||",
      "gemin", "Gemin||",
      "ai", "AI|" . vivaldiUserDataDir . "|",
      "trading", "Trading||",
      "gordos", "Gordos||",
      "books", "Books|" . booksProfileDir . "|",
      "debug", "Debug||--no-first-run"
    )
    for k, v in defaults
      IniWrite(v, "config.ini", "vivaldi-profiles", k)
  }
  if (IniRead("config.ini", "chrome-profiles",, "") = "") {
    defaults := Map(
      "work", "Work|" . chromeUserDataDir . "|",
      "debug", "Profile 3|" . chromeDebugUserDataDir . "|--flag-switches-begin --flag-switches-end --origin-trial-disabled-features=CanvasTextNg|WebAssemblyCustomDescriptors",
      "main", "Profile 1||"
    )
    for k, v in defaults
      IniWrite(v, "config.ini", "chrome-profiles", k)
  }
  if (IniRead("config.ini", "vivaldi-local-profiles",, "") = "") {
    defaults := Map("main", "Main||", "ai", "AI||", "gordos", "Gordos||")
    for k, v in defaults
      IniWrite(v, "config.ini", "vivaldi-local-profiles", k)
  }
}

GetAllProfiles(section) {
  sectionData := IniRead("config.ini", section,, "")
  if (sectionData = "")
    return []
  result := []
  lines := StrSplit(sectionData, "`n")
  for line in lines {
    parts := StrSplit(line, "=")
    if (parts.Length < 2)
      continue
    key := parts[1]
    value := parts[2]
    pipeParts := StrSplit(value, "|")
    profileDir := pipeParts[1]
    userDataDir := pipeParts.Length >= 2 ? pipeParts[2] : ""
    extraFlags := pipeParts.Length >= 3 ? pipeParts[3] : ""
    result.Push(Map("key", key, "profileDir", profileDir, "userDataDir", userDataDir, "extraFlags", extraFlags))
  }
  return result
}

UpdateProfile(section, key, profileDir, userDataDir, extraFlags) {
  IniWrite(profileDir . "|" . userDataDir . "|" . extraFlags, "config.ini", section, key)
}

RemoveProfile(section, key) {
  IniDelete("config.ini", section, key)
}

DetectBrowserProfiles(browser) {
  localAppData := EnvGet("LOCALAPPDATA")
  if (browser = "vivaldi")
    userDataDir := localAppData . "\Vivaldi\User Data"
  else if (browser = "chrome")
    userDataDir := localAppData . "\Google\Chrome\User Data"
  else
    return []

  if (!DirExist(userDataDir))
    return []

  result := []
  loop files, userDataDir . "\*", "D" {
    prefsFile := A_LoopFilePath . "\Preferences"
    if (FileExist(prefsFile)) {
      dirName := A_LoopFileName
      ; Skip internal dirs
      if (dirName = "System Profile" || dirName = "Guest Profile")
        continue
      result.Push(Map("dirName", dirName, "path", A_LoopFilePath))
    }
  }
  return result
}
