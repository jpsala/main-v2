; Ensure the script exits cleanly when terminated
OnExit exitScript
; Global variables for storing various states and configurations
global storedVolume := "", mouseX := 0, mouseY := 0, mode := 0, monitorInfo := {x: 0, y: 0, width: 0, height: 0}
global activeTradeWin := 'xxxx', tvWin := '', fxWin := '', lastBrowserTitle := "" , time := '', TimeGui1 := 0, TimeGui2 := 0

; Load persistent window alias mappings from config.ini for Roa() function
; Enables alias-based window management (e.g., "code" -> specific VS Code window)
LoadAliasMap()

initStarted := true

savedID := ""
saveVol := ""
A_Clipboard := A_ComputerName
; Flags to identify the current machine type
isNotebook := A_ComputerName == 'ZENBOOK' ? true : false
isRemote := A_ComputerName == 'CIDEV06' ? true : false
isGordos := A_ComputerName == 'gordos' ? true : false
isWork := A_ComputerName == 'AR-IT31927' ? true : false
isCarnival := A_ComputerName == 'avdp-1310' ? true : false

activeGroup := ""

altProfile := "" 
; Toggle variables
logVisibility := false
toggleCodeDebug := false
toggleChromeDebug := false
toggleObsidanDebug := false
windowUnderMouseID := 0
winProcessNameUnderMouse := ''
winTitleUnderMouse := ''

; Determine the device section in the configuration file based on the machine type
deviceSection := isGordos ? "gordos" : (isNotebook ? "notebook" : !isWork ? "desktop" : "work")
deviceSection := isCarnival ? "carnival" : deviceSection
; Read paths from the configuration file for the current device section
whatsappExe := IniRead("config.ini", deviceSection, "whatsapp_path", "")
cursorExe := IniRead("config.ini", deviceSection, "cursor_path", "")
vscodeExe := IniRead("config.ini", deviceSection, "vscode_path", "")
vivaldiExe := IniRead("config.ini", deviceSection, "vivaldi_path", "")
vivaldiLocalExe := IniRead("config.ini", deviceSection, "vivaldi_local_path", "")
chromeExe := IniRead("config.ini", deviceSection, "chrome_path", "")
zenExe := IniRead("config.ini", deviceSection, "zen_path", "")
xyplorerExe := IniRead("config.ini", deviceSection, "xyplorer_path", "")
strokesplusExe := IniRead("config.ini", deviceSection, "strokesplus_exe", "")
strokesplusDir := IniRead("config.ini", deviceSection, "strokesplus_dir", "")


; Validate that all paths were found
if (!whatsappExe || !cursorExe || !vscodeExe || !vivaldiExe || !vivaldiLocalExe || !chromeExe || !zenExe || !xyplorerExe || !strokesplusExe || !strokesplusDir) {
    MsgBox("Error: Missing required paths in config.ini for " . deviceSection . " section")
    ExitApp(1)
}

; Remove any trailing spaces from paths
whatsappExe := Trim(whatsappExe)
cursorExe := Trim(cursorExe)
vscodeExe := Trim(vscodeExe)
vivaldiExe := Trim(vivaldiExe)
vivaldiLocalExe := Trim(vivaldiLocalExe)
chromeExe := Trim(chromeExe)
zenExe := Trim(zenExe)
xyplorerExe := Trim(xyplorerExe)
strokesplusExe := Trim(strokesplusExe)
strokesplusDir := Trim(strokesplusDir)

vivaldiWithMainProfile := vivaldiExe ' --profile-directory="Profile 1" '
vivaldiWithCarnivalProfile := vivaldiExe ' --user-data-dir="C:\tools\vivaldi\User Data" --profile-directory="Carnival" '
vivaldiWithYoutubeProfile := vivaldiExe ' --user-data-dir="C:\tools\vivaldi\User Data" --profile-directory="Youtube" '
vivaldiAltWithMainProfile := vivaldiExe ' --profile-directory="Main.alt" '
vivaldiWithGeminProfile := vivaldiExe ' --profile-directory="Gemin"'
vivaldiWithAIProfile := vivaldiExe ' --user-data-dir="C:\tools\vivaldi\User Data" --profile-directory="AI" '
vivaldiWithTradingProfile := vivaldiExe ' --profile-directory="Trading" '
vivaldiWithGordosProfile := vivaldiExe ' --profile-directory="Gordos" '
chromeWithWorkProfile := chromeExe ' --user-data-dir="C:\tools\chrome\User Data" --profile-directory="Work" '
vivaldiWithBooksProfile := vivaldiExe ' --user-data-dir=d:\vivaldi-profiles --profile-directory="Books" '

vivaldiLocalWithMainProfile := vivaldiLocalExe ' --profile-directory="Main" '
vivaldiLocalWithAIProfile := vivaldiLocalExe ' --profile-directory="AI" '
vivaldiLocalWithGordosProfile := vivaldiLocalExe ' --profile-directory="Gordos" '

