@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================================
REM  ENDPAGE - One-click startup script (Windows local dev)
REM
REM  Usage:
REM    1. Double-click start.bat to launch backend + frontend
REM    2. Auto-configures ADB port forwarding for mobile dev
REM    3. Run stop.bat to stop all services
REM
REM  Default ports:
REM    - Backend API:  8000
REM    - Frontend Web: 3000
REM ============================================================

REM Auto-detect project root (where this script lives)
set "PROJECT_ROOT=%~dp0"
set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "VENV_PATH=D:\uv\venvs\practice"
set "BACKEND_DIR=%PROJECT_ROOT%\backend"
set "FRONTEND_DIR=%PROJECT_ROOT%\web"
set "BACKEND_PORT=8000"
set "FRONTEND_PORT=3000"

echo.
echo  ================================================
echo     ENDPAGE Startup
echo  ================================================
echo.

REM ---------- 1. Check prerequisites ----------
echo  [1/6] Checking environment...

if not exist "%VENV_PATH%\Scripts\python.exe" (
    echo  [ERROR] Python venv not found: %VENV_PATH%
    pause & exit /b 1
)
if not exist "%BACKEND_DIR%\app\main.py" (
    echo  [ERROR] Backend not found: %BACKEND_DIR%\app\main.py
    pause & exit /b 1
)
where node >nul 2>&1 || (echo  [ERROR] Node.js not found & pause & exit /b 1)
echo  [OK]   Environment check passed

REM ---------- 2. Check frontend deps ----------
echo  [2/6] Checking frontend dependencies...
if not exist "%FRONTEND_DIR%\node_modules\next" (
    echo  [INFO]  Installing frontend dependencies...
    cd /d "%FRONTEND_DIR%" && call npm install || (echo  [ERROR] npm install failed & pause & exit /b 1)
    cd /d "%PROJECT_ROOT%"
)
echo  [OK]   Frontend dependencies ready

REM ---------- 3. Kill old services on ports ----------
echo  [3/6] Freeing ports...
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /r ":%BACKEND_PORT% .*LISTENING"') do (
    if not "%%a"=="0" (
        echo  [INFO]  Killing old process on port %BACKEND_PORT% ^(PID %%a^)
        taskkill /PID %%a /T /F >nul 2>&1
    )
)
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /r ":%FRONTEND_PORT% .*LISTENING"') do (
    if not "%%a"=="0" (
        echo  [INFO]  Killing old process on port %FRONTEND_PORT% ^(PID %%a^)
        taskkill /PID %%a /T /F >nul 2>&1
    )
)
timeout /t 1 /nobreak >nul
echo  [OK]   Ports ready

REM ---------- 4. Start backend ----------
echo  [4/6] Starting backend on port %BACKEND_PORT%...
start "ENDPAGE-Backend" cmd /k "cd /d %BACKEND_DIR% && %VENV_PATH%\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port %BACKEND_PORT% --reload"

REM ---------- 5. Start frontend ----------
echo  [5/6] Starting frontend on port %FRONTEND_PORT%...
start "ENDPAGE-Frontend" cmd /k "cd /d %FRONTEND_DIR% && npx next dev --port %FRONTEND_PORT%"

REM ---------- 6. ADB port forwarding ----------
echo  [6/6] Configuring ADB...
where adb >nul 2>&1
if !errorlevel!==0 (
    adb reverse tcp:%BACKEND_PORT% tcp:%BACKEND_PORT% >nul 2>&1
    if !errorlevel!==0 (
        echo  [OK]   ADB port forwarding configured
    ) else (
        echo  [SKIP] No Android device connected
    )
) else (
    echo  [SKIP] ADB not found, skipping mobile config
)

REM ---------- 7. Save lock file ----------
echo BACKEND_PORT=%BACKEND_PORT%> "%PROJECT_ROOT%\.endpage.lock"
echo FRONTEND_PORT=%FRONTEND_PORT%>> "%PROJECT_ROOT%\.endpage.lock"

REM ---------- 8. Wait for services ----------
echo.
echo  Waiting for services to start...
call :wait_for_service %BACKEND_PORT% 30 Backend
if errorlevel 1 (
    echo  [ERROR] Backend startup timed out. Check the Backend terminal.
    pause & exit /b 1
)
call :wait_for_service %FRONTEND_PORT% 60 Frontend
if errorlevel 1 (
    echo  [ERROR] Frontend startup timed out. Check the Frontend terminal.
    pause & exit /b 1
)

echo.
echo  ================================================
echo     All services started!
echo  ------------------------------------------------
echo     Frontend:  http://localhost:%FRONTEND_PORT%
echo     Backend:   http://localhost:%BACKEND_PORT%/docs
echo  ------------------------------------------------
echo     Run stop.bat to stop all services
echo  ================================================
echo.

start "" "http://localhost:%FRONTEND_PORT%"
timeout /t 3 /nobreak >nul
exit /b 0

REM ============================================================
:wait_for_service
set /a "_W=0"
set /a "_MAX=%~2"
set "_SNAME=%~3"
:wait_loop
powershell -Command "try{$c=New-Object Net.Sockets.TcpClient;$c.Connect('127.0.0.1',%~1);$c.Close();exit 0}catch{exit 1}" >nul 2>&1
if !errorlevel!==0 (
    echo  [OK]   %_SNAME% is ready
    exit /b 0
)
set /a "_W+=1"
if !_W! geq !_MAX! exit /b 1
set /a "_MOD=!_W! %% 5"
if !_MOD!==0 echo  [...]  Waiting for %_SNAME%... (!_W!/%_MAX%s^)
timeout /t 1 /nobreak >nul
goto wait_loop
