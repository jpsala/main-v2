; ===================================================================
; Menu definitions - pure data, no helpers
; Action helpers live in menu-actions.ahk
; Engine/dispatch lives in menus-whichkey.ahk
; ===================================================================

FindFirstExistingPath(paths) {
    for _, path in paths {
        if (path && FileExist(path))
            return path
    }
    return ""
}

QuoteCommandPath(path) {
    if (!path)
        return ""
    return InStr(path, " ") ? '"' . path . '"' : path
}

OpenResolvedApp(alias, label, paths, bookmark := false, extraArgs := "") {
    exePath := FindFirstExistingPath(paths)
    if (!exePath) {
        MsgBox(label . " no encontrado en esta notebook/PC")
        return false
    }
    return Roa(alias, QuoteCommandPath(exePath) . extraArgs, bookmark)
}

OpenFolderInExplorer(alias, targetCandidates) {
    targetPath := ""
    for _, path in targetCandidates {
        if (path && (DirExist(path) || FileExist(path))) {
            targetPath := path
            break
        }
    }

    if (!targetPath) {
        MsgBox("No encontre la carpeta o archivo configurado para " . alias)
        return false
    }

    launcher := xyplorerExe && FileExist(xyplorerExe)
        ? QuoteCommandPath(xyplorerExe)
        : QuoteCommandPath(A_WinDir . "\explorer.exe")
    return Roa(alias, launcher . ' "' . targetPath . '"')
}

OpenWindowSpy() {
    SplitPath(A_AhkPath, , &ahkDir)
    return OpenResolvedApp("window-spy", "Window Spy", [ahkDir . "\UX\WindowSpy.ahk"])
}

GetConfigValueWithFallback(key, default := "") {
    global deviceSection
    value := IniRead("config.ini", deviceSection, key, "")
    if (value != "")
        return value
    return IniRead("config.ini", "desktop", key, default)
}

GetDevRoot() {
    configured := GetConfigValueWithFallback("dev_dir", "")
    candidates := []

    if (configured)
        candidates.Push(configured)

    for _, fallback in ["C:\dev", "D:\dev", EnvGet("USERPROFILE") . "\dev", A_ScriptDir . "\.."] {
        if (!fallback)
            continue
        alreadyIncluded := false
        for _, existing in candidates {
            if (existing = fallback) {
                alreadyIncluded := true
                break
            }
        }
        if (!alreadyIncluded)
            candidates.Push(fallback)
    }

    for _, path in candidates {
        if (DirExist(path))
            return path
    }

    return configured ? configured : "C:\dev"
}

