---
name: dev-start
description: Start the local development environment (frontend + backend)
disable-model-invocation: false
allowed-tools: Bash(cmd.exe *)
---

Start the local development environment by running the startup script:

1. Execute `start.bat` from the project root `D:\practice\one`
2. This will launch:
   - Backend (FastAPI/Uvicorn) on port 8000
   - Frontend (Next.js) on port 3000
3. The script auto-detects port conflicts and opens the browser when ready
4. To stop services later, run `stop.bat`
