@echo off
setlocal
"%~dp0RemoteMicRC003.exe" --enable-full-keys
set "exit_code=%ERRORLEVEL%"
if not "%exit_code%"=="0" (
  echo Full-key setup did not complete. See the message from RemoteMicRC003.exe.
  pause
)
exit /b %exit_code%
