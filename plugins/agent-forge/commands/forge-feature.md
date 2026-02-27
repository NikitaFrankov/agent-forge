---
name: forge-feature
description: Start deterministic new feature development with full lifecycle. Use when developing a new feature from scratch. Runs through ideation, planning, and implementation phases automatically.
user_invocable: true
---

# /forge-feature - New Feature Development Pipeline

Start deterministic new feature development with full lifecycle management.

## Usage

```
/forge-feature <описание фичи>
```

**Никаких флагов** - просто команда и описание на естественном языке.

## Examples

```
/forge-feature добавить авторизацию через Google OAuth
/forge-feature реализовать пагинацию для списка пользователей
/forge-feature добавить темную тему в приложение
/forge-feature создать систему уведомлений
/forge-feature интегрировать платежную систему Stripe
```

## Pipeline Stages

### Stage 1: Intake
1. Parse command and description
2. Generate semantic ID (e.g., FEATURE-AUTH-OAUTH-001)
3. Create beads structure (Epic + molecules)
4. Create Context Pack

### Stage 2: Ideation
1. Launch analyst agent for structured interview
2. Generate PRD with AIDD sections
3. If AIDD:RESEARCH_HINTS exist → researcher agent
4. PRD review loop (up to 5 iterations)
5. When PRD Status: READY → proceed

### Stage 3: Planning
1. Read PRD and research findings
2. Launch planner agent
3. Create implementation plan with iterations/tasks
4. Plan review loop (up to 5 iterations)
5. When Plan Status: READY → proceed

### Stage 4: Implementation (Ralph Wiggum Loop)
1. For each pending task:
   - Launch implementer agent
   - Implement single task
   - Run tests
   - Launch code-reviewer agent
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
        │    implementer → code-reviewer      │
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

## Executor Selection

**Priority order:**
1. `.agent-forge/config.yaml` (project config)
2. Auto-detection from project files:
   - `build.gradle.kts` → kotlin
   - `Cargo.toml` → rust
   - `pyproject.toml` → python
   - `package.json` → typescript

## Verification

At completion, verify:
- [ ] PRD exists with Status: READY
- [ ] Plan exists with Status: READY
- [ ] All tasks have Status: passing
- [ ] All tests pass
- [ ] Changes are committed
- [ ] Beads epic closed

## Resume Support

If interrupted, the flow can be resumed:
```
/forge-feature resume FEATURE-AUTH-OAUTH-001
```

The system reads current state from beads and continues from the last checkpoint.

## Output

At completion, the output includes:
- **Feature ID** - The generated semantic ID
- **Summary** - What was implemented
- **Commits** - List of commit hashes
- **Files Changed** - List of modified/created files
- **Beads Reference** - Link to beads epic for history
