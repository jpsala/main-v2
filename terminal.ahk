; ===================================================================
; TERMINAL HOTKEYS
; ===================================================================
#HotIf WinActive("ahk_exe WindowsTerminal.exe") or WinActive("ahk_exe ConEmu64.exe") and (activeGroup == "")
:*:.irc.:: {
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\{Enter}")
  Sleep(200)
  Send(".\Scripts\activate{Enter}")
  Sleep(200)
  Send("python -c `" import os; print(os.environ['VIRTUAL_ENV']) `" {Enter}")
  Sleep(500)
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\{Enter}")
  Send("python manage.py shell_plus --ptpython{Enter}")
  Sleep(1000)
  Send("{Enter}")
  Send("from django.forms.models import model_to_dict")
  Sleep(500)
  Send("{Enter}")
  Send("log=model_to_dict")
  Sleep(200)
  Send("{Enter}")
  Send("^l")
}

:*:.irci.:: {
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\{Enter}")
  Sleep(200)
  Send(".\Scripts\activate{Enter}")
  Sleep(200)
  Send("python -c `" import os; print(os.environ['VIRTUAL_ENV']) `" {Enter}")
  Sleep(500)
  Send("cd C:\\dev\\work\\IRCPeopleDirectory\\src\\{Enter}")
  Send("python manage.py shell_plus --ptipython{Enter}")
  Sleep(1000)
  Send("{Enter}")
  Send("log=model_to_dict{Enter}")
  SendInput("{Enter}")
  Sleep(100)
  Send('import printf{Enter}')
  Sleep(1000)
  Send('{Enter}^l')
  Send("{F2}{Down 7}{Right}{Down}{Right}{Down}{Right}{Enter}")
}

:*:.atci.:: {
  Send("cd C:\\dev\\work\\atc\\{Enter}")
  Sleep(200)
  Send(".\Scripts\activate{Enter}")
  Sleep(200)
  Send("python -c `" import os; print(os.environ['VIRTUAL_ENV']) `" {Enter}")
  Sleep(500)
  Send("cd C:\\dev\\work\\atc\\src\\{Enter}")
  Send("python manage.py shell_plus --ptipython{Enter}")
  Sleep(1000)
  Send("{Enter}")
  Send("log=model_to_dict{Enter}")
  SendInput("{Enter}")
  Sleep(1000)
  Send('{Enter}^l')
  Send("{F2}{Down 7}{Right}{Down}{Right}{Down}{Right}{Enter}")
}

:*:.import.:: {
  Send("from django.forms.models import model_to_dict{Enter}")
  Send("import printf{Enter}")
  Sleep(200)
  Send("log=model_to_dict{Enter}")
}
#HotIf
