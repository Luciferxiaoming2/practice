---
name: db-inspect
description: Inspect the SQLite database - list tables, count rows, check schema
disable-model-invocation: false
allowed-tools: Bash(D:/uv/venvs/practice/Scripts/python*)
---

Inspect the SQLite database at `backend/endpage.db`:

1. List all tables and their schemas (columns, types, constraints)
2. Show row counts for each table
3. Show sample data (first 5 rows) from each table
4. Check for any integrity issues

Use Python with sqlite3 module:
```
D:/uv/venvs/practice/Scripts/python.exe -c "import sqlite3; ..."
```
