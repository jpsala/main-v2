; ===================================================================
; XYPLORER HOTKEYS
; ===================================================================
;#x::RoAWithPattern('ahk_exe XYplorer.exe', xyplorerExe)

#HotIf WinActive('ahk_exe XYplorer.exe')

!f:: {
  options := {
    waitml: 500,
    items: [
      { key: "s", label: "Sort by ...", 
        submenu: [
          { key: "f", label: "Sort by size asc"}
        ]
      },
      { key: "t", label: "Toggle Visual Filter"},
      { 
        key: "f", 
        label: "Filters", 
        submenu: [
          { key: "f", label: "Filter .mq5 with magic numbers" }, 
          { key: "v", label: "Toggle Visual Filter" }
        ] 
      }, 
      { 
        key: "s", 
        label: "Filter Selection", 
        submenu: [
          { key: "m", label: "Filter .mq5 with magic numbers" }, 
          { key: "e", label: "Filter .ex5 with magic numbers" }
        ] 
      }
    ]
  }
  
  key := customMenu(options)
  if (key == 't') {
    macro('::' 
      'focus("P1"); // Make sure Pane 1 is focused' 
      'tab("new");  // Create a new, empty tab in the focused pane (P2)' 
      '// Now in the new tab in P2' 
      'goto("D:\SQX\Projects", 1); // Navigate this new tab to the second path' 
      'focus("P2"); // Switch focus to Pane 2' 
      'tab("new");  // Create a new, empty tab in the focused pane (P1)' 
      '// No need to explicitly specify P1 again, we are already in the new tab in P1'
      'goto("D:\SQX\136\user\projects", 1); // Navigate the new tab (now current) to the path')
  }
  ; Handle Filters submenu
  if (key == 'ff') {
    send('^j')
    Sleep(200)
    send('{Text}>^.*\d{5,}\.mq5$')
    send('{enter}')
  }
  if (key == 'sf') {
    macro('::#250;#487;sortby("Size", "a", "Name:d");#251')
  }
  if (key == 'fv') {
    send('^+j')
  }
  
  ; Handle Filter Selection submenu
  if (key == "sm") {
    send('^m')
    Sleep(200)
    send('{Text}>^.*\d{5,}\.mq5$')
    send('{enter}')
  }
  if (key == "se") {
    send('^m')
    Sleep(200)
    send('{Text}>^.*\d{5,}\.ex5$')
    send('{enter}')
  }
}

#!x:: {
  options := {
    waitml: 1000,
    items: [
      { key: "d", label: "Desktop" }, 
      { key: "v", label: "Dev" }, 
      { key: "c", label: "Color Filters" }
    ]
  }
  
  key := customMenu(options)
  
  if (key == "d") {
    run(xyploreExe " /script=`"::goto 'Desktop'; sortby 'm', 'd'; sel 3; focus 'List'`"")
  }
  if (key == "v") {
    run(
      xyploreExe
      " /script=`"::goto 'c:\dev\work\newcomers\app\backend'; "
      "sortby 'm', 'd'; "
      "sel 3; "
      "focus 'List'`""
    )
  }
  if (key == "c") {
    run(xyploreExe " /script=`"::#629;`"")
  }
}

#HotIf

macro(str) {
  KeyWait('alt')
  send('^l')
  Sleep(20)
  SendText(str)
  send('{enter}')
  send('^l')
  send('{esc}')
  send('{tab}')
  Sleep(300)
  send('{space}')
  ; Sleep(100)
}