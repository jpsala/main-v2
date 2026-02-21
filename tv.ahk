#Requires AutoHotkey v2.0
OnExit exitTv
initTV()
; ****************************
; for mt4/mt4
; ****************************
#hotif (MouseIsOver('ahk_exe terminal64.exe') or MouseIsOver('ahk_exe terminal.exe'))
  +F8:: {
    Send('{F8}')
    ImageSearch(&X, &Y, 0, 0, 3800, 3800, 'mt5_common.png')
    if (X) {
      MouseClick('Left', X, Y)
    }
    send('{Tab 7}')
    send('3')
    send('{Tab}')
    send('1')
    send('{Enter}')
  }
  XButton2:: {
    MouseClick('Left')
    Sleep(100)
    send('+i')
  }
  ^c:: {
    ; KeyWait("Alt")
    Sleep(300)
    send('+i')
    Sleep(1000)
    ImageSearch(&X, &Y, 1730, 800, 1980, 1800, 'position.png')
    if (X) {
      soundOk()
      msgV1('Position set')
    } else {
      send('+i')
    }
  }
  !b:: {
    ImageSearch(&X, &Y, 1730, 800, 1980, 1800, 'position.png')
    msg(X, Y)
  }
  !c:: {
    global ep, tp, sl
    KeyWait("Alt")
    KeyWait("c")
    MouseClick("left")
    ep := CtrlC()
    Sleep(100)
    MouseClick("left", 0, 23, 1, 0, , 'R')
    Sleep(100)
    sl := CtrlC()
    MouseClick("left", 0, 23, 1, 0, , 'R')
    ; send('{tab}')
    Sleep(100)
    tp := CtrlC()
    msgV1(ep ' ' sl ' ' tp ' Copied to ep, sl, tp')
  }
  !r:: {
    KeyWait("Ctrl")
    KeyWait("Alt")
    KeyWait("t")
    Sleep(50)
    MouseClick("left")
    Sleep(50)
    Send(ep)
    Send("{Enter}")
    MouseMove(0, 22, 0, 'R')
    MouseClick("left")
    Sleep(50)
    Send(sl)
    MouseMove(0, 22, 0, 'R')
    MouseClick("left")
    Sleep(50)
    Send(tp)
    Send("{Enter}")
  }
  #!r:: {
    KeyWait("Ctrl")
    KeyWait("Alt")
    KeyWait("t")
    Sleep(50)
    MouseClick("left")
    Sleep(50)
    Send(sl)
    Send("{Enter}")
    MouseMove(0, 22, 0, 'R')
    MouseClick("left")
    Sleep(50)
    Send(tp)
    Send("{Enter}")
  }
  !e:: {
    KeyWait("Ctrl")
    KeyWait("Alt")
    KeyWait("e")
    Sleep(50)
    MouseClick("left", , , 2)
    Sleep(50)
    Send(ep)
    ; Send("{Enter}")
  }

  !t:: {
    KeyWait("Ctrl")
    KeyWait("Alt")
    KeyWait("t")
    Sleep(50)
    MouseClick("left", , , 2)
    Sleep(50)
    Send(tp)
    ; Send("{Enter}")
  }

  !s:: {
    KeyWait("Ctrl")
    KeyWait("Alt")
    KeyWait("s")
    Sleep(50)
    MouseClick("left", , , 2)
    Sleep(50)
    Send(sl)
    ; Send("{Enter}")s
  }
#HotIf
; End

; ****************************
; for fx-replay
; ****************************
  #!q:: {
    ; if(WinExist(fxWin)){
    ;   list:=WinGetList(fxWin)
    ;   if(not list){
    ;     MsgBox('Error finding fxWin')
    ;     return
    ;   }
    ;   for index, id in list {
    ;     if(!WinActive(id)){
    ;       WinActivateFast("ahk_id " id)
    ;     } else {
    ;       WinMinimize('ahk_id ' id)
    ;     }
    ;   }
    ; } else {
    if (!WinExist(fxWin))
      Run(browserWithTradingProfile 'https://app.fxreplay.com/ --new-window')
    try WinActivateFast(fxWin)
    winHandle := WinWaitActive(fxWin, , 20)
    if (winHandle) {
      setManualBookmark('#t', winHandle)
    } else {
      MsgBox('Error finding fxWin')
    }
    ; Run(browserWithTradingProfile 'https://app.fxreplay.com/ --new-window' )
    ; }
  }
