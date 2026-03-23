; Example chord registrations for the standalone chord-hotkeys module.
; Press Alt+T to show the hint overlay.
;
; Alt+T, then:
; - C: Fix Writing
; - E: Translate to English
; - M: Manual submenu
; - S: Traducir a espanol
;
; Inside M:
; - A: Manual Alpha
; - D: Manual Docs
; - O: Manual Ops submenu
; - R: Manual Reload
;
; Inside M > O:
; - L: Manual Logs
; - T: Manual Tasks

HandleExampleChordCommand(commandName) {
    switch commandName {
    case "fix_writing":
        msg("Fix Writing")
    case "translate_to_english":
        msg("Translate to English")
    case "manual_alpha":
        msg("Manual Alpha")
    case "manual_docs":
        msg("Manual Docs")
    case "manual_logs":
        msg("Manual Logs")
    case "manual_reload":
        msg("Manual Reload")
    case "manual_tasks":
        msg("Manual Tasks")
    case "translate_to_spanish":
        msg("Traducir a espanol")
    default:
        msg("Unknown chord: " . commandName)
    }
}

InitExampleChords() {
    ChordSetHintDelay(0.8)
    ChordSetTimeout(3.5)

    exampleChordMap := Map(
        "!t", Map(
            "c", ChordEntry("fix_writing", "Fix Writing"),
            "e", ChordEntry("translate_to_english", "Translate to English"),
            "m", {
                label: "Manual",
                hintDelay: 1,
                items: Map(
                    "a", ChordEntry("manual_alpha", "Manual Alpha"),
                    "d", ChordEntry("manual_docs", "Manual Docs"),
                    "o", {
                        label: "Manual Ops",
                        hintDelay: 1,
                        items: Map(
                            "l", ChordEntry("manual_logs", "Manual Logs"),
                            "t", ChordEntry("manual_tasks", "Manual Tasks")
                        )
                    },
                    "r", ChordEntry("manual_reload", "Manual Reload")
                )
            },
            "s", ChordEntry("translate_to_spanish", "Traducir a espanol")
        )
    )

    ChordRegister(exampleChordMap, HandleExampleChordCommand)
}


