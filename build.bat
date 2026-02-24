@echo off
REM Build script for Main.ahk automation tool
REM Compiles the AHK script to executable and packages distribution files

setlocal enabledelayedexpansion

echo ======================================
echo Building Main.ahk Automation Tool
echo ======================================
echo.

REM Check if Ahk2Exe compiler exists
set "AHK_COMPILER=C:\Users\jsa6055\AppData\Local\Programs\AutoHotkey\Compiler\Ahk2Exe.exe"
set "AHK_BASE=C:\Users\jsa6055\AppData\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe"
if not exist "%AHK_COMPILER%" (
    echo ERROR: AutoHotkey compiler not found at:
    echo %AHK_COMPILER%
    echo.
    echo Please install AutoHotkey v2 from https://www.autohotkey.com/
    pause
    exit /b 1
)

echo [1/5] Cleaning previous build...
if exist "dist" (
    rmdir /s /q "dist"
)
mkdir "dist"

echo.
echo [2/5] Compiling main.ahk to main.exe...
"%AHK_COMPILER%" /in "main.ahk" /out "dist\main.exe" /icon "main.ico" /base "%AHK_BASE%"

if errorlevel 1 (
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo.
echo [3/5] Copying required files to dist\...

REM Copy libraries
echo - Copying lib\ folder...
xcopy /E /I /Y "lib" "dist\lib\" >nul

REM Copy UI files
echo - Copying ui\ folder...
xcopy /E /I /Y "ui" "dist\ui\" >nul

REM Copy icons and config templates
echo - Copying icons and config files...
copy /Y "main.ico" "dist\" >nul
copy /Y "icon.ico" "dist\" >nul
copy /Y "config.ini.dist" "dist\config.ini" >nul

REM Copy documentation
if exist "README.md" copy /Y "README.md" "dist\" >nul

echo.
echo [4/5] Creating zip distribution...
powershell -Command "Compress-Archive -Path 'dist\*' -DestinationPath 'main-automation-dist.zip' -Force"

if errorlevel 1 (
    echo WARNING: Failed to create zip file
) else (
    echo SUCCESS: main-automation-dist.zip created
)

echo.
echo [5/5] Creating installer with Inno Setup...
set INNO_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe
if not exist "%INNO_PATH%" goto :skip_installer

"%INNO_PATH%" "installer.iss"
if errorlevel 1 (
    echo WARNING: Installer compilation failed
    goto :installer_done
)
echo SUCCESS: main-automation-setup.exe created
goto :installer_done

:skip_installer
echo SKIPPED: Inno Setup not found at:
echo %INNO_PATH%
echo Install from https://jrsoftware.org/isinfo.php to create installer

:installer_done

echo.
echo ======================================
echo Build Complete!
echo ======================================
echo.
echo Output files:
echo - dist\main.exe (executable)
echo - main-automation-dist.zip (portable distribution)
if exist "main-automation-setup.exe" echo - main-automation-setup.exe (installer)
echo.
pause