JoinPath(basePath, relativePath) {
    if (!basePath)
        return relativePath
    if (SubStr(basePath, -1) = "\" || SubStr(basePath, -1) = "/")
        return basePath . relativePath
    return basePath . "\" . relativePath
}

OpenRepoInEditor(alias, label, editorExe, relativePath, bookmark := false) {
    if (!editorExe) {
        MsgBox(label . ": editor no configurado")
        return false
    }

    targetPath := JoinPath(GetDevRoot(), relativePath)
    if (!DirExist(targetPath) && !FileExist(targetPath)) {
        MsgBox(label . ": no encontre " . targetPath)
        return false
    }

    return Roa(alias, editorExe . ' "' . targetPath . '"', bookmark)
}

OpenFileWithCodeCli(label, folderPath, filePath) {
    if (!DirExist(folderPath)) {
        MsgBox(label . ": no encontre " . folderPath)
        return false
    }

    if (!FileExist(filePath)) {
        MsgBox(label . ": no encontre " . filePath)
        return false
    }

    SplitPath(filePath, &fileName)
    Run(QuoteCommandPath(A_ComSpec) . ' /c cd /d "' . folderPath . '" && code "' . fileName . '"')
    return true
}

; ===================================================================
; Menu A - Apps
; #a
; ===================================================================
GetMainSeqAOptions() {
    return {
        showDelaySeconds: 2,
        items: [
            { key: "a", label: "Audio devices", action: () => ShowAudioDeviceSwitcher() },
            { key: "b", label: "Show Bookmarks", action: () => showBookmarks() },
            { key: "c", label: "SpeedCrunch", action: () => OpenResolvedApp("SpeedCrunch", "SpeedCrunch", ["C:\tools\speedcrunch\speedcrunch.exe", A_ProgramFiles . "\SpeedCrunch\speedcrunch.exe", A_ProgramFiles . " (x86)\SpeedCrunch\speedcrunch.exe"]) },
            { key: "C", label: "LibreOffice Calc", action: () => OpenResolvedApp("libreoffice-calc", "LibreOffice Calc", [A_ProgramFiles . "\LibreOffice\program\scalc.exe", A_ProgramFiles . " (x86)\LibreOffice\program\scalc.exe"]) },
            { key: "n", label: "Constelaciones", idleTimeoutSeconds: 3, items: [
                { key: "d", label: "Dev server: bun run dev", doc: "Runs the local full-stack dev server from C:\dev\chat\constelaciones in a visible terminal.", command: "bun run dev", action: () => RunConstelacionesWebDev() },
                { key: "p", label: "Publish controlled URL: dev + tunnel", doc: "Starts the local dev server and the Cloudflare tunnel for https://turnos.jpsala.dev in separate terminal tabs.", command: "bun run dev; cloudflared tunnel run paperclip-jpsala-dev", action: () => RunConstelacionesPublishControlled() },
                { key: "t", label: "Tunnel only: turnos.jpsala.dev", doc: "Runs only the Cloudflare tunnel used by the controlled public URL.", command: "cloudflared tunnel run paperclip-jpsala-dev", action: () => RunConstelacionesPublicTunnel() },
                { key: "l", label: "Open local app", doc: "Opens http://localhost:3000 in the main browser.", command: "open http://localhost:3000", action: () => OpenConstelacionesLocal() },
                { key: "u", label: "Open public URL", doc: "Opens https://turnos.jpsala.dev in the main browser.", command: "open https://turnos.jpsala.dev", action: () => OpenConstelacionesPublic() },
                { key: "r", label: "Terminal in repo", doc: "Opens Windows Terminal in C:\dev\chat\constelaciones.", command: "wt -d C:\dev\chat\constelaciones", action: () => OpenConstelacionesTerminal() },
                { key: "o", label: "Open repo folder", doc: "Opens C:\dev\chat\constelaciones in Explorer.", command: "explorer C:\dev\chat\constelaciones", action: () => OpenConstelacionesRepoFolder() },
                { key: "v", label: "Open repo in VS Code", doc: "Opens C:\dev\chat\constelaciones in VS Code.", command: "code C:\dev\chat\constelaciones", action: () => OpenRepoInEditor("constelaciones-project", "Constelaciones", vscodeExe, "chat\constelaciones") },
                { key: "c", label: "Checks / build", items: [
                    { key: "k", label: "Check: bun run check", doc: "Runs the root check script, currently format:check then typecheck through apps/web.", command: "bun run check", action: () => RunConstelacionesPackageScript("check") },
                    { key: "b", label: "Build: bun run build", doc: "Builds apps/web through the root package script.", command: "bun run build", action: () => RunConstelacionesPackageScript("build") },
                    { key: "l", label: "Lint: bun run lint", doc: "Runs apps/web lint through the root package script.", command: "bun run lint", action: () => RunConstelacionesPackageScript("lint") },
                    { key: "f", label: "Format check", doc: "Runs Prettier check through apps/web.", command: "bun run format:check", action: () => RunConstelacionesPackageScript("format:check") },
                    { key: "t", label: "Typecheck", doc: "Runs TypeScript typecheck through apps/web.", command: "bun run typecheck", action: () => RunConstelacionesPackageScript("typecheck") },
                ] },
                { key: "w", label: "WhatsApp / CRM scripts", items: [
                    { key: "i", label: "Import Ro WhatsApp", doc: "Imports Rocio WhatsApp data through the project script.", command: "bun run import:whatsapp:ro", action: () => RunConstelacionesPackageScript("import:whatsapp:ro") },
                    { key: "s", label: "Sync Ro WhatsApp mirror", doc: "Syncs the local WhatsApp mirror for Rocio.", command: "bun run sync:whatsapp:ro", action: () => RunConstelacionesPackageScript("sync:whatsapp:ro") },
                    { key: "j", label: "CRM sync job once", doc: "Runs the WhatsApp CRM sync job once in a visible terminal.", command: "bun run whatsapp:crm:sync-job", action: () => RunConstelacionesPackageScript("whatsapp:crm:sync-job") },
                    { key: "T", label: "Install CRM sync task", doc: "Installs the periodic Windows task for WhatsApp CRM sync.", command: "bun run whatsapp:crm:install-task", action: () => RunConstelacionesPackageScript("whatsapp:crm:install-task") },
                    { key: "n", label: "Resolve names Ro", doc: "Runs the OpenRouter contact-name resolver.", command: "bun run names:resolve:ro", action: () => RunConstelacionesPackageScript("names:resolve:ro") },
                    { key: "p", label: "Check payment proofs Ro", doc: "Runs the payment proof checker with sync enabled.", command: "bun run check:payment-proofs:ro", action: () => RunConstelacionesPackageScript("check:payment-proofs:ro") },
                    { key: "r", label: "Rebuild CRM Ro", doc: "Rebuilds CRM records from the WhatsApp mirror.", command: "bun run rebuild:crm:ro", action: () => RunConstelacionesPackageScript("rebuild:crm:ro") },
                    { key: "a", label: "AI review Ro", doc: "Runs the OpenRouter AI review script.", command: "bun run ai:review:ro", action: () => RunConstelacionesPackageScript("ai:review:ro") },
                ] },
                { key: "x", label: "Data / cleanup scripts", items: [
                    { key: "c", label: "Clean test bookings/payments (no confirm)", doc: "Runs the safe pre-production cleanup script as declared in package.json, without adding --confirm. It preserves CRM/WhatsApp, places, encounters, templates and webhook events.", command: "bun run db:clean-test-bookings-payments", action: () => RunConstelacionesPackageScript("db:clean-test-bookings-payments") },
                ] },
                { key: "i", label: "Context index scripts", items: [
                    { key: "i", label: "Context index", doc: "Regenerates docs/.generated/context-index.md.", command: "bun run context:index", action: () => RunConstelacionesPackageScript("context:index") },
                    { key: "a", label: "Context audit", doc: "Audits project docs/topics/tasks context coherence.", command: "bun run context:audit", action: () => RunConstelacionesPackageScript("context:audit") },
                    { key: "r", label: "Context refresh", doc: "Runs the context refresh script.", command: "bun run context:refresh", action: () => RunConstelacionesPackageScript("context:refresh") },
                ] },
            ] },
            { key: "e", label: "Electro Bun Deploy / Release", idleTimeoutSeconds: 3, items: [
                { key: "r", label: "Restart server/dev runtime", doc: "Restarts the Fixvox/Electro Bun dev runtime in background. Use after code changes or when the local app/server is stale.", command: "bun scripts/restart-dev.ts", action: () => RunElectroBunDev() },
                { key: "u", label: "Other PC: create + upload installer", doc: "Full handoff release for another computer: runs focused control-plane tests, deploys proxy/admin secrets, creates Fixvox-Installer.exe, uploads the installer/update artifacts to GitHub, then prints the release and installer URLs.", command: "tests; deploy proxy; bun run package:win creates and uploads Fixvox-Installer.exe; verify GitHub release", action: () => RunElectroBunOtherPcReadyRelease() },
                { key: "p", label: "Publish installer + update artifacts", doc: "Builds the Windows installer, uploads GitHub release artifacts, and deploys production backend so other PCs can update. Uses the production release flow with SkipProductionSecret.", command: "scripts/publish-windows-release.ps1 -DeployProduction -SkipProductionSecret", action: () => RunElectroBunPublishProdArtifacts() },
                { key: "b", label: "Build installer locally", doc: "Builds the stable Windows installer locally with -SkipPublish and opens the output folder. Does not upload artifacts or deploy production.", command: "scripts/build-windows-installer.ps1 -SkipPublish; open installer folder", action: () => RunElectroBunInstallerOnly() },
                { key: "o", label: "Open latest installer", doc: "Opens Explorer selecting the newest generated installer if present, otherwise opens the output folder.", command: "scripts/open-windows-installer-location.ps1", action: () => RunElectroBunOpenInstallerFolder() },
                { key: "d", label: "Dry-run production release", doc: "Prints the production deploy/build/upload commands without executing them.", command: "scripts/publish-windows-release.ps1 -DeployProduction -DryRun", action: () => RunElectroBunProdDryRun() },
                { key: "g", label: "Check GitHub auth", doc: "Runs gh auth status to confirm GitHub CLI can create/upload releases. Does not change release state.", command: "gh auth status", action: () => RunElectroBunDeployCommand("gh auth status", "gh auth status") },
                { key: "t", label: "Run tests", doc: "Runs bun test from C:\dev\electro-bun-1. Does not build, deploy, or upload anything.", command: "bun test", action: () => RunElectroBunDeployCommand("bun test", "bun test") },
                { key: "v", label: "Build views", doc: "Runs bun run build:views. Useful before packaging when only frontend/screens changed.", command: "bun run build:views", action: () => RunElectroBunPackageScript("build:views") },
                { key: "h", label: "Help: explain this menu", doc: "Opens a generated local documentation window for current menu entries. Does not run build, deploy, install, or release commands.", command: "ShowElectroBunMenuDocs()", action: () => ShowElectroBunMenuDocs() },
            ] },
            { key: "p", label: "Copicu clipboard app", idleTimeoutSeconds: 3, items: [
                { key: "r", label: "Restart dev app", doc: "Runs Copicu's dev restart script. Stops repo-owned Copicu/Vite/Tauri processes, starts dev mode, waits for readiness, and writes logs under .codex-run/dev-restart.", command: "npm run dev:restart", action: () => RunCopicuRestartDev() },
                { key: "k", label: "Kill dev app", doc: "Stops Copicu dev/runtime processes associated with this repo, including the Vite port owner when present.", command: "stop copicu.exe / tauri / vite on port 1420", action: () => RunCopicuKillDev() },
                { key: "o", label: "Open repo folder", doc: "Opens C:\dev\chat\copyq-tauri in Explorer. Does not open VS Code or another editor.", command: "explorer C:\dev\chat\copyq-tauri", action: () => OpenCopicuRepoFolder() },
                { key: "t", label: "Terminal in repo", doc: "Opens Windows Terminal in C:\dev\chat\copyq-tauri.", command: "wt -d C:\dev\chat\copyq-tauri", action: () => OpenCopicuTerminal() },
                { key: "i", label: "Build installer and run", doc: "Builds the Tauri NSIS installer, finds the newest *-setup.exe under src-tauri\target\release\bundle\nsis, and launches it so you can continue the installer manually.", command: "npm run tauri:build; run newest *-setup.exe", action: () => RunCopicuBuildAndRunInstaller() },
                { key: "b", label: "Build frontend", doc: "Runs npm run build from the Copicu repo.", command: "npm run build", action: () => RunCopicuBuild() },
                { key: "c", label: "Cargo check", doc: "Runs cargo check from src-tauri using a separate target dir for quick validation.", command: "cd src-tauri; cargo check", action: () => RunCopicuCargoCheck() },
                { key: "v", label: "Visual checks", doc: "Runs npm run visual:check from the Copicu repo.", command: "npm run visual:check", action: () => RunCopicuVisualCheck() },
            ] },
            { key: "f", label: "File Explorer", action: () => Roa("file-explorer", QuoteCommandPath(A_WinDir . "\explorer.exe")) },
            { key: "M", label: "Mixer", action: () => openMixer() },
            { key: "s", label: "Spotify", action: () => Roa("spotify", "spotify.exe") },
            { key: "S", label: "ShareX screenshots", action: () => OpenFolderInExplorer("sharex-folder", [EnvGet("USERPROFILE") . "\Pictures\ShareX", EnvGet("USERPROFILE") . "\Pictures\sharex", EnvGet("USERPROFILE") . "\Pictures"]) },
            { key: "v", label: "Web Clipboard Sender", action: () => OpenWebClipboardSender() },
            { key: "w", label: "Restart Wispr Flow", action: () => RestartWisprFlow() },
            { key: "t", label: "tablet/telegram/terminal", items: [
                { key: "t", label: "Windows Terminal", action: () => OpenResolvedApp("windows-terminal", "Windows Terminal", [EnvGet("LOCALAPPDATA") . "\Microsoft\WindowsApps\wt.exe", A_ProgramFiles . "\WindowsApps\Microsoft.WindowsTerminal_1.23.20211.0_x64__8wekyb3d8bbwe\wt.exe"]) },
                { key: "T", label: "Telegram", action: () => OpenResolvedApp("telegram", "Telegram", ["C:\tools\Telegram\Telegram.exe", A_AppData . "\Telegram Desktop\Telegram.exe", EnvGet("LOCALAPPDATA") . "\Programs\Telegram Desktop\Telegram.exe"]) },
                { key: "a", label: "Tablet", action: () => RunScrcpyTablet() },
                { key: "p3", label: "Phone 700px", chordPath: ["p", "3"], chordPathLabel: "Phone", action: () => RunScrcpyPhone(700) },
                { key: "p4", label: "Phone 900px", chordPath: ["p", "4"], chordPathLabel: "Phone", action: () => RunScrcpyPhone(900) },
            ] },
            { key: "i", label: "Clipboard Agent (AI)", action: () => RunClipboardAgent() },
            { key: "x", label: "XYplorer", action: () => Roa("xyplorer", xyplorerExe) },
            { key: "y", label: "Window Spy", action: () => OpenWindowSpy() },
        ]
    }
}

; ===================================================================
; Menu W - Browser & Web
; #w
; ===================================================================
GetMainSeqWOptions() {
    return {
        showDelaySeconds: 1,
        items: [
            ; { key: "$", label: "USD" },
            { key: "a", label: "AI", action: () => OpenRepoInEditor("ai-project", "AI", cursorExe, "ai") },
            ; { key: "A", label: "Amaia", action: () => OpenRepoInEditor("amaia-project", "Amaia", cursorExe, "amaia") },
            ; { key: "b", label: "Browser Books", action: () => Roa("vivaldi-books", vivaldiWithBooksProfile, "#b") },
            { key: "c", label: "Browser Carnival", action: () => OpenBrowserProfile("chrome-carnival", vivaldiWithCarnivalProfile) },
            { key: "C", label: "Constelaciones", idleTimeoutSeconds: 3, items: [
                { key: "d", label: "Dev server: bun run dev", doc: "Runs the local full-stack dev server from C:\dev\chat\constelaciones in a visible terminal.", command: "bun run dev", action: () => RunConstelacionesWebDev() },
                { key: "p", label: "Publish controlled URL: dev + tunnel", doc: "Starts the local dev server and the Cloudflare tunnel for https://turnos.jpsala.dev in separate terminal tabs.", command: "bun run dev; cloudflared tunnel run paperclip-jpsala-dev", action: () => RunConstelacionesPublishControlled() },
                { key: "t", label: "Tunnel only: turnos.jpsala.dev", doc: "Runs only the Cloudflare tunnel used by the controlled public URL.", command: "cloudflared tunnel run paperclip-jpsala-dev", action: () => RunConstelacionesPublicTunnel() },
                { key: "l", label: "Open local app", doc: "Opens http://localhost:3000 in the main browser.", command: "open http://localhost:3000", action: () => OpenConstelacionesLocal() },
                { key: "u", label: "Open public URL", doc: "Opens https://turnos.jpsala.dev in the main browser.", command: "open https://turnos.jpsala.dev", action: () => OpenConstelacionesPublic() },
                { key: "r", label: "Terminal in repo", doc: "Opens Windows Terminal in C:\dev\chat\constelaciones.", command: "wt -d C:\dev\chat\constelaciones", action: () => OpenConstelacionesTerminal() },
                { key: "o", label: "Open repo folder", doc: "Opens C:\dev\chat\constelaciones in Explorer.", command: "explorer C:\dev\chat\constelaciones", action: () => OpenConstelacionesRepoFolder() },
                { key: "v", label: "Open repo in VS Code", doc: "Opens C:\dev\chat\constelaciones in VS Code.", command: "code C:\dev\chat\constelaciones", action: () => OpenRepoInEditor("constelaciones-project", "Constelaciones", vscodeExe, "chat\constelaciones") },
                { key: "c", label: "Checks / build", items: [
                    { key: "k", label: "Check: bun run check", doc: "Runs the root check script, currently format:check then typecheck through apps/web.", command: "bun run check", action: () => RunConstelacionesPackageScript("check") },
                    { key: "b", label: "Build: bun run build", doc: "Builds apps/web through the root package script.", command: "bun run build", action: () => RunConstelacionesPackageScript("build") },
                    { key: "l", label: "Lint: bun run lint", doc: "Runs apps/web lint through the root package script.", command: "bun run lint", action: () => RunConstelacionesPackageScript("lint") },
                    { key: "f", label: "Format check", doc: "Runs Prettier check through apps/web.", command: "bun run format:check", action: () => RunConstelacionesPackageScript("format:check") },
                    { key: "t", label: "Typecheck", doc: "Runs TypeScript typecheck through apps/web.", command: "bun run typecheck", action: () => RunConstelacionesPackageScript("typecheck") },
                ] },
                { key: "w", label: "WhatsApp / CRM scripts", items: [
                    { key: "i", label: "Import Ro WhatsApp", doc: "Imports Rocio WhatsApp data through the project script.", command: "bun run import:whatsapp:ro", action: () => RunConstelacionesPackageScript("import:whatsapp:ro") },
                    { key: "s", label: "Sync Ro WhatsApp mirror", doc: "Syncs the local WhatsApp mirror for Rocio.", command: "bun run sync:whatsapp:ro", action: () => RunConstelacionesPackageScript("sync:whatsapp:ro") },
                    { key: "j", label: "CRM sync job once", doc: "Runs the WhatsApp CRM sync job once in a visible terminal.", command: "bun run whatsapp:crm:sync-job", action: () => RunConstelacionesPackageScript("whatsapp:crm:sync-job") },
                    { key: "T", label: "Install CRM sync task", doc: "Installs the periodic Windows task for WhatsApp CRM sync.", command: "bun run whatsapp:crm:install-task", action: () => RunConstelacionesPackageScript("whatsapp:crm:install-task") },
                    { key: "n", label: "Resolve names Ro", doc: "Runs the OpenRouter contact-name resolver.", command: "bun run names:resolve:ro", action: () => RunConstelacionesPackageScript("names:resolve:ro") },
                    { key: "p", label: "Check payment proofs Ro", doc: "Runs the payment proof checker with sync enabled.", command: "bun run check:payment-proofs:ro", action: () => RunConstelacionesPackageScript("check:payment-proofs:ro") },
                    { key: "r", label: "Rebuild CRM Ro", doc: "Rebuilds CRM records from the WhatsApp mirror.", command: "bun run rebuild:crm:ro", action: () => RunConstelacionesPackageScript("rebuild:crm:ro") },
                    { key: "a", label: "AI review Ro", doc: "Runs the OpenRouter AI review script.", command: "bun run ai:review:ro", action: () => RunConstelacionesPackageScript("ai:review:ro") },
                ] },
                { key: "x", label: "Data / cleanup scripts", items: [
                    { key: "c", label: "Clean test bookings/payments (no confirm)", doc: "Runs the safe pre-production cleanup script as declared in package.json, without adding --confirm. It preserves CRM/WhatsApp, places, encounters, templates and webhook events.", command: "bun run db:clean-test-bookings-payments", action: () => RunConstelacionesPackageScript("db:clean-test-bookings-payments") },
                ] },
                { key: "i", label: "Context index scripts", items: [
                    { key: "i", label: "Context index", doc: "Regenerates docs/.generated/context-index.md.", command: "bun run context:index", action: () => RunConstelacionesPackageScript("context:index") },
                    { key: "a", label: "Context audit", doc: "Audits project docs/topics/tasks context coherence.", command: "bun run context:audit", action: () => RunConstelacionesPackageScript("context:audit") },
                    { key: "r", label: "Context refresh", doc: "Runs the context refresh script.", command: "bun run context:refresh", action: () => RunConstelacionesPackageScript("context:refresh") },
                ] },
            ] },
            { key: "m", label: "chrome-main", action: () => Roa("chrome-main", browserWithChromeMainProfile) },
            { key: "d", label: "Debug with chrome", chordHidden: true },
            ; { key: "x", label: "Chrome Debug", action: () => OpenChromeDebugCopy() }
            { key: "D", label: "Debug with vivaldi", action: () => Run(vivaldiWithDebugProfile) },
            { key: "f", label: "Browser Main", action: () => OpenMainBrowser() },
            { key: "d", label: "Vivaldi debug", action: () => Run(vivaldiWithDebugProfile) },
            { key: "s", label: "Sites", items: [
                ; { key: "g", label: "Gemini", action: () => Roa("vivaldi-gemini", vivaldiWithGeminProfile . " https://gemini.google.com/ --new-window", "#i") },
                ; { key: "j", label: "Jitsi", action: () => Roa("jitsi-meet", vivaldiWithMainProfile . " https://meet.jit.si/JP_ALFRE_REDACTED_SECRET") },
                { key: "g", label: "Google", items: [
                    { key: "a", label: "jpsala.ai", action: () => OpenBrowserProfile("jpsala-ai", vivaldiWithJpsalaAiProfile) },
                    { key: "w", label: "jpsala.work", action: () => OpenBrowserProfile("jpsala-work", vivaldiWithJpsalaWorkProfile) },
                    { key: "v", label: "jpsala.dev", action: () => OpenBrowserProfile("jpsala-dev", vivaldiWithJpsalaDevProfile) },
                    { key: "A", label: "jpsala.alt", action: () => OpenBrowserProfile("jpsala-alt", vivaldiWithJpsalaAltProfile) },
                    { key: "c", label: "Google Calendar", action: () => OpenUrlWithBrowser("google-calendar", "https://calendar.google.com/calendar/u/0/r", vivaldiWithMainProfile) },
                    { key: "d", label: "Google Drive", action: () => OpenUrlWithBrowser("google-drive", "https://drive.google.com/drive/my-drive?ths=true", vivaldiWithMainProfile) },
                    { key: "e", label: "Google Keep", action: () => OpenUrlWithBrowser("google-keep", "https://keep.google.com/", vivaldiWithMainProfile) },
                ] },
                { key: "e", label: "Opencode Proxy", action: () => OpenUrlWithBrowser("opencode-proxy-management", "http://127.0.0.1:8317/management.html#/quota", vivaldiWithMainProfile) },
                ; { key: "m", label: "Google Mail", action: () => Roa("google-mail", vivaldiWithMainProfile . " https://mail.google.com") },
                ; { key: "u", label: "Cursor Dashboard", action: () => Roa("cursor-dashboard", vivaldiWithMainProfile . " https://cursor.com/dashboard?tab=billing") }
                ; { key: "t", label: "TradingView", action: () => Roa("tradingview", vivaldiWithMainProfile . " https://www.tradingview.com/chart") },
            ] },
            ; { key: "F", label: "Chrome Debug", action: () => Run(chromeWithDebugProfile) },
            ; { key: "g", label: "Browser AI", action: () => Roa("vivaldi-ai", vivaldiWithAIProfile, "#g") },
            ; { key: "G", label: "Browser Gordos", action: () => Run(vivaldiWithGordosProfile) },
            ; { key: "r", label: "Debug", chordHidden: true },
            ; { key: "w", label: "Work", action: () => Roa("browser-work", chromeWithWorkProfile) },
            ; { key: "#w", label: "Work (Alt)", chordHidden: true },
            ; { key: "#d", label: "chrome-debug (Alt)", chordHidden: true },
            { key: "v", label: "Youtube", action: () => OpenBrowserProfile("vivaldi-youtube", vivaldiWithYoutubeProfile, "#v") },
            { key: "w", label: "Web Clipboard Sender", action: () => OpenWebClipboardSender() },
            ; { key: "yv", label: "YouTube Video Downloader", chordPath: ["y", "v"], chordPathLabel: "YouTube DL", action: () => DownloadYouTubeVideoFromClipboard() },
            ; { key: "ya", label: "YouTube Audio Downloader", chordPath: ["y", "a"], chordPathLabel: "YouTube DL", action: () => DownloadYouTubeAudioFromClipboard() },
            ; { key: "V", label: "Vivaldi (App)", action: () => Roa("vivaldi", vivaldiExe) },
        ]
    }
}

; ===================================================================
; Menu ` - CopyQ
; ===================================================================
GetCopyQOptions() {
        return {
            showDelaySeconds: 1,
            items: [
                { key: "c", label: "Smart Copy", items: [
                    { key: "c", label: "Clipboard", action: () => CopyQ_SmartCopyToTab("&clipboard") },
                    { key: "p", label: "Pass", action: () => CopyQ_SmartCopyToTab("pass") },
                ] },
                { key: "e", label: "Export selected images", action: () => CopyQ_ExportSelectedImages() },
                { key: "Q", label: "CopyQ (save window)", action: () => OpenCopyQSaveWindow() },
                { key: "p", label: "Send item to pass", action: () => CopyQ_SendItemToPass() },
            ]
        }
}

; ===================================================================
; Menu C - Code
; ===================================================================
GetMainSeqCOptions() {
    return {
        showDelaySeconds: 1,
        items: [
            ; { key: "M", label: "Main script with cursor", action: () => OpenRepoInEditor("main-scripts", "Main script with cursor", cursorExe, "scripts\main", "!m") },
            { key: "a", label: "auto.ahk in vscode", action: () => OpenFileWithCodeCli("auto.ahk in vscode", A_ScriptDir, A_ScriptDir . "\auto.ahk") },
            { key: "m", label: "Main script with vscode", action: () => OpenRepoInEditor("main-scripts", "Main script with vscode", vscodeExe, "scripts\main", "!m") },
            { key: "t", label: "Chat", action: () => OpenRepoInEditor("chat", "Chat", vscodeExe, "chat", "#t") },
            { key: "C", label: "Code", action: () => RoAWithPattern("ahk_exe Code.exe", vscodeExe, "^!c") },
            { key: "c", label: "Cursor", action: () => Roa("cursor", vscodeExe) },
            { key: "l", label: "Claude Code", action: () => Roa("claude-code", 'wt --size 90,35 -p "Claude" -- claude --dangerously-skip-permissions --chrome --ide ') },
            { key: "q", label: "copyQ data", action: () => OpenFolderInExplorer("copyq-backup", ["D:\user-home-in-d\Documents\copyq-backup", EnvGet("USERPROFILE") . "\Documents\copyq-backup"]) },
            { key: "p", label: "Passwords", action: () => OpenFolderInExplorer("passwords-backup", ["D:\user-home-in-d\Documents\Chrome Passwords Backup.csv", EnvGet("USERPROFILE") . "\Documents\Chrome Passwords Backup.csv"]) },
        ]
    }
}
