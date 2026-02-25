---
name: forge-exec
description: |
  Execute Ralph Wiggum implementation loop with executor selection.
  Fresh context per iteration, single task per iteration, two-stage review.

argument-hint: <ticket> [--executor <name>] [max_iterations]
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Task
---

# /forge-exec - Implementation Execution

Execute the Ralph Wiggum implementation loop with automatic executor selection.

## Usage

```bash
/forge-exec <ticket> [--executor <name>] [max_iterations]
```

## Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `<ticket>` | Yes | - | Ticket identifier |
| `--executor <name>` | No | auto | Override auto-detection |
| `max_iterations` | No | 50 | Maximum iterations before stopping |

## Executor Selection

**Priority order:**
1. `--executor kotlin` flag (explicit override)
2. `.agent-forge/config.yaml` → `executor: kotlin`
3. Auto-detection from project files:
   - `build.gradle.kts` → kotlin
   - `Cargo.toml` → rust
   - `pyproject.toml` → python
   - `package.json` → typescript

**Auto-detection script:**
```bash
bash ${PLUGIN_ROOT}/core/scripts/detect-executor.sh
```

## Prerequisites

- Plan must exist at `.agent-forge/plan/<ticket>.md`
- Plan must have Status: READY

If plan doesn't exist or isn't ready:
```
ERROR: Plan not ready for implementation
Run /forge-plan <ticket> first
```

## Ralph Wiggum Principles

1. **Fresh Context** - Each iteration gets a new Claude context
2. **Single Task** - One task per iteration
3. **Two-Stage Review** - Implementer → Code-reviewer
4. **Commit After Approval** - Only after APPROVED
5. **Progress Logging** - Update activity.md each iteration
6. **50 Retry Strategy** - For persistent errors
7. **Max Iterations Safety** - Stop at limit

## Workflow

### 1. Verify Plan Ready
```
Read .agent-forge/plan/<ticket>.md
Check: ## Plan Review → Status: READY
```

### 2. Get Context Pack Info
```
Read .agent-forge/context/<ticket>.pack.md
Extract: ticket, branch, user_note
```

### 3. Detect Executor and Generate PROMPT.md

**Step 3a: Detect Executor**
```bash
# Run detection script
EXECUTOR=$(bash ${PLUGIN_ROOT}/core/scripts/detect-executor.sh)

# Or read from plan
Read .agent-forge/plan/<ticket>.md
Look for: ## Executor Selection → Detected: <executor>
```

**Step 3b: Generate PROMPT.md with Executor Context**
```bash
bash ${PLUGIN_ROOT}/core/scripts/generate-prompt.sh <ticket> [executor]
```

This script:
1. Loads `executors/<executor>/executor.json` → extracts test/lint commands
2. Loads `executors/<executor>/generator.md` → code patterns
3. Loads `executors/<executor>/debugger.md` → debugging strategies
4. Generates `.agent-forge/PROMPT.md` with executor-specific instructions

**Generated PROMPT.md structure:**
```markdown
# Implementation Iteration: <ticket>

## Executor: kotlin

## Pre-Iteration Checks
1. Read Codebase Patterns
2. Verify correct branch

## Your Task
1. Find next task
2. Read requirements
3. **Follow executor patterns below**

## Executor Commands
- Test: ./gradlew test --tests "..."
- Lint: ./gradlew detekt
- Build: ./gradlew build

## Executor Code Patterns (from generator.md)
[Kotlin patterns, data classes, coroutines, etc.]

## Debugging Strategy (from debugger.md)
[50 retry strategy, common errors, fixes]

## After Implementation
- Update activity log
- Wait for APPROVAL
- Commit after APPROVED
```

### 4. Iteration Loop
```
FOR iteration = 1 TO max_iterations:
    1. Launch implementer agent
       - Read Codebase Patterns
       - Implement single task
       - Run tests
       - Report completion

    2. Launch code-reviewer agent
       - Read actual code files
       - Two-stage review (spec + quality)
       - APPROVED or ISSUES_FOUND

    3. If APPROVED:
       - Commit changes
       - Mark task Status: passing
       - Update activity log

    4. If ISSUES_FOUND:
       - Implementer addresses issues
       - Re-review

    5. Check completion:
       - All tasks Status: passing?
       - Output <promise>COMPLETE</promise>
       - Exit loop

NEXT iteration
```

### 5. Completion
```
## Implementation Complete

**Ticket:** <ticket>
**Total Iterations:** <count>
**Tasks Completed:** <count>/<total>

**Commits:**
- <commit 1>
- <commit 2>

**Activity Log:** .agent-forge/activity/<ticket>.md

**Ready for:** Merge/PR
```

## Executor System

Each executor provides:

| File | Purpose |
|------|---------|
| `executor.json` | Commands (test, lint, build), patterns (src_dir, config_files) |
| `generator.md` | Code patterns, naming conventions, common structures |
| `debugger.md` | 50 retry strategy, error patterns and fixes |
| `tester.md` | Testing framework, patterns, commands |
| `reviewer.md` | Code review checklist, quality standards |

**Executor context is injected into PROMPT.md automatically.**

### Available Executors

| Executor | Detection File | Commands |
|----------|---------------|----------|
| kotlin | build.gradle.kts | ./gradlew test, detekt, ktlintFormat |
| python | pyproject.toml | pytest, ruff, black |
| rust | Cargo.toml | cargo test, clippy |
| typescript | package.json | npm test, eslint |

## Monitoring

Watch progress in real-time:
```bash
# Activity log
tail -f .agent-forge/activity/<ticket>.md

# Git log
git log --oneline -10
```

## Safety

**Before running in production:**
1. Use isolated environment (worktree, Docker)
2. Commit working state before starting
3. Have escape hatch (Ctrl+C)
4. Monitor progress

**If something goes wrong:**
```bash
git reset --hard HEAD  # Discard changes
/forge-exec <ticket>   # Restart
```

## Examples

```bash
# Start implementation
/forge-exec AUTH-123-add-oauth

# With custom iteration limit
/forge-exec AUTH-123 20

# Continue after interruption
/forge-exec AUTH-123  # Resumes from task status
```

## Verification

At completion, verify:
- [ ] All tasks Status: passing
- [ ] All tests pass
- [ ] All changes committed
- [ ] Activity log complete
- [ ] No uncommitted changes
