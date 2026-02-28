---
description: Prevent agents from automatically committing and pushing code.
---

# 🛑 NO AUTO COMMIT OR PUSH

**CRITICAL RULE:**
You MUST NOT run `git add`, `git commit`, or `git push` automatically.
Always leave unstaged and uncommitted changes for the USER to review, stage, commit, and push themselves.
You may only run these commands if the USER explicitly issues a direct instruction to do so in the current prompt (e.g., "please commit and push these changes").
