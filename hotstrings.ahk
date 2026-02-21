; ===================================================================
; HOTSTRINGS - TEXT REPLACEMENTS
; ===================================================================
; for LLMs

; LLM markup selector - shows all available options
:*?C:.ll:: {
  options := {
    waitml: 800,
    items: [{ key: "y", label: "you" }, { key: "b", label: "begin/end" }, { key: "f", label: "For you" }, { key: "r", label: "rules" }, { key: "e", label: "examples" }, { key: "c", label: "context" }, { key: "i", label: "instructions" }, { key: "s", label: "step" }
    ]
  }

  key := customMenu(options)

  ; Execute the selected action based on the key
  switch key {
    case "y":
      clp := A_Clipboard
      send('{shift down}')
      A_Clipboard := '<you>`n`n</you>'
      send('^v')
      sleep(50)
      send('{shift up}')
      send('{up}')
      A_Clipboard := clp
    case "b":
      clp := A_Clipboard
      A_Clipboard := '<begin>`n`n<end>'
      send('{shift down}')
      send('^v')
      sleep(50)
      send('{shift up}')
      send('{up}')
      sleep(50)
      send('{end}')
      sleep(50)
      send('+{enter}')
      A_Clipboard := clp
    case "f":
      clp := A_Clipboard
      A_Clipboard := '<For you>`n`n</For you>'
      send('{shift down}')
      send('^v')
      sleep(50)
      send('{shift up}')
      send('{up}')
      sleep(50)
      send('{end}')
      sleep(50)
      send('+{enter}')
      A_Clipboard := clp
    case "r":
      clp := A_Clipboard
      A_Clipboard := '<rules>`n`n</rules>'
      send('{shift down}')
      send('^v')
      send('{shift up}')
      send('{up}')
      sleep(50)
      send('{end}')
      sleep(50)
      send('+{enter}')
      A_Clipboard := clp
    case "e":
      clp := A_Clipboard
      A_Clipboard := '<examples>`n`n</examples>'
      send('{shift down}')
      sleep(50)
      send('^v')
      sleep(50)
      send('{up}')
      sleep(50)
      send('{end}')
      sleep(50)
      send('+{enter}')
      A_Clipboard := clp
    case "c":
      clp := A_Clipboard
      A_Clipboard := '<context>`n`n</context>'
      send('{shift down}')
      sleep(50)
      send('^v')
      sleep(50)
      send('{up}')
      sleep(50)
      send('{end}')
      sleep(50)
      send('+{enter}')
    case "i":
      clp := A_Clipboard
      A_Clipboard := '<instructions>`n`n</instructions>'
      send('{shift down}')
      send('^v')
      send('{shift up}')
      sleep(50)
      send('{up}')
      A_Clipboard := clp
    case "s":
      send('Lets work step by step, one at a time, we don`'t start the next one until I told you so')
  }
}
; for LLMs end


; API keys
:?C:.apior:: {
  send('REDACTED_SECRET')
}

:?C:.apig:: {
  options := {
    waitml: 0,
    items: [{ key: "1", label: "jpsala" }, { key: "2", label: "alt" }, { key: "3", label: "api4" }, { key: "4", label: "api3" }, { key: "5", label: "api2" }, { key: "6", label: "api1" }, { key: "7", label: "tv" }, { key: "8", label: "ai" }
    ]
  }

  key := customMenu(options)

  ; Execute the selected action based on the key
  if (key == "1") {
    send('REDACTED_SECRET')
  } else if (key == "2") {
    send('REDACTED_SECRET')
  } else if (key == "3") {
    send('REDACTED_SECRET')
  } else if (key == "4") {
    send('REDACTED_SECRET')
  } else if (key == "5") {
    send('REDACTED_SECRET')
  } else if (key == "6") {
    send('REDACTED_SECRET')
  } else if (key == "7") {
    send('REDACTED_SECRET')
  } else if (key == "8") {
    send('REDACTED_SECRET')
  }
}
:?C:.apioa:: {
  send('REDACTED_SECRET' 'REDACTED_SECRET' 'REDACTED_SECRET' 'REDACTED_SECRET')
}
:?C:.apia:: {
  send('REDACTED_SECRET' 'REDACTED_SECRET' 'REDACTED_SECRET' 'REDACTED_SECRET' 'REDACTED_SECRET')
}

; Script helpers
:?C:.sprun:: {
  Send('sp.Run(`'c:\\dev\\scripts\\bin\\sp.ahk `' + action.ActionName + " " + action.GestureName + " " + action.ApplicationName)')
}
::.ah::autohotkey

; Password
:*:.pp::REDACTED_SECRET

; ===================================================================
; vs code snippets
; ===================================================================
:?C:.mb:: {
  send('multipleBookings')
}
; ===================================================================
; SPECIAL CHARACTERS - ACCENTS AND SPANISH CHARACTERS
; ===================================================================

; Spanish accents and ñ

:*?C:~n::ñ
:*?C:''a::á
:*?C:''e::é
:*?C:''i::í
:*?C:''o::ó
:*?C:''u::ú

; ===================================================================
; DATE AND TIME INSERTIONS
; ===================================================================
; generate a random number between 0 and 6


:?C:.mn:: {
  ; The number of sequential strategies SQ will save from this starting point.
  strats := 2000
  ; We will reserve a block of 1000, so 'strats' should ideally be <= 1000.
  ; If strats > 1000, the blocks might overlap in the next hour, but this is a minor risk.

  maxMagicNumber := 2147483647

  ; --- Your Enhanced Logic ---
  ; We create a unique "Block ID" based on Year, Month, Day, and Hour (YMMddHH).
  ; This makes the block unique across a 10-year period.
  ; We append "000" to reserve a block of 1,000 numbers.

  lastDigitOfYear := SubStr(A_Year, -0) ; Gets the last character of the year (e.g., '5' for 2025)
  blockID_str := FormatTime("A_now", "MMddHH")
  magicNumber_str := lastDigitOfYear . blockID_str . "000"

  ; Convert to integer.
  magicNumber := Integer(magicNumber_str)

  ; --- CRUCIAL SAFETY CHECK ---
  ; Verify the number is within the MT4/MT5 limit.
  if (magicNumber > maxMagicNumber) {
    MsgBox("CRITICAL WARNING:"
      . "`n`nThe generated magic number (" . magicNumber . ") is TOO LARGE."
      . "`n`nLimit: " . maxMagicNumber
      . "`nThis can happen in years ending with a high digit (e.g., 2032, 2033)."
      . "`n`nThe script will stop to prevent errors.", "Magic Number Overflow", 16) ; 16 = Critical/Stop Icon
    return
  }

  ; Check if we have enough room for all 'strats'.
  if ((magicNumber + strats) > maxMagicNumber) {
    MsgBox("WARNING:"
      . "`n`nThe starting magic number (" . magicNumber . ") is valid,"
      . "`nbut the range for " . strats . " strategies would exceed the max limit."
      . "`n`nReduce the number of strategies or wait for the next hour.", "Range Overflow", 48)
    return
  }


  ; Send the robust starting magic number to StrategyQuant.
  SendInput(magicNumber)

}

