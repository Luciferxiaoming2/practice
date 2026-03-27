@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================================
REM  ENDPAGE - One-click startup script (Windows local dev)
REM
REM  Usage:
REM    1. Double-click start.bat to launch frontend + backend
REM    2. Or run in terminal: start.bat
REM    3. Browser opens automatically when services are ready
REM    4. Close the two spawned terminal windows to stop services
REM
REM  Prerequisites:
REM    - Node.js installed and in PATH
REM    - Python venv at: D:\uv\venvs\practice
REM    - Backend deps installed (pip install -r requirements.txt)
REM
REM  Default ports:
REM    - Backend API:  8000
REM    - Frontend Web: 3000
REM    - Auto-resolves port conflicts
REM ============================================================

set "PROJECT_ROOT=D:\practice\one"
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

REM ---------- 1. CD to project ----------
cd /d "%PROJECT_ROOT%" 2>nul
if errorlevel 1 goto :err_no_project

REM ---------- 2. Check prerequisites ----------
echo  [1/6] Checking environment...

if not exist "%VENV_PATH%\Scripts\activate.bat" goto :err_no_venv
if not exist "%BACKEND_DIR%\app\main.py" goto :err_no_backend

where node >nul 2>&1
if errorlevel 1 goto :err_no_node

where npm >nul 2>&1
if errorlevel 1 goto :err_no_npm

echo  [OK]   Environment check passed

REM ---------- 3. Check frontend deps ----------
echo  [2/6] Checking frontend dependencies...

if not exist "%FRONTEND_DIR%\node_modules\next" goto :install_npm_deps
goto :deps_ok

:install_npm_deps
echo  [INFO]  Installing frontend dependencies...
cd /d "%FRONTEND_DIR%"
call npm install
if errorlevel 1 goto :err_npm_install
cd /d "%PROJECT_ROOT%"

:deps_ok
echo  [OK]   Frontend dependencies ready

REM ---------- 4. Port conflict detection ----------
echo  [3/6] Checking ports...

call :handle_port %BACKEND_PORT% Backend
set "BACKEND_PORT=!FREE_PORT!"

call :handle_port %FRONTEND_PORT% Frontend
set "FRONTEND_PORT=!FREE_PORT!"

echo  [OK]   Ports allocated (Backend:%BACKEND_PORT% / Frontend:%FRONTEND_PORT%)

REM Save actual ports to lock file for stop.bat
echo BACKEND_PORT=%BACKEND_PORT%> "%PROJECT_ROOT%\.endpage.lock"
echo FRONTEND_PORT=%FRONTEND_PORT%>> "%PROJECT_ROOT%\.endpage.lock"

REM ---------- 5. Start backend ----------
echo  [4/6] Starting backend on port %BACKEND_PORT%...

start "ENDPAGE-Backend" cmd /k "cd /d %BACKEND_DIR% && call %VENV_PATH%\Scripts\activate.bat && echo [Backend] Starting uvicorn... && uvicorn app.main:app --host 127.0.0.1 --port %BACKEND_PORT% --reload"

REM ---------- 6. Start frontend ----------
echo  [5/6] Starting frontend on port %FRONTEND_PORT%...

start "ENDPAGE-Frontend" cmd /k "cd /d %FRONTEND_DIR% && echo [Frontend] Starting Next.js... && npx next dev --port %FRONTEND_PORT%"

REM ---------- 7. Wait for services ----------
echo  [6/6] Waiting for services...

call :wait_for_service %BACKEND_PORT% 30 Backend
if errorlevel 1 goto :err_backend_timeout

call :wait_for_service %FRONTEND_PORT% 60 Frontend
if errorlevel 1 goto :err_frontend_timeout

echo.
echo  ================================================
echo     All services started successfully!
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
REM  Subroutines
REM ============================================================

:handle_port
set "FREE_PORT=%~1"
set "_PORT=%~1"
set "_NAME=%~2"
netstat -ano 2>nul | findstr /r ":%_PORT% .*LISTENING" >nul 2>&1
if errorlevel 1 exit /b 0
REM Port is occupied - get PID
set "_PID="
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /r ":%_PORT% .*LISTENING"') do (
    if not "%%a"=="0" set "_PID=%%a"
)
if not defined _PID goto :find_alt_port
echo  [WARN]  Port %_PORT% occupied by PID !_PID!, killing...
taskkill /PID !_PID! /F >nul 2>&1
timeout /t 1 /nobreak >nul
netstat -ano 2>nul | findstr /r ":%_PORT% .*LISTENING" >nul 2>&1
if errorlevel 1 (
    echo  [OK]   Port %_PORT% freed
    exit /b 0
)
:find_alt_port
echo  [WARN]  Cannot free port %_PORT%, finding alternative...
REM Snapshot netstat once to avoid repeated slow calls
set "_NETSTAT_TMP=%TEMP%\endpage_netstat.tmp"
netstat -ano 2>nul | findstr /r "LISTENING" > "!_NETSTAT_TMP!"
set /a "_TRY=%_PORT%+1"
:find_loop
if !_TRY! gtr 65535 exit /b 1
echo  [...]  Trying port !_TRY!...
findstr /r ":!_TRY! " "!_NETSTAT_TMP!" >nul 2>&1
if errorlevel 1 (
    set "FREE_PORT=!_TRY!"
    echo  [INFO]  %_NAME% will use port !_TRY!
    del "!_NETSTAT_TMP!" >nul 2>&1
    exit /b 0
)
echo  [WARN]  Port !_TRY! also occupied, skipping
set /a "_TRY+=1"
goto find_loop

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
if !_MOD!==0 echo  [...]  Waiting for %_SNAME%... (!_W!/%_MAX%s)
timeout /t 1 /nobreak >nul
goto wait_loop

REM ============================================================
REM  Error handlers
REM ============================================================

:err_no_project
echo  [ERROR] Project path not found: %PROJECT_ROOT%
pause
exit /b 1

:err_no_venv
echo  [ERROR] Python venv not found: %VENV_PATH%
echo          Run: uv venv %VENV_PATH%
pause
exit /b 1

:err_no_backend
echo  [ERROR] Backend code not found: %BACKEND_DIR%\app\main.py
pause
exit /b 1

:err_no_node
echo  [ERROR] Node.js not found. Install from https://nodejs.org/
pause
exit /b 1

:err_no_npm
echo  [ERROR] npm not found. Reinstall Node.js.
pause
exit /b 1

:err_npm_install
echo  [ERROR] npm install failed. Check network or npm config.
pause
exit /b 1

:err_backend_timeout
echo  [ERROR] Backend startup timed out (30s). Check the Backend terminal window.
echo          Common fix: pip install -r requirements.txt
pause
exit /b 1

:err_frontend_timeout
echo  [ERROR] Frontend startup timed out (60s). Check the Frontend terminal window.
echo          Common fix: cd web ^&^& npm install
pause
exit /b 1
