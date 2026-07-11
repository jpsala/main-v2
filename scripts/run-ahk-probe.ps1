param(
    [string]$Script = "tests/command-palette-probe.ahk",
    [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$scriptPath = [IO.Path]::GetFullPath((Join-Path $root $Script))
$ahk = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$process = $null

try {
    if (-not (Test-Path $scriptPath)) { throw "Probe not found: $scriptPath" }
    if (-not (Test-Path $ahk)) { throw "AutoHotkey v2 not found: $ahk" }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $ahk
    $startInfo.Arguments = '/ErrorStdOut "{0}"' -f $scriptPath
    $startInfo.WorkingDirectory = $root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "Could not start AutoHotkey probe" }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        $process.WaitForExit()
        throw "Probe timed out after $TimeoutSeconds seconds"
    }

    $stdout = $stdoutTask.GetAwaiter().GetResult().Trim()
    $stderr = $stderrTask.GetAwaiter().GetResult().Trim()
    $exitCode = $process.ExitCode
    if ($exitCode -ne 0 -or $stderr -or $stdout -ne "PASS") {
        throw "Probe failed (exit=$exitCode)`nSTDOUT:`n$stdout`nSTDERR:`n$stderr"
    }

    Write-Output "PASS $Script"
} finally {
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq "AutoHotkey64.exe" -and $_.CommandLine -like "*$Script*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    if ($process) { $process.Dispose() }
}
