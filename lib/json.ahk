;===============================================================================
; SHARED JSON HELPERS
; JXON source adapted from https://github.com/TheArkive/JXON_ahk2
;===============================================================================

JsonLoad(&src, args*) {
    return Jxon_Load(&src, args*)
}

JsonDump(obj, indent := "", lvl := 1) {
    return Jxon_Dump(obj, indent, lvl)
}

Jxon_Load(&src, args*) {
    key := "", is_key := false
    stack := [ tree := [] ]
    next := '"{[01234567890-tfn'
    pos := 0

    while ( (ch := SubStr(src, ++pos, 1)) != "" ) {
        if InStr(" `t`n`r", ch)
            continue
        if !InStr(next, ch, true) {
            testArr := StrSplit(SubStr(src, 1, pos), "`n")

            ln := testArr.Length
            col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

            msg := Format("{}: line {} col {} (char {})"
                ,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
                  : (next == "'")     ? "Unterminated string starting at"
                  : (next == "\")     ? "Invalid \escape"
                  : (next == ":")     ? "Expecting ':' delimiter"
                  : (next == '"')     ? "Expecting object key enclosed in double quotes"
                  : (next == '"}')    ? "Expecting object key enclosed in double quotes or object closing '}'"
                  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
                  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
                  : ["Expecting JSON value(string, number, [true, false, null], object or array)"
                     , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1)][1]
                , ln, col, pos)

            throw Error(msg, -1, ch)
        }

        obj := stack[1]
        is_array := (obj is Array)

        if i := InStr("{[", ch) {
            val := (i = 1) ? Map() : Array()

            is_array ? obj.Push(val) : obj[key] := val
            stack.InsertAt(1,val)

            next := '"' ((is_key := (ch == "{")) ? "}" : "{[]0123456789-tfn")
        } else if InStr("}]", ch) {
            stack.RemoveAt(1)
            next := (stack[1]==tree) ? "" : (stack[1] is Array) ? ",]" : ",}"
        } else if InStr(",:", ch) {
            is_key := (!is_array && ch == ",")
            next := is_key ? '"' : '"{[0123456789-tfn'
        } else {
            if (ch == '"') {
                i := pos
                while (i := InStr(src, '"',, i+1)) {
                    val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
                    if (SubStr(val, -1) != "\")
                        break
                }
                if !i ? (pos--, next := "'") : 0
                    continue

                pos := i

                val := StrReplace(val, "\/", "/")
                val := StrReplace(val, '\"', '"')
                val := StrReplace(val, "\b", "`b")
                val := StrReplace(val, "\f", "`f")
                val := StrReplace(val, "\n", "`n")
                val := StrReplace(val, "\r", "`r")
                val := StrReplace(val, "\t", "`t")

                i := 0
                while (i := InStr(val, "\",, i+1)) {
                    if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
                        continue 2

                    xxxx := Abs("0x" . SubStr(val, i+2, 4))
                    if (xxxx < 0x100)
                        val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
                }

                if is_key {
                    key := val, next := ":"
                    continue
                }

            } else {
                val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)

                if IsInteger(val)
                    val += 0
                else if IsFloat(val)
                    val += 0
                else if (val == "true" || val == "false")
                    val := (val == "true")
                else if (val == "null")
                    val := ""
                else if is_key {
                    pos--, next := "#"
                    continue
                }

                pos += i-1
            }

            is_array ? obj.Push(val) : obj[key] := val
            next := obj == tree ? "" : is_array ? ",]" : ",}"
        }
    }

    return tree[1]
}

Jxon_Dump(obj, indent := "", lvl := 1) {
    if IsObject(obj) {
        if (obj is Array) {
            if (obj.Length == 0)
                return "[]"

            out := "["
            for i, v in obj
                out .= "`n" . indent . Jxon_Dump(v, indent . "  ", lvl+1) . ","
            out := RTrim(out, ",") . "`n" . SubStr(indent, 3) . "]"
            return out

        } else if (obj is Map) {
            if (obj.Count == 0)
                return "{}"

            out := "{"
            for k, v in obj
                out .= "`n" . indent . '"' . k . '": ' . Jxon_Dump(v, indent . "  ", lvl+1) . ","
            out := RTrim(out, ",") . "`n" . SubStr(indent, 3) . "}"
            return out
        }
    }

    if IsNumber(obj)
        return obj
    if (obj == "true" || obj == "false")
        return obj
    if (obj == "")
        return "null"

    obj := StrReplace(obj, "\", "\\")
    obj := StrReplace(obj, '"', '\"')
    obj := StrReplace(obj, "`b", "\b")
    obj := StrReplace(obj, "`f", "\f")
    obj := StrReplace(obj, "`n", "\n")
    obj := StrReplace(obj, "`r", "\r")
    obj := StrReplace(obj, "`t", "\t")

    return '"' . obj . '"'
}
