# Script para limpiar config.ini
Write-Host "=== LIMPIEZA DE CONFIG.INI ===" -ForegroundColor Cyan

# Leer archivo
$lines = Get-Content config.ini -Encoding Unicode
$newLines = @()
$currentSection = ''
$removed = @()
$logVisCount = 0

foreach ($line in $lines) {
    $trim = $line.Trim()
    
    if ($trim -match '^\[(.+)\]$') {
        $currentSection = $matches[1]
        $logVisCount = 0
        $newLines += $line
        continue
    }
    
    if ($trim -eq '' -or $trim.StartsWith(';')) {
        $newLines += $line
        continue
    }
    
    if ($trim -match '^([^=]+)=') {
        $key = $matches[1].Trim()
        $skip = $false
        
        # Variables section
        if ($currentSection -eq 'variables') {
            if ($key -eq 'logVisibility') {
                $logVisCount++
                if ($logVisCount -gt 1) {
                    $removed += "[$currentSection] $key (duplicado)"
                    $skip = $true
                }
            }
            elseif ($key -in @('serialNumber', 'tvactive', 'tvBacktesting', 'tvBarVisible', 'tvMode')) {
                $removed += "[$currentSection] $key"
                $skip = $true
            }
        }
        
        # Paths section
        if ($currentSection -eq 'paths' -and $key -in @('icon_wrench', 'sound_start', 'sound_stop')) {
            $removed += "[$currentSection] $key"
            $skip = $true
        }
        
        # Device sections
        if ($currentSection -in @('desktop', 'work', 'carnival', 'notebook', 'gordos')) {
            if ($key -in @('kenv_scripts_dir', 'kit_dir')) {
                $removed += "[$currentSection] $key"
                $skip = $true
            }
            if ($currentSection -eq 'notebook' -and $key -eq 'fsTouch_exe') {
                $removed += "[$currentSection] $key"
                $skip = $true
            }
        }
        
        if (-not $skip) {
            $newLines += $line
        }
    } else {
        $newLines += $line
    }
}

# Guardar
$newLines | Out-File config.ini -Encoding Unicode -Force

Write-Host "`n--- Keys Removidas ---" -ForegroundColor Yellow
foreach ($item in $removed) {
    Write-Host "  ✗ $item" -ForegroundColor Red
}
Write-Host "`n✓ Total removido: $($removed.Count) keys" -ForegroundColor Green
Write-Host "✓ config.ini actualizado (backup: config.ini.backup)" -ForegroundColor Green
