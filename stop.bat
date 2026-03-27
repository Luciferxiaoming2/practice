@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================================
REM  ENDPAGE - Stop script (Windows local dev)
REM
REM  Usage:
REM    1. Double-click stop.bat to stop all running services
REM    2. Or run in terminal: stop.bat
REM    3. Reads port info from .endpage.lock (written by start.bat)
REM ============================================================

set "PROJECT_ROOT=D:\practice\one"
set "LOCK_FILE=%PROJECT_ROOT%\.endpage.lock"
set "BACKEND_PORT="
set "FRONTEND_PORT="

echo.
echo  ================================================
echo     ENDPAGE Stop
echo  ================================================
echo.

REM ---------- 1. Read lock file ----------
if not exist "%LOCK_FILE%" goto :no_lock

for /f "tokens=1,* delims==" %%a in ('type "%LOCK_FILE%"') do (
    if "%%a"=="BACKEND_PORT" set "BACKEND_PORT=%%b"
    if "%%a"=="FRONTEND_PORT" set "FRONTEND_PORT=%%b"
)

if not defined BACKEND_PORT goto :no_lock
if not defined FRONTEND_PORT goto :no_lock

echo  [INFO]  Lock file found (Backend:%BACKEND_PORT% / Frontend:%FRONTEND_PORT%)
echo.
goto :do_stop

:no_lock
echo  [WARN]  Lock file not found, using default ports (8000/3000)
set "BACKEND_PORT=8000"
set "FRONTEND_PORT=3000"
echo.

:do_stop
REM ---------- 2. Stop backend ----------
set "STOPPED_SOMETHING=0"

call :kill_on_port %BACKEND_PORT% Backend
if !errorlevel!==0 set "STOPPED_SOMETHING=1"

REM ---------- 3. Stop frontend ----------
call :kill_on_port %FRONTEND_PORT% Frontend
if !errorlevel!==0 set "STOPPED_SOMETHING=1"

REM ---------- 4. Close ENDPAGE terminal windows ----------
taskkill /FI "WINDOWTITLE eq ENDPAGE-Backend*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq ENDPAGE-Frontend*" /F >nul 2>&1

REM ---------- 5. Clean up lock file ----------
if exist "%LOCK_FILE%" del "%LOCK_FILE%" >nul 2>&1

echo.
if "!STOPPED_SOMETHING!"=="1" (
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

REM ============================================================
REM  Subroutines
REM ============================================================

:kill_on_port
set "_KP=%~1"
set "_KN=%~2"
set "_FOUND=0"

for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /r ":%_KP% .*LISTENING"') do (
    if not "%%a"=="0" (
        set "_FOUND=1"
        echo  [STOP]  Killing %_KN% on port %_KP% (PID %%a)...
        taskkill /PID %%a /T /F >nul 2>&1
    )
)

if "!_FOUND!"=="0" (
    echo  [SKIP]  %_KN% not running on port %_KP%
    exit /b 1
)
echo  [OK]   %_KN% stopped
exit /b 0
