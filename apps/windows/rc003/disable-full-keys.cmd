@echo off
setlocal
"%~dp0RemoteMicRC003.exe" --disable-full-keys
set "exit_code=%ERRORLEVEL%"
if not "%exit_code%"=="0" (
  echo Full-key removal did not complete. See the message from RemoteMicRC003.exe.
  pause
)
exit /b %exit_code%
