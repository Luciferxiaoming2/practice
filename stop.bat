@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================================
REM  ENDPAGE - Stop script (Windows local dev)
REM ============================================================

set "PROJECT_ROOT=%~dp0"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "LOCK_FILE=%PROJECT_ROOT%\.endpage.lock"
set "BACKEND_PORT=8000"
set "FRONTEND_PORT=3000"

echo.
echo  ================================================
echo     ENDPAGE Stop
echo  ================================================
echo.

REM ---------- 1. Read lock file ----------
if exist "%LOCK_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%LOCK_FILE%"') do (
        if "%%a"=="BACKEND_PORT" set "BACKEND_PORT=%%b"
        if "%%a"=="FRONTEND_PORT" set "FRONTEND_PORT=%%b"
    )
    echo  [INFO]  Ports: Backend=%BACKEND_PORT% / Frontend=%FRONTEND_PORT%
) else (
    echo  [INFO]  No lock file, using defaults: 8000/3000
)
echo.

REM ---------- 2. Stop by port ----------
set "STOPPED=0"

for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /r ":%BACKEND_PORT% .*LISTENING"') do (
    if not "%%a"=="0" (
        echo  [STOP]  Killing Backend on port %BACKEND_PORT% ^(PID %%a^)
        taskkill /PID %%a /T /F >nul 2>&1
        set "STOPPED=1"
    )
)

for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /r ":%FRONTEND_PORT% .*LISTENING"') do (
    if not "%%a"=="0" (
        echo  [STOP]  Killing Frontend on port %FRONTEND_PORT% ^(PID %%a^)
        taskkill /PID %%a /T /F >nul 2>&1
        set "STOPPED=1"
    )
)

REM ---------- 3. Close named terminal windows ----------
taskkill /FI "WINDOWTITLE eq ENDPAGE-Backend*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq ENDPAGE-Frontend*" /F >nul 2>&1

REM ---------- 4. Remove ADB forwarding ----------
where adb >nul 2>&1
if !errorlevel!==0 (
    adb reverse --remove-all >nul 2>&1
    echo  [OK]   ADB forwarding removed
)

REM ---------- 5. Clean up ----------
if exist "%LOCK_FILE%" del "%LOCK_FILE%" >nul 2>&1

echo.
if "!STOPPED!"=="1" (
    echo  ================================================
    echo     All services stopped.
    echo  ================================================
) else (
    echo  ================================================
    echo     No running services found.
    echo  ================================================
)
echo.
timeout /t 3 /nobreak >nul
exit /b 0
