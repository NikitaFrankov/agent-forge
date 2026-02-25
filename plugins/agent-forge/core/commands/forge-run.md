---
name: forge-run
description: |
  Full development pipeline from idea to completion.
  Runs ideation → research → planning → implementation → review.

argument-hint: <ticket> [--executor <name>]
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - AskUserQuestion
  - Task
---

# /forge-run - Full Development Pipeline

Execute the complete development pipeline from idea to completion.

## Usage

```bash
/forge-run <ticket> [--executor <kotlin|python|rust|typescript>]
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<ticket>` | Yes | Ticket identifier (e.g., AUTH-123, user-auth) |
| `--executor <name>` | No | Explicit executor selection |

## Pipeline Stages

### Stage 1: Ideation (if no PRD exists)
1. Create Context Pack
2. Launch ideation agent for interview
3. Generate PRD with AIDD sections
4. If research hints exist → researcher agent
5. PRD review loop (up to 5 iterations)
6. When PRD Status: READY → proceed

### Stage 2: Planning
1. Read PRD and research findings
2. Launch planner agent
3. Create implementation plan with iterations/tasks
4. Plan review loop (up to 5 iterations)
5. When Plan Status: READY → proceed

### Stage 3: Implementation
1. Launch Ralph Wiggum loop
2. Each iteration: implementer → code-reviewer
3. Fresh context per iteration
4. Single task per iteration
5. Commit after APPROVED
6. Continue until all tasks passing

### Stage 4: Completion
1. All tasks Status: passing
2. All tests passing
3. Activity log complete
4. Ready for merge/PR

## Executor Selection

**Priority order:**
1. `--executor` flag (explicit)
2. `.agent-forge/config.yaml` (project config)
3. Auto-detection from project files:
   - `build.gradle.kts` → kotlin
   - `Cargo.toml` → rust
   - `pyproject.toml` → python
   - `package.json` → typescript

## Examples

```bash
# Full pipeline with auto-detection
/forge-run AUTH-123-add-oauth

# Explicit executor
/forge-run AUTH-123 --executor kotlin

# Continue from existing PRD
/forge-run AUTH-123  # Skips ideation if PRD exists
```

## Flow Diagram

```
┌─────────────┐
│   START     │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│  PRD exists?│─NO─►│  IDEATION   │
└──────┬──────┘     │  (interview)│
       │YES         └──────┬──────┘
       │                   │
       │                   ▼
       │            ┌─────────────┐
       │            │  RESEARCH   │
       │            │  (if hints) │
       │            └──────┬──────┘
       │                   │
       ▼                   ▼
┌─────────────────────────────┐
│       PRD READY?            │◄──── Review loop
└──────────────┬──────────────┘
               │YES
               ▼
┌─────────────────────────────┐
│          PLANNING           │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       PLAN READY?           │◄──── Review loop
└──────────────┬──────────────┘
               │YES
               ▼
┌─────────────────────────────┐
│       IMPLEMENTATION        │
│   ┌─────────┐ ┌───────────┐ │
│   │Implement│─►│Code Review│ │
│   └─────────┘ └─────┬─────┘ │
│         ▲           │       │
│         └───────────┘       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│      ALL TASKS PASSING?     │
└──────────────┬──────────────┘
               │YES
               ▼
┌─────────────────────────────┐
│          COMPLETE           │
└─────────────────────────────┘
```

## Verification

At completion, verify:
- [ ] `.agent-forge/prd/<ticket>.prd.md` exists with Status: READY
- [ ] `.agent-forge/plan/<ticket>.md` exists with Status: READY
- [ ] All tasks have Status: passing
- [ ] All tests pass
- [ ] Activity log is complete
- [ ] Changes are committed
