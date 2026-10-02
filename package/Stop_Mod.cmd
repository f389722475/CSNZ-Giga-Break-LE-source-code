@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not exist "%~dp0payload\CSNZ_LENative.exe" (
  echo Missing payload\CSNZ_LENative.exe. Extract the complete deployment ZIP first.
  pause
  exit /b 1
)
if not exist "%~dp0payload\native.ini" (
  echo Not configured. Run Install.cmd in this package first.
  pause
  exit /b 1
)
"%~dp0payload\CSNZ_LENative.exe" --stop
set "result=%errorlevel%"
pause
exit /b %result%