chromeWithDebugProfile := chromeExe ' --profile-directory="Profile 3" --user-data-dir="c:\chrome-debug" --flag-switches-begin --flag-switches-end --origin-trial-disabled-features=CanvasTextNg|WebAssemblyCustomDescriptors'
; chromeWithDebugProfile := chromeExe ' --profile-directory="Profile 3" --remote-debugging-port=9222 --no-first-run --user-data-dir="c:\chrome-debug" --flag-switches-begin --flag-switches-end --origin-trial-disabled-features=CanvasTextNg|WebAssemblyCustomDescriptors'
vivaldiWithDebugProfile := vivaldiExe ' --profile-directory="Debug" --remote-debugging-port=9222 --no-first-run' ; --disable-features=BlockInsecurePrivateNetworkRequests
;"C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --user-data-dir=C:\chrome-debug --no-first-run

browserWindow := "ahk_exe vivaldi.exe ahk_exe chrome.exe ahk_exe msedge.exe ahk_exe firefox.exe ahk_exe brave.exe"


; browserWithMainLocalProfile := vivaldiLocalWithMainProfile
; browserWithAILocalProfile := vivaldiLocalWithAIProfile
; ; Vivaldi end

; ; browser paths
; browserWithMainProfile := vivaldiWithMainProfile
; browserWithAIProfile := vivaldiWithAIProfile
; browserWithTradingProfile := vivaldiWithTradingProfile

; browserWithChatGptProfile := zenAppPath '-p AI '
; vivaldiWithChatGptProfile := zenAppPath '-p AI '
; browserWithJPProfile := zenAppPath ' -p Personal '

; browserWithVideosProfile := zenAppPath ' --profile-directory="Videos.profile" '
; browserWithDebugProfile := zenAppPath ' --remote-debugging-port=9222  -p Debug" '
; browserWithDevProfile := chromeAppPath ' --remote-debugging-port=9222 --profile-directory=Debug'
browserWithChromeMainProfile := chromeExe ' --profile-directory="Profile 1" '

; browserWithAIProfile := zenAppPath ' -p AI '
; browserWithWorkProfile := zenAppPath ' -p Work '

; browserWithAmaiaProfile := chromeAppPath ' --profile-directory="Profile 2" '

; A_Clipboard := browserWithVideosProfile
; browserWithTradingProfile := zenAppPath ' --profile-directory=Trading '

Global filesToCheckForReload := [
  ; {path: A_ScriptFullPath, lastModVar: FileGetTime(A_ScriptFullPath, "M")},
  {path: './main.ahk', lastModVar: FileGetTime('./main.ahk', "M")},
  {path: './msg.ahk', lastModVar: FileGetTime('./msg.ahk', "M")},
  {path: './functions.ahk', lastModVar: FileGetTime('./functions.ahk', "M")},
  {path: './init.ahk', lastModVar: FileGetTime('./init.ahk', "M")},
  {path: './bookmarks.ahk', lastModVar: FileGetTime('./bookmarks.ahk', "M")},
  {path: './menus.ahk', lastModVar: FileGetTime('./menus.ahk', "M")},
  {path: './code.ahk', lastModVar: FileGetTime('./code.ahk', "M")},
  {path: './hotstrings.ahk', lastModVar: FileGetTime('./hotstrings.ahk', "M")},
  {path: './system.ahk', lastModVar: FileGetTime('./system.ahk', "M")},
  {path: './chrome.ahk', lastModVar: FileGetTime('./chrome.ahk', "M")},
  {path: './ai.ahk', lastModVar: FileGetTime('./ai.ahk', "M")},
  {path: './ai-picker.ahk', lastModVar: FileGetTime('./ai-picker.ahk', "M")},
  {path: './ai-webui.ahk', lastModVar: FileGetTime('./ai-webui.ahk', "M")},
  {path: './lib/chord-hotkeys.ahk', lastModVar: FileGetTime('./lib/chord-hotkeys.ahk', "M")},
  {path: './hotkeys-global.ahk', lastModVar: FileGetTime('./hotkeys-global.ahk', "M")},
  {path: './roa.ahk', lastModVar: FileGetTime('./roa.ahk', "M")},
  {path: './menu.ahk', lastModVar: FileGetTime('./menu.ahk', "M")},
]
emptylog()
onceADay()



msg('init.ahk loaded', { seconds: 2, X: 10, Y: 10 })
if (ProcessExist('StrokesPlus.net.exe') == 0 and !isWork and !isCarnival) {
  Run(strokesplusExe, strokesplusDir)
}


; ***********************************************
; init some global variables from ini file
; ***********************************************
global cursorKeysEnabled := false
variablesToPersist := ['cursorKeysEnabled', 'logVisibility']
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

; Run low priority tasks every second
SetTimer(CheckTimeForFileModification,1000)

; let make some noise when the script is loaded

volumeGui := Gui(,'volumeGui ')
volumeGui.BackColor := "Black"
volumeGui.Opt("-Caption	+AlwaysOnTop -SysMenu +ToolWindow ")
volumeGui.Add("progress", "w50 h10 vMyProgress c8d8793", 0) 

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
