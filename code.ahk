; ********************************************
; vscode hotkeys
; ********************************************
#HotIf (WinActive("ahk_exe Code.exe") or WinActive("ahk_exe Cursor.exe",)) and (activeGroup == "")
!g:: {
  send('!^g')
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
#!p:: {
  KeyWait("Alt")
  KeyWait("LWin")
  send('^p%')
}

:*:.c :: {
  Send('console.log(')
}
:*:clogc:: {
  Send("console.log(" . "' " . A_Clipboard . "',){left} " . A_Clipboard)
}

#!r:: {
  cm := CoordMode('Mouse', 'Screen')
  mouseSaved := saveMouse()
  KeyWait("Alt", 'T1')
  KeyWait("LWin", 'T1')
  KeyWait("r", 'T1')
  try {
    WinActivate("[Debug] or chrome-debug")
  } catch Error as e {
    MsgBox('Open debug browser')
    return
  }
  WinGetPos(&x, &y, &width, &height, "A")
  MouseClick('Middle', x + 300, y + 300, 1, 0)
  Sleep(100)
  Send("^l")
  Sleep(200)
  Send("{enter}")
  Sleep(100)
  WinActivate("ahk_exe " cursorExe)
  CoordMode('Mouse', cm)
  restoreMouse(mouseSaved)
}

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

#HotIf (toggleCodeDebug)
F10:: msgV1(toggleCodeDebug)
!z:: Send('{F10}')
!r:: Send('{f5}')
!e:: Send('{f10}')
F1:: toggleLog(1)
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

;*********************************
;   End vscode
;*************************************
