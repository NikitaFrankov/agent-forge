---
name: forge-feature
description: |
  Start deterministic new feature development with full lifecycle.
  Use when developing a new feature from scratch, implementing new
  functionality, or when user describes a feature to add/build/create.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task, Skill
---

# Forge Feature - New Feature Development Pipeline

## When to Use

- User describes a new feature to implement
- Need to add new functionality to the codebase
- Full feature lifecycle management required
- Structured ideation and planning needed

## Pipeline Stages

### Stage 1: Intake

1. Parse command and description
2. Generate semantic ID (e.g., `FEATURE-AUTH-OAUTH-001`)
3. Create beads structure (Epic + molecules)
4. Create Context Pack

**Intake Agent:** Launch `agent-forge:intake` to parse command and initialize beads structure.

### Stage 2: Ideation

1. Launch **analyst agent** for structured interview
2. Generate PRD with AIDD sections
3. If AIDD:RESEARCH_HINTS exist → launch researcher agent
4. PRD review loop (up to 5 iterations)
5. When PRD Status: READY → proceed

**Analyst Agent:** Launch `agent-forge:analyst` (or `agent-forge:base:base-analyst`) for PRD generation.

### Stage 3: Planning

1. Read PRD and research findings
2. Launch planner agent
3. Create implementation plan with iterations/tasks
4. Plan review loop (up to 5 iterations)
5. When Plan Status: READY → proceed

**Planner Agent:** Launch `agent-forge:planner` (or `agent-forge:base:base-planner`) for implementation planning.

### Stage 4: Implementation (Ralph Wiggum Loop)

1. For each pending task:
   - Launch **executor:implementer** agent (stack-specific)
   - Implement single task
   - Run tests (via executor tools)
   - Launch **executor:reviewer** agent (stack-specific)
   - If APPROVED: commit, mark passing
   - If ISSUES_FOUND: address and re-review
2. Continue until all tasks passing

### Stage 5: Completion

1. All tasks Status: passing
2. All tests passing
3. Generate completion digest
4. Archive artifacts
5. Close beads issues

## Flow Diagram

```
/forge-feature добавить авторизацию через OAuth
        │
        ▼
┌───────────────────┐
│  INTAKE           │ Generate ID: FEATURE-AUTH-OAUTH-001
│  intake agent     │ Create beads structure
└───────┬───────────┘
        │
        ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  IDEATION     │────►│  RESEARCH     │────►│  PRD REVIEW   │
│  analyst      │     │  (if hints)   │     │  (loop 5x)    │
└───────┬───────┘     └───────────────┘     └───────┬───────┘
        │                                           │
        │              PRD: READY                   │
        └───────────────────────────────────────────┘
                            │
                            ▼
                ┌───────────────────┐
                │     PLANNING      │
                │  planner → review │
                │  (loop 5x)        │
                └─────────┬─────────┘
                          │ Plan: READY
                          ▼
        ┌─────────────────────────────────────┐
        │     IMPLEMENTATION (Ralph Wiggum)   │
        │                                     │
        │  FOR each task:                     │
        │    executor:implementer             │
        │    executor:reviewer                │
        │    If APPROVED: commit              │
        │    If ISSUES: loop back             │
        │                                     │
        └─────────────────┬───────────────────┘
                          │ All tasks: passing
                          ▼
                ┌───────────────────┐
                │    COMPLETE       │
                └───────────────────┘
```

## Key Principles

### 1. Deterministic Progress
- Each stage has clear entry/exit criteria
- Status tracked in beads
- No ambiguity about what to do next

### 2. Ralph Wiggum Loop
- Implement one task at a time
- Review before committing
- If issues found, fix and re-review

### 3. Test-Driven
- Write tests for new functionality
- Tests must pass before task marked complete

### 4. Executor System
- Stack-specific implementation via executor:role
- Auto-detection from project files
- Consistent interface across languages

## Beads Structure

```yaml
bd-FEATURE-AUTH-OAUTH-001              # Epic (type=epic)
├── bd-...-prd                         # Mol: PRD artifact
├── bd-...-research                    # Mol: Research findings (optional)
├── bd-...-plan                        # Mol: Implementation plan
├── bd-...-iter-1                      # Iteration 1 container
│   ├── bd-...-task-001                # Task
│   │   ├── impl-001                   # Wisp (ephemeral)
│   │   └── review-001                 # Digest
│   └── bd-...-task-002                # Task
├── bd-...-iter-2                      # Iteration 2 container
│   └── ...
└── bd-...-digest                      # Final digest
```

## Executor System

The pipeline uses **executor:role** references for stack-specific agents:

| Reference | Resolves to |
|-----------|-------------|
| `executor:implementer` | `executors/<stack>/implementer.md` |
| `executor:reviewer` | `executors/<stack>/reviewer.md` |
| `executor:tester` | `executors/<stack>/tester.md` |

Executor is auto-detected from project files or set in `.agent-forge/config.yaml`.

## Verification Checklist

At completion, verify:
- [ ] PRD exists with Status: READY
- [ ] Plan exists with Status: READY
- [ ] All tasks have Status: passing
- [ ] All tests pass
- [ ] Changes are committed
- [ ] Beads epic closed

## Output

At completion, the output includes:
- **Feature ID** - The generated semantic ID
- **Summary** - What was implemented
- **Commits** - List of commit hashes
- **Files Changed** - List of modified/created files
- **Beads Reference** - Link to beads epic for history

## Resume Support

If interrupted, the flow can be resumed by reading current state from beads and continuing from the last checkpoint.

```
/forge-feature resume FEATURE-AUTH-OAUTH-001
```
