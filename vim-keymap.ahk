; Vim key bindings only.
; Edit this file to change key -> action mappings without touching vim-mode.ahk.
;
; Available action kinds:
; - VimAction("motion", "left" | "right" | "up" | "down" | "word_back" | "word_forward" | "word_end" | "line_start" | "line_end" | "doc_start" | "doc_end")
; - VimAction("operator", "d" | "c" | "y")
; - VimAction("operator_motion", { operator: "d", motion: "line_end" })
; - VimAction("delete_char", true|false)
; - VimAction("toggle_visual")
; - VimAction("toggle_visual_line")
; - VimAction("paste")
; - VimAction("history_nav", "back" | "forward")
; - VimAction("char_motion", "f" | "F" | "t" | "T")
; - VimAction("repeat_char_motion", true|false)
; - VimAction("line_operator", "d" | "c" | "y")
; - VimAction("send", "^z")
; - VimAction("set_mode", false)
; - VimAction("insert_after", "{Right}")
; - VimAction("insert_here", "{Home}")
; - VimAction("escape")

global vimKeymap := Map(
    ; Movement
    "h", VimAction("motion", "left"),
    "j", VimAction("motion", "down"),
    "k", VimAction("motion", "up"),
    "l", VimAction("motion", "right"),
    "b", VimAction("motion", "word_back"),
    "w", VimAction("motion", "word_forward"),
    "+w", VimAction("motion", "word_back"),
    "e", VimAction("motion", "word_end"),
    "0", VimAction("motion", "line_start"),
    "+4", VimAction("motion", "line_end"),
    "g", VimAction("motion", "doc_start"),
    "+g", VimAction("motion", "doc_end"),
    "+h", VimAction("history_nav", "back"),
    "+l", VimAction("history_nav", "forward"),
    "f", VimAction("char_motion", "f"),
    "+f", VimAction("char_motion", "F"),
    "t", VimAction("char_motion", "t"),
    "+t", VimAction("char_motion", "T"),
    "n", VimAction("repeat_char_motion", false),
    "+n", VimAction("repeat_char_motion", true),
    ";", VimAction("repeat_char_motion", false),
    ",", VimAction("repeat_char_motion", true),

    ; Editing
    "v", VimAction("toggle_visual"),
    "+v", VimAction("toggle_visual_line"),
    "x", VimAction("delete_char", false),
    "+x", VimAction("delete_char", true),
    "d", VimAction("operator", "d"),
    "+d", VimAction("operator_motion", { operator: "d", motion: "line_end" }),
    "c", VimAction("operator", "c"),
    "+c", VimAction("operator_motion", { operator: "c", motion: "line_end" }),
    "y", VimAction("operator", "y"),
    "+y", VimAction("line_operator", "y"),
    "p", VimAction("paste"),
    "u", VimAction("send", "^z"),

    ; Exit / insert-like commands
    "i", VimAction("insert_here"),
    "+i", VimAction("insert_here", "{Home}"),
    "a", VimAction("insert_after", "{Right}"),
    "+a", VimAction("insert_after", "{End}"),
    "o", VimAction("insert_after", "{End}{Enter}"),
    "+o", VimAction("insert_after", "{Home}{Enter}{Up}")
)

VimRegisterKeymap(vimKeymap)
VimRegisterSuppressedPrintables(vimKeymap)