#HotIf WinActive(fxWin) and tvMode == 'command'
Space:: {
  send('^{Space}')
}
#HotIf
#HotIf
#HotIf WinActive(fxWin)
+Space:: Send('^{Space}')
!z:: send('!,')
; TODO: add to a new menu
!r:: send('!j') ; ray
#HotIf
; End

; ****************************
; We are in command mode
;****************************
#HotIf WinActive(tvWin) and tvMode == 'command' ; InStr(activeTradeWin, winTitleUnderMouse)
  f::
  b:: {
    pressToolBar(isFx ? 14 : 14, 1) ; Path
  }
  Space::
  a:: {
    send('{esc}')
    if (isFx) {
      send('^{Space}')
      return
    }
    send('+{Right}')
  }
  z:: Send('^z')
#HotIf
; End


; ****************************
; mannaging only debug/nodebug mode specifically
#HotIf tvBacktesting and WinActive(activeTradeWin)
Space:: {
  SendWithLevel('+{right}', 1)
}
#HotIf
; ****************************
;end 

; ****************************
; hotkeys and hotkstring
; ****************************
#HotIf WinActive(activeTradeWin)
  ; hotstrings
  :*:.up::🟢
  :*:.dn::🔴
  :*:.nd::⚫
  :O:.ch::CHoCH
  :*:ccc::CHoCH
  :O:.bo::BOS
  :*:bbb::BOS
  :O:.id::IDM
  :O:.d::Daily
  :O:.4::H4
  :O:.1::H1
  :O:.5::M15
  ; end hotstrings
  ^#t:: Send(tp)
  ^#e:: Send(ep)
  ^#s:: Send(sl)
  #x:: msgV1('x')
  +Space:: {
    A_Clipboard := ' '
    send('^v')
  }
  ; !Space:: {
  ;   char := Seq(500, 1, , , false)
  ;   BlockInput(true)
  ;   if (char) {
  ;     if (char == '1') {
  ;       SendWithLevel('1{Enter}', 1)
  ;       Sleep(500)
  ;       hardResetChart()
  ;     } else if (char == '2') {
  ;       SendWithLevel('5{Enter}', 1)
  ;       Sleep(500)
  ;       hardResetChart()
  ;     } else if (char == '3') {
  ;       SendWithLevel('15{Enter}', 1)
  ;       Sleep(500)
  ;       hardResetChart()
  ;     } else if (char == '4') {
  ;       SendWithLevel('4h{Enter}', 1)
  ;       Sleep(500)
  ;       hardResetChart()
  ;     } else {
  ;       Sleep(1)
  ;       SendWithLevel('{space}' char, 1)
  ;     }
  ;   }
  ;   else {
  ;     ; msgOld('no char')
  ;     ; pressToolBar(isFx ? 14 : 14, 1)
  ;     SendWithLevel('{space}', 1)
  ;   }
  ;   BlockInput(false)
  ; }
  ^Space:: {
    if (isFx) {
      Send('^{Space}')
    } else {
      Send('+{Right}')
    }
  }
  F1:: {
    Send('15{enter}')
    Sleep(700)
    hardResetChart()
  }
  F2:: {
    Send('1{enter}')
    Sleep(700)
    hardResetChart()
  }
  F3:: {
    Send('4H{enter}')
    Sleep(700)
    hardResetChart()
  }
  F4:: toggleTvMode()
  F5:: toggleDebuggingTV()
  ; ****************************
  ; Drawings / objects / presstoolbar
  ; ****************************
  !e:: Send('!t') ; trendline
  !q:: {
    if (isFx) {
      pressToolBarWithCoords(30, 116, 56, 170) ; rectangle
    } else
      Send('!+r')
  }
  !b:: pressToolBar(isFx ? 14 : 14, 1) ; toggle drawings/indicators visibility
  ; !h:: pressToolBarWithCoords(33, 79, 108, 247, false, 30, 72, 91, 228) ;
  !p:: pressToolBarWithCoords(35, 181, 89, 499, false, 31, 117, 78, 248) ; Path
  !x:: pressToolBarWithCoords(33, 238, 56, 292, false, 32, 211, 51, 260) ; Highlight
  !s::
  short(key := '') {
    if (isTv){
      pressToolBar(isFx ? 7 : 5, 2) ; Short
    } else {
      pressToolBarWithCoords(29, 188, 84, 212)
    }
  }
  !+e:: pressToolBar(isFx ? 6 : 6, 14) ; ellipse
  ; !c::pressToolBar(isFx ? 7 : 5, 1) ; Long
  !+s::
  long(key := '') {
    if (isTv)
      pressToolBar(isFx ? 7 : 5, 1) ; Long
    else
      pressToolBarWithCoords(28, 186, 108, 194)
  }
  ; !l:: long()
  !a:: pressToolBarWithCoords(34, 181, 163, 498) ; Path
  ; !x::pressToolBar(isFx ? 4 : 6, 2) ; Highlight
  !z:: {
    static isZoom := true
    toolPos := isFx ? (isZoom ? 10 : 11) : (isZoom ? 10 : 11)
    isZoom := !isZoom
    pressToolBar(toolPos, 0, true) ; Long
  }
  !v:: {
    char := Seq(800, 1)
    if (char) {
      if (char == 't') {
        Send(tp)
      } else if (char == 's') {
        Send(sl)
      } if (char == 'e') {
        Send(ep)
      } if (char == 'v') {
        setPosition()
      }
    }
  }
  !i:: {
    A_Clipboard := 'Icon'
    Sleep(50)
    send('^v')

  }
  !j:: Send("!j")
  #i:: {
    if ( not WinExist('ahk_exe Frameless.exe'))
      Run('C:\tools\frameless\Frameless.exe "C:\Users\JP\Documents\validPullBack.png" x=1760 y=45 w=80 h=80 aot=yes noactivate=yes')
  }
  !F1::
  `::
  {
    toggletvactive()
  }
  !F2::
  !#^F2:: {
    toggletvBarVisible(false)
  }
  !F3:: toggletvBarVisible(true)
  ; *******************************************
  ; Positions
  ; *******************************************
  !c:: readPosition()
  ; !a::position()
  ^2:: position(2)
  #!2:: position(2, 20)
  #!^2:: position(2, 10)
  #!+2:: position(2, 10)
  ^3:: position(3)
  #!3:: position(3, 5)
  #!^3:: position(3, 2)
  #!+3:: position(3, 15)
  ^4:: position(4)
  #!4:: position(4, 20)
  #!^4:: position(4, 15)
  #!+4:: position(4, 15)
  ^5:: position(5)
  #!5:: position(5, 20)
  #!+5:: position(5, 20)

  !+b:: {
    KeyWait("Alt")
    MouseClick("left")
    Sleep(100)
    Send("^c")
    Send("{Tab 5}")
    Sleep(100)
    Send("{Enter}")
    Sleep(200)
    WinActivateFast("ahk_class MetaQuotes::MetaTrader::4.00")
    return
  }
  #e:: mainSeq('#e')
  ; #4::toggleIndicator('4H') ; ext H4
  #1::toggleIndicator('1H') ; ext H1
  #5::toggleIndicator('15') ; ext M15
  #!d::toggleIndicator('daily') ; Daily
  #d::toggleIndicator('optistruct') ; OptiStruct
  #!e::toggleIndicator('Int.') ; Internal
  ; !r::seqGui([
  ;   ; { key: 'a', label: 'm1', fn: () => [ send('5{Enter}')]},
  ;   { key: 'b', label: 'm5', fn: () => [ send('5{Enter}')]},
  ;   { key: 'c', label: 'm15', fn: () => [ send('15{Enter}')]},
  ;   { key: 'd', label: 'H1', fn: () => [ send('1h{Enter}')]},
  ;   { key: 'e', label: 'H4', fn: () => [ send('4h{Enter}')]},
  ; ], 10000, true, 800)
#HotIf
; End

; ****************************
; mbuttons at bottom, left: zoom panel, right: reset chart
; ****************************
#HotIf WinActive(activeTradeWin) and isTvActive() and inStr(winTitleUnderMouse, activeTradeWin) and mouseY > 700 ; Mbutton
  MButton:: {
    if (mouseX < 1600) { ; zoom panel
      send('{alt Down}')
      MouseClick('Left')
      send('{alt Up}')
      msg('Zoom!')
    } else if (mouseY > 700) {
      hardResetChart()
    }
  }
#HotIf
; End

; ****************************
; mouse
; ****************************

#HotIf WinActive(activeTradeWin) and isTvActive() and inStr(winTitleUnderMouse, activeTradeWin) ; Mouse
  ; Indicators
  ; seqGui for toolbar buttons
  !a::
  XButton2::
    mainSeq(a, millToStart := 1){
      ; hide indicators
      key := seqGui([
        { key: 'e', label: 'PullBack indicator toggle', fn: () => [ pressToolBarWithCoords(64, 152, 99, 152) ]},
        { key: 'r', label: 'Ray', fn: () => [ KeyWait('Alt'), Send('!j')]},
        { key: 'h', label: 'Horizontal line', fn: () => [
          pressToolBarWithCoords(33, 79, 108, 247, false, 30, 72, 91, 228, true)
        ]},
        { key: 's', label: 'Short', fn: () => [ pressToolBarWithCoords(34, 155, 90, 208)]},
        { key: '!s', label: 'Long', fn: () => [ pressToolBarWithCoords(34, 155, 131, 174)]},
        { key: 'p', label: 'Path', fn: () => [ 
          isTv ? pressToolBarWithCoords(34, 130, 163, 498) : pressToolBarWithCoords(35, 129, 89, 290)
        ]},
        { key: 'v', label: 'Vertical Line',  fn: () => [ pressToolBarWithCoords(34, 77, 110, 308)]},
        { key: 'c', label: 'Collapse price', fn: () => [ collapsePrice()]},
        { key: '#e',label: 'Ind. OptiStruct',fn: () => [ toggleIndicator('optistruct')]},
        { key: 'i', label: 'Ind. Internal',  fn: () => [ toggleIndicator('Int.')]},
        { key: 'd', label: 'Ind. Ext Daily', fn: () => [ pressToolBarWithCoords(255, 167, 367, 169)]},
        { key: '4', label: 'Ind. Ext H4',    fn: () => [ toggleIndicator('4H')]},  ; Updated to use toggleIndicator
        { key: '1', label: 'Ind. Ext H1',    fn: () => [ toggleIndicator('1H')]},  ; Updated to use toggleIndicator
        { key: '5', label: 'Ind. Ext 15m',   fn: () => [ toggleIndicator('15m')]},  ; Updated to use toggleIndicator
        { key: '#5', label: 'Ind. Ext 5m',    fn: () => [ toggleIndicator('5m')]},  ; Updated to use toggleIndicator
        { key: 'w', label: 'Ind. Sectional', fn: () => [ toggleIndicator('Sess')]},  ; Updated to use toggleIndicator
        { key: '#d',label: 'Ind. Disabled',  fn: () => [ pressToolBarWithCoords(36, 421, 149, 442)]},
      ], 10000, true, millToStart)
    }
  XButton1:: hardResetChart()

  ^+WheelDown:: {
    send('{WheelDown}')
  }
  ^+WheelUp:: {
    send('{WheelUp}')
  }
  +MButton:: {
    msgV1('Collapsing Price')
    KeyWait('Shift')
    BlockInput(true)
    Send('{Ctrl down}')
    ; make a for loop 10 times
    Loop (50) {
      Send('${WheelDown 5}')
      Sleep(1)
    }
    ; Sleep(100)
    ; Send('{WheelDown 15}')
    Send('{Ctrl up}')
    BlockInput(false)
    msgV1('Done')
  }
  +!MButton:: {
    KeyWait('Shift')
    KeyWait('Alt')
    BlockInput(true)
    ; make a for loop 10 times
    Loop (25) {
      scrollAlt('dn', 10)
    }
    ; Sleep(100)
    ; Send('{WheelDown 15}')
    BlockInput(false)
  }

  +WheelDown:: {
    scrollAlt("dn")
    Send("^{WheelDown 2}")
  }
  +WheelUp:: {
    scrollAlt("up")
    Send("^{WheelUp 2}")
  }

  WheelDown:: whell('dn')
  WheelUp:: whell('up')

  !WheelDown:: scrollAlt("dn")
  !WheelUp:: scrollAlt("up")
#HotIf

; End

; ****************************
; Functions
; ****************************
  toggleIndicator(key, reUse := false){

    if (key == 'sess') {
      pressToolBarWithCoords(555, 59, 1622, 59)
    } else if (key == 'optistruct') {
      pressToolBarWithCoords(137, 120, 215, 118)
    } else if (key == 'int') {
      pressToolBarWithCoords(315, 157, 227, 161)
    } else if (key == 'daily') {
      changeExtIndicator('daily')
    } else if (key == '4H' and reUse) {
      changeExtIndicator('4H')
    } else if (key == '1H' and reUse) {
      changeExtIndicator('1H')
    } else if (key == '15m' and reUse) {
      changeExtIndicator('15m')
    } else if (key == '5m' and reUse) {
      changeExtIndicator('5m')
    } else if (key == 'pb' and !reUse) {
      pressToolBarWithCoords(64, 151, 99, 149)
    }
  }

  changeExtIndicator(TF){
    mPos := saveMouse()
    BlockInput(true)
    try {
      tfs := Map('4H', [974, 618], '1H', [979, 546], '15m', [987, 478], '5m', [989, 421], 'daily', [975, 642])
      clickCoords := [[141, 133],[384, 134, 700],[1020, 180],  tfs.get(TF), [1131, 1036]]
      for coords in clickCoords{
        mi := getMonitorInfo()
        ; log(mi.monitor, mi.screenLeft, mi.screenRight, mi.left, mi.right)
        if(mi.monitor == 2){
          msg('error', 'monitor = 2')
          soundError()
          BlockInput(false)
          return
        }
        MouseClick('Left', coords[1], coords[2], 1, 0)
        ms := coords.Length == 3 ? coords[3] : 200
        Sleep(ms)
      }
      
    } catch Error as e {
      msg('error')
    }
    BlockInput(false)
    restoreMouse(mPos)
    ; MouseClick('Left', tfs.get(TF)[1] tfs.get(TF)[2], 1, 0)
    ; Sleep(1000)
    ; MouseClick('Left', 1131, 1036, 1, 0)
  }
  collapsePrice() {
    msgV1("Collapsing...")
    If (GetKeyState("Shift")) {
      Send("{Shift up}")
      Sleep(500)
    }
    ; Sleep, 1000
    Loop 40 {
      scrollAlt("dn")
      Sleep(10)
    }
    msgV1("Collapsing, ready")
    return
  }

  whell(dir) {
    savedMouse := saveMouse()
    mouseInfo := getMouseCoords('Window')

    isAtBottom := mouseInfo.y > (monitorInfo.Bottom - 300)
    if ((mouseInfo.x > (monitorInfo.right - 200)) and not isAtBottom) {
      BlockInput(true)
      Send(dir == 'up' ? "{WheelUp}" : "{WheelDown}")
      BlockInput(false)
      return
    }

    if (isAtBottom) {
      rightOffSet := monitorInfo.right - 500
      if (mouseInfo.x > (rightOffSet)) {
        MouseMove(monitorInfo.right - 60, monitorInfo.Bottom / 2, 0)
        scrollAlt(dir)
        MouseMove(monitorInfo.right / 2, monitorInfo.Bottom / 2, 0)
        Send(dir == 'dn' ? "^{WheelDown}" : "^{WheelUp}")
      } else {
        scrollAlt(dir)
      }
    } else {
      BlockInput(true)
      Send(dir == 'up' ? "^{WheelUp}" : "^{WheelDown}")
      BlockInput(false)
    }
    restoreMouse(savedMouse)
  }

  scrollAlt(dir, count := 5) {
    global tvRightOffset, tvSideBarWidth := 160
    try {
      dir := (dir = 'up') ? 'up' : 'dn'
      mouseInfo := getMouseCoords('Window')
      rightOffset := tvRightOffset + (tvBarVisible ? tvSideBarWidth : 0)
      X2 := monitorInfo.right - rightOffset
      BlockInput(true)
      MouseMove(X2, mouseInfo.y > 786 ? 600 : mouseInfo.y, 0)
      dir = "dn" ? Send("{WheelDown " count "}") : Send("{WheelUp " count "}")
      MouseMove(mouseInfo.x, mouseInfo.y, 0)
    } catch Error as e {
      BlockInput(false)
    } finally {
      BlockInput(false)
    }

  }

  isTvActive() {
    global tvactive
    return tvactive == 1
  }

  toggletvBarVisible(visible := false) {

    global tvBarVisible
    global ogcsideBar
    mousePos := mouseClickAndSave(1918, 102)
    if istvBarVisible() {
      ogcsideBar := "Bar visible"
      msgV1("Bar visible")
      tvBarVisible := false
    } else {
      ogcsideBar := ""
      msgV1("Bar hidden")
      tvBarVisible := true
    }
    if (visible) {
      Sleep(100)
      Send("^!+-")
    } else {
      ; pairs
      Sleep(100)
      Send("^!+/")
    }
    restoreMouse(mousePos)
    return
  }

  istvBarVisible() {
    return tvBarVisible
  }

  toggletvactive() {
    global tvactive
    if isTvActive() {
      tvactive := "0"
    } else {
      tvactive := "1"
    }
  }

  temp(range) {
    msgV1(range)
    Send(range)
    Sleep(200)
    Send("{Enter}")
  }

  TVChecksTwoSec() {
    checkIfWindowOpened()
  }

  TVChecksHalfSec() {
    global activeTradeWin, tvWin, fxWin, isTv, isFx
    checkForTVGui()
    try {
      isTv := InStr(WinGetTitle('A'), tvWin)
      isFx := InStr(WinGetTitle('A'), fxWin)
      ; msgOld(activeTradeWin)
      activeTradeWin := isTv ? tvWin : (isFx ? fxWin : 'xxxxx')
    } catch Error as e {
      activeTradeWin := 'error:xxxxx'
    }
  }

  checkIfWindowOpened() {
    global tvactive
    ; ImageSearch(&X, &Y, 322, 0, 1670, 429, '*10 tvWinX1.png')
    ; msgOld(X ? 'Found' : 'Not found')
    ; if(!X){
    ; ImageSearch(&X, &Y, 322, 0, 1670, 429, '*50 tvWinX2.png')
    ; ImageSearch(&X, &Y, 416, 37, 1528, 637, 'XButton2.png')
    ; }
    ; if(!X){
    ;   ImageSearch(&X, &Y, 779, 633, 1666, 1075, 'TVWindowLine.png')
    ; ; ImageSearch(&X, &Y, 416, 37, 1528, 637, 'XButton2.png')
    ; }
    ; tvactive := X ? false : true
  }

  createTVGuis() {
    global myGui
    myGui := Gui()
    myGui.Opt("-Caption	+AlwaysOnTop -SysMenu +ToolWindow")		;removes caption and border

    myGui.BackColor := "1d222e"				; sets window color
    myGui.SetFont("s9 bold", "Arial")   ;now this sets the font for all of the GUI
    fontColor := '8c92a6'
    myGui.Add("text", "x2 y4 w30 h12 c" fontColor " vshift")

    myGui.Add("text", "x31 y4 w2 h12 c" fontColor, "|")
    myGui.Add("text", "x37 y4 w19 h12 c" fontColor " vctrl")

    myGui.Add("text", "x62 y4 w2 h12 c" fontColor, "|")
    myGui.Add("text", "x72 y4 w33 h12 c" fontColor " vtvActive")

    myGui.Add("text", "x110 y4 w2 h12 c" fontColor, "|")
    myGui.Add("text", "x119 y4 w27 h12 c" fontColor " vtvMode")

    myGui.Add("text", "x152 y4 w2 h12 c" fontColor, "|")
    myGui.Add("text", "x159 y4 w37 h12 c" fontColor " vtvBacktesting")

    myGui.Add("text", "x299 y4 w2 h12 c" fontColor, "|")
    myGui.Add("text", "x305 y4 w187 h12 c" fontColor " vtvBarVisible")

    myGui.Show("x" . tvToolbarLeft . " y5 W207")


  }
  
  timeframeChange(text) {
    win := WinExist(fxWin) ? fxWin : tvWin
    WinActivateFast(win)
    ; WinWaitActive(win, 600)
    BlockInput(true)
    MouseMove(-20, -20, , 'R')
    Sleep(100)
    send(text)
    Sleep(50)
    send('{Enter}')
    MouseMove(20, 20, , 'R')

    hardResetChart()
    BlockInput(false)
  }
  
  hardResetChart(){
    global tvBarVisible
    msg('Reset chart')
    ; if (betweenCoords(1834, 39, 1916, 1004)) {
    ;   clickOnPosition(1901, 47)
    ;   tvBarVisible := not tvBarVisible
    ;   return
    ; }
    ; mp := saveMouse()
    send('^!h')
    sleep(200)
    ; MouseMove(28, 495, 0)
    resetChart()
    sleep(200)
    send('^!h')
    ; restoreMouse(mp)
  }

  checkForTVGui() {
    global myGui, guiActive 
    if (MouseIsOver(activeTradeWin) and not guiActive) {
      myGui.Show("NoActivate")
      guiActive := true
    }
    if (MouseIsOver(activeTradeWin) and guiActive) {
      try myGui['shift'].Text := GetKeyState("Shift") ? 'Shift' : ''
      try myGui['Ctrl'].Text := GetKeyState("Ctrl") ? 'Ctrl' : ''
      try myGui['tvBacktesting'].Text := tvBacktesting ? 'BT' : ''
      try myGui['tvMode'].Text := tvMode == 'normal' ? '' : 'Cmd.'
      try myGui['tvActive'].Text := tvactive ? '' : 'TVOff'
      try myGui['tvBarVisible'].Text := tvBarVisible ? 'R-Bar' : 'ssss'
    }
    if ( not MouseIsOver(activeTradeWin)) {
      guiActive := false
      myGui.Hide()

    }
  }

  pressToolBarWithCoords(X1, Y1, X2, Y2, onlyFirst := false, X1TV := false, Y1TV := false, X2TV := false, Y2TV := false, applyOnEnd := false) {
    if (!X1TV) {
      X1TV := X1
      Y1TV := Y1
      X2TV := X2
      Y2TV := Y2

    } else if (WinActive(fxWin)) {
      Sleep(100)
      X1 := X1TV
      Y1 := Y1TV
      X2 := X2TV
      Y2 := Y2TV
    }
    KeyWait("alt")
    KeyWait("ctrl")
    BlockInput(true)
    mPos := saveMouse()
    if (onlyFirst) {
      MouseClick('Left', X1, Y1, 1, 0)
      BlockInput(false)
      return
    } else {
      MouseMove(X1, Y1, 0)
      MouseClick('Left')
    }

    ; if(true){
    ;   BlockInput(false)
    ;   return
    ; }
    MouseMove(X2, Y2, 0)
    Sleep(100)
    MouseClick('Left')
    restoreMouse(mPos)
    if (applyOnEnd) {
      Sleep(200)
      MouseClick('Left')
    }
    BlockInput(false)
  }

  pressToolBar(tvNum, elNum, onlyOnSideBar := false, clickOnEnd := false) {
    ; al 70% zoom for tv
    ; al 75% zoom for fx
    ; tvNum := 7
    ; elNum := 1
    yStart := isfx ? 45 : 50
    yStartMenuLeft := isfx ? 0 : 17
    elHeight := 28
    BlockInput(true)
    MouseGetPos(&X, &Y)
    ; KeyWait("alt")
    yPos := yStart + ((tvNum - 1) * elHeight)

    MouseMove(28, yPos, 0)
    if (isfx) {
      MouseClick('Left', , , 1, 0, 'D')
      Sleep 500
    } else {
      MouseClick('Left', , , 2, 0)
    }

    if (!onlyOnSideBar) {
      offsetElX := 30
      offsetElY := yStartMenuLeft + (elHeight * (elNum - 1))
      MouseMove(offsetElX, offsetElY, 0, 'R')
      Sleep 20
      MouseClick('Left', , , 1)
    }

    MouseMove(X, Y, 0)

    if (clickOnEnd) {
      Sleep(100)
      MouseClick('Left')
    }

    BlockInput(false)
    Send('{Ctrl Up}')
    Send('{Shift Up}')
    Send('{Alt Up}')


  }

  readPosition() {
    global ep, tp, sl
    KeyWait("Alt")
    MouseClick("left", , , 2)
    Sleep(100)
    ; Check if we are in the inputs tab of the order dialog
    if (!isSelectedTextANumber()) {
      msgV1("Error, goto the inputs tab", 4, false, 900, 400)
      soundError()
      return
    }
    ; we are ok
    ; ep
    Send("{Tab 4}")
    ep := CtrlC()
    Send("{Tab 2}")
    tp := CtrlC()
    Send("{Tab 2}")
    sl := CtrlC()
    Send("{Tab 3}")
    Send("{Enter}")
  }

  position(tpX := false, ticksForSl := 0) {
    global ep, tp, sl
    comision := 4
    KeyWait("Alt")
    MouseClick("left", , , 2)
    ; test first
    Sleep(100)
    clip := ctrlC()
    if (!isSelectedTextANumber()) {
      msgV1("Error, goto the inputs tab", 4, false, 900, 400)
      soundError()
      return
    }

    ; we are ok
    Send("{Tab 4}")
    ep := CtrlC()

    ; tp
    Send("{Tab 2}")
    Sleep(50)
    tp := CtrlC()

    ; ticks + ticksForSl
    Send("{Tab 1}")
    ticks := Number(CtrlC())
    ticksSL := ticks + ticksForSl
    Send(ticksSL)

    ; sl
    Send("{Tab 1}")
    Sleep(50)
    sl := CtrlC()
    Sleep(50)

    ; change tp
    Send("+{tab 3}")
    tpx := tpx ? tpx : InputBox("Enter X TP", "X TP", , 2).value
    ticksTP := (ticksSL * tpx) + (comision * tpx)
    Sleep(50)
    if (ticksTP > 2800) {
      msgbox("Error tp muy alto: " . ticksTP)
    } else {
      Sleep(50)

      Send(ticksTP)
      Sleep(50)
    }
    Send("{Tab}")
    Sleep(50)
    tp := CtrlC()
    Send("{tab 5}")
    Sleep(50)
    Send("{Enter}")
    Sleep(80)
    msgV1('copied to clipboard', 1)
    copyToClipboard(tp)
    copyToClipboard('tp')
    copyToClipboard(sl)
    copyToClipboard('sl')
    copyToClipboard(ep)
    copyToClipboard('ep')
  }

  setPosition(tpX := false, ticksForSl := 0) {
    global ep, tp, sl
    comision := 4
    KeyWait("Alt")
    MouseClick("left", , , 2)
    ; test first
    Sleep(100)
    clip := ctrlC()
    if (!isSelectedTextANumber()) {
      msgV1("Error, goto the inputs tab", 4, false, 900, 400)
      soundError()
      return
    }
    send('{tab 4}')
    if (IsSet(ep)) {
      send(ep)
    }
    send('{tab 2}')
    if (IsSet(tp)) {
      send(tp)
    }
    send('{tab 2}')
    if (IsSet(sl)) {
      send(sl)
    }
    send('{tab 3}')
    Send('{Enter}')
  }
  isSelectedTextANumber() {
    prevClip := A_Clipboard
    clip := ctrlC()
    A_Clipboard := prevClip
    return isNumber(clip) == 1
  }

  makeTvContextMenu() {
    ; Menu, MyMenu, add  ; Creates a separator line.
    Tray := A_TrayMenu
    TraySetIcon("tv.png")
    MyMenu := Menu()
  }

  toggleTvMode() {
    global tvMode
    tvMode := tvMode == 'normal' ? 'command' : 'normal'
  }

  toggleDebuggingTV() {
    global tvBacktesting
    tvBacktesting := !tvBacktesting
  }

  initTV() {
    tvactive := "1"
    global tvMode
    global guiActive := false
    global ogcshift := false
    global ogcctrl := false
    global ogcactive := false
    global activeTradeWin := 'XXXXXXXXX'
    global isTv := false, isFx := false
    ; global myGui
    global tvRightOffset := A_ComputerName == "ZENBOOK" ? 40 : 50
    global tvToolbarLeft := A_ComputerName == "ZENBOOK" ? 1300 : 1300
    global tvactive := "1"
    global tvWin := '% '
    global fxWin := 'FX Replay'
    global tvBacktesting := false

    ; Load global variables saved in ini file
    loadTVVariables()
    SetTimer(TVChecksHalfSec, 500)
    SetTimer(TVChecksTwoSec, 1000)
    createTVGuis()

  }

  loadTVVariables() {
    global tvMode, tvBacktesting, tvBarVisible, tvactive
    global tvVariablesToPersist := ["tvMode", "tvBacktesting", "tvBarVisible", "tvactive"]

    for variable in tvVariablesToPersist {
      try {
        %variable% := IniRead("config.ini", "variables", variable, "")
      } catch {
        try %variable% := ""
      }

    }
  }

  resetChart() {
    ; global tvSideBarWidth := 130
    ; rightOffset := tvRightOffset + (tvBarVisible ? tvSideBarWidth : 0)
    ; MouseGetPos(&X, &Y)
    ; BlockInput(true)
    ; MouseClick('Left', monitorInfo.right - 20 - rightOffset, Y, 2, 0)
    send('!r')
    sleep(100)
    scrollAlt("dn")
    ; MouseMove(X, Y, 0)
    ; BlockInput(false)
  }

  clickOnPosition(x, y) {
    mousePos := saveMouse()
    MouseMove(x, y, 0)
    MouseClick('Left')
    Sleep(1)
    restoreMouse(mousePos)
  }

  exitTv(exireason, exitcode) {
    for variable in tvVariablesToPersist {
      try IniWrite(%variable%, "config.ini", "variables", variable)
    }
  }
; End