:?C:.rn:: {
  yearShort := SubStr(A_YYYY, 3, 2)
  dateTimeStr := yearShort . A_MM . A_DD . A_Hour . A_Min
  magicNumber := round(dateTimeStr / 2)
  SendInput magicNumber
}
:?C:.t1:: {
  time := FormatTime("A_now", "HHmm")
  Send(time)
}
:?C:.t2:: {
  time := FormatTime("A_now", "HH:mm")
  Send(time)
}
:?C:.dt:: {
  time := FormatTime("A_now", "yyMMddHHmm")
  Send(time)
}
:?C:.dt1:: {
  time := FormatTime("A_now", "yy-MM-dd-HHmm")
  Send(time)
}
:?C:.dt2:: {
  time := FormatTime("A_now", "yyMMdd HH:mm")
  Send(time)
}
:?C:.dt3:: {
  time := FormatTime("A_now", "MM-dd-yyyy_HH:mm")
  Send(time)
}
:?C:.dt4:: {
  time := FormatTime("A_now", "ddd MMM yyyy HH:mm")
  Send(time)
}
:?C:.d:: {
  time := FormatTime("A_now", "yy-MM-dd")
  Send(time)
}
:?C:.d1:: {
  time := FormatTime("A_now", "yyMMdd")
  Send(time)
}
:?C:.d2:: {
  time := FormatTime("A_now", "MM-dd-yy")
  Send(time)
}
:?C:.d3:: {
  time := FormatTime("A_now", "dd MMM yyyy")
  Send(time)
}
:?C:.d4:: {
  time := FormatTime("A_now", "ddd dd MMM yyyy")
  Send(time)
}
:?C:.d5:: {
  time := FormatTime("A_now", "yyyy dd (MMM) mm ") FormatTime("A_now", "ddd")
  Send(time)
}

; ===================================================================
; CODE BLOCK HOTSTRINGS
; ===================================================================

:?C:.cb:: {
  send('``````')
  send('{Enter}')
  send('`````` {up}{enter}')
}
:?C:.cbt:: {
  send('``````')
  send('{Enter}')
  send('`````` {up}typescript{enter}')
}
::nas:: {
  Send(getNextSerialNumber())
}