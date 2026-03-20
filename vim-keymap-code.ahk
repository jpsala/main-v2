; Vim bindings specific to VS Code / Cursor.

VimHotIfCode(*) {
    try
        return VimHotIf() && (WinActive("ahk_exe Code.exe") || WinActive("ahk_exe Cursor.exe"))
    catch
        return false
}

global vimCodeKeymap := Map(
    "/", VimAction("search"),
    "+7", VimAction("search")
)

VimRegisterKeymap(vimCodeKeymap, VimHotIfCode)
VimRegisterSuppressedPrintables(vimCodeKeymap, VimHotIfCode)
