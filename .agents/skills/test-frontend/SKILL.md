---
name: test-frontend
description: Build and type-check the Next.js frontend
disable-model-invocation: false
allowed-tools: Bash(cd /d/practice/one/web*), Bash(npm *), Bash(npx *)
---

Validate the Next.js frontend:

1. Change to the `web/` directory
2. Run `npx tsc --noEmit` to check TypeScript types
3. Run `npx next build` to verify the production build succeeds
4. If there are errors, analyze and suggest fixes
5. Report a summary of all issues found
