@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "COMPILER=%ProgramFiles%\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BASE_EXE=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
set "INPUT_AHK=%SCRIPT_DIR%portable-automation.ahk"
set "OUTPUT_EXE=%SCRIPT_DIR%portable-automation.exe"
set "ICON_FILE=%SCRIPT_DIR%main.ico"

if not exist "%COMPILER%" (
  echo Missing compiler: %COMPILER%
  exit /b 1
)

if not exist "%BASE_EXE%" (
  echo Missing base exe: %BASE_EXE%
  exit /b 1
)

if not exist "%INPUT_AHK%" (
  echo Missing input script: %INPUT_AHK%
  exit /b 1
)

if not exist "%ICON_FILE%" (
  echo Missing icon file: %ICON_FILE%
  exit /b 1
)

"%COMPILER%" /in "%INPUT_AHK%" /out "%OUTPUT_EXE%" /icon "%ICON_FILE%" /bin "%BASE_EXE%"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo Build failed with exit code %EXIT_CODE%.
  exit /b %EXIT_CODE%
)

echo Built: %OUTPUT_EXE%
exit /b 0
