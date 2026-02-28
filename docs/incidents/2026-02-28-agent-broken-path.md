# Incident Report: Agent Fails to Detect/Recover from Corrupted `$PATH`

**Date:** 2026-02-28
**Status:** Reported
**Components Affected:** Agent Execution Shell, Root-Cause Analysis Heuristics

## Description

When the agent executes terminal commands that inadvertently corrupt its own shell `$PATH` (e.g., executing `export PATH="literal_string:$PATH"` where the variable doesn't expand properly or is executed in a sub-shell/background process that loses the host path), standard POSIX binaries like `bash`, `nix`, `git`, and `rm` begin returning `127 command not found`.

Instead of recognizing that its fundamental execution environment is compromised, the agent hallucinates that it is hitting expected sandboxed security restrictions. It then wastes context tokens thrashing on increasingly complex application-level workarounds rather than simply repairing its own environment.

## Root Cause Analysis

- **Missing Diagnostic Steps:** The agent failed to execute basic environmental sanity checks (like `echo $PATH` or `which bash`) immediately when core utilities began failing.
- **Confirmation Bias / Tunnel Vision:** The agent assumed that because it was running in an isolated runner environment, the missing utilities were an expected property of a "locked-down sandbox." This led the agent to blame the application's dependencies and configuration constraints instead of diagnosing its own broken shell.
- **Over-Complication of Fixes:** Instead of fixing the execution environment, the agent attempted to rewrite the target bash scripts, modify plugin configurations, and inject commands directly into the user's GUI terminal.

## Requested System Prompt Adjustments

To prevent this failure mode in the future, the Google Antigravity team should update the system prompt or execution heuristics with the following self-healing directives:

1. **Environmental Sanity Checks:** If fundamental POSIX commands (`bash`, `grep`, `rm`, `git`) unexpectedly return `127 command not found` in a Unix/Mac environment during a `run_command` step, the agent MUST immediately halt its current task logic.
2. **Mandatory `$PATH` Audit:** The agent must be instructed to explicitly run `echo $PATH` to verify the integrity of its execution environment before assuming the failure is related to the user's code.
3. **Environment Isolation Validation:** The agent should not assume "security sandboxing" or "missing host paths" without first verifying that the environment variables haven't been mutated by previous operations in the session.

## Impact

Without this heuristic, agents waste massive amounts of user time and token context generating "fixes" for complex application logic when the root cause is a simple broken terminal session.
