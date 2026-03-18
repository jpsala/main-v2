; Vim key bindings only.
; Edit this file to change key -> action mappings without touching vim-mode.ahk.
;
; Available action kinds:
; - VimAction("motion", "left" | "right" | "up" | "down" | "word_back" | "word_forward" | "line_start" | "line_end" | "doc_start" | "doc_end")
; - VimAction("operator", "d" | "c" | "y")
; - VimAction("delete_char", true|false)
; - VimAction("toggle_visual")
; - VimAction("paste")
; - VimAction("send", "^z")
; - VimAction("set_mode", false)
; - VimAction("insert_after", "{Right}")
; - VimAction("escape")

global vimKeymap := Map(
    ; Movement
    "h", VimAction("motion", "left"),
    "j", VimAction("motion", "down"),
    "k", VimAction("motion", "up"),
    "l", VimAction("motion", "right"),
    "b", VimAction("motion", "word_back"),
    "w", VimAction("motion", "word_forward"),
    "0", VimAction("motion", "line_start"),
    "+4", VimAction("motion", "line_end"),
    "g", VimAction("motion", "doc_start"),
    "+g", VimAction("motion", "doc_end"),

    ; Editing
    "v", VimAction("toggle_visual"),
    "x", VimAction("delete_char", false),
    "+x", VimAction("delete_char", true),
    "d", VimAction("operator", "d"),
    "c", VimAction("operator", "c"),
    "y", VimAction("operator", "y"),
    "p", VimAction("paste"),
    "u", VimAction("send", "^z"),

    ; Exit / insert-like commands
    "i", VimAction("set_mode", false),
    "a", VimAction("insert_after", "{Right}"),
    "o", VimAction("insert_after", "{End}{Enter}"),
    "+o", VimAction("insert_after", "{Home}{Enter}{Up}"),
    "Esc", VimAction("escape")
)

VimRegisterKeymap(vimKeymap)
