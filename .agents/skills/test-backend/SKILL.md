---
name: test-backend
description: Run FastAPI backend tests with pytest and report results
disable-model-invocation: false
allowed-tools: Bash(cd /d/practice/one/backend*), Bash(D:/uv/venvs/practice/Scripts/python*), Bash(D:/uv/venvs/practice/Scripts/pytest*)
---

Run the FastAPI backend test suite:

1. Activate the virtual environment at `D:\uv\venvs\practice`
2. Change to the `backend/` directory
3. Run `pytest -v --tb=short` to execute all tests
4. If tests fail, analyze the output and suggest fixes
5. Report a summary: total / passed / failed / errors
