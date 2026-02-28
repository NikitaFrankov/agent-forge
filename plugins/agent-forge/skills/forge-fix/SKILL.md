---
name: forge-fix
description: |
  Execute deterministic bug fix with autonomous diagnosis, root cause analysis,
  regression test creation, and verification. Use when fixing bugs, debugging
  issues, investigating crashes, or when user describes any error/problem/bug.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task, Skill
---

# Forge Fix - Bug Fix Pipeline

## When to Use

- User describes a bug, crash, error, or problem
- Need to fix an issue in the code
- Root cause diagnosis is required
- Regression test is needed

## Pipeline Stages

### Stage 1: Intake

1. Parse bug description from user
2. Generate semantic ID (e.g., `FIX-CRASH-PERM-001`)
3. Create bug issue in beads: `bd create --type bug --title "Bug: {description}"`
4. Initialize diagnosis KV store
5. Set state: `forge:pending_diagnosis`

**Intake Agent:** Launch `agent-forge:intake` to parse command and initialize beads structure.

### Stage 2: Investigation

1. Launch **investigator agent** (`agent-forge:investigator`)
2. Analyze codebase to find root cause
3. Document diagnosis in beads KV:
   ```yaml
   diagnosis-report:
     root_cause: "<description>"
     affected_files: [list]
     suspected_location: "file:line"
     reproduction_steps: [steps]
   ```
4. State: `forge:diagnosed`

### Stage 3: Fix Planning

1. Create condensed fix plan (max 2 iterations - faster than feature)
2. Plan must include:
   - Files to modify
   - Minimal change scope
   - Regression test location
3. When Plan Status: READY → proceed to implementation

### Stage 4: Implementation

**CRITICAL: Regression Test First**
1. Write test that reproduces the bug (must FAIL before fix)
2. Implement minimal fix
3. Verify regression test PASSES
4. Launch **executor:reviewer** agent (stack-specific)
5. If APPROVED: commit
6. If ISSUES_FOUND: address and re-review

### Stage 5: Verification

1. All regression tests pass
2. No side effects introduced
3. Root cause addressed
4. Close bug issue: `bd close <bug-id>`

## Flow Diagram

```
Bug Description
        │
        ▼
┌───────────────────┐
│  INTAKE           │ Generate ID: FIX-CRASH-PERM-001
│  intake agent     │ Create bug issue in beads
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│  INVESTIGATION    │ investigator agent → root cause
│  State: diagnosed │ Output: diagnosis report in KV
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐     ┌───────────────────┐
│  FIX PLANNING     │────►│  PLAN REVIEW      │
│  fix-planner      │     │  (condensed)      │
│  (1-2 iterations) │     │  loop 2x          │
└─────────┬─────────┘     └─────────┬─────────┘
          │                         │
          │         Plan: READY     │
          └─────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │    FIX IMPLEMENTATION       │
        │                             │
        │  1. Write regression test   │
        │  2. Implement minimal fix   │
        │  3. Verify test passes      │
        │  4. executor:reviewer       │
        │                             │
        └─────────────┬───────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │    VERIFICATION             │
        │  - Regression tests pass    │
        │  - No side effects          │
        │  - Root cause addressed     │
        └─────────────┬───────────────┘
                      │
                      ▼
              ┌───────────────┐
              │   COMPLETE    │
              │  Close bug    │
              └───────────────┘
```

## Key Principles

### 1. Regression Test First
- ALWAYS write a test that reproduces the bug BEFORE fixing
- This test becomes the acceptance criteria
- Test must FAIL before fix, PASS after fix

### 2. Minimal Scope
- Fix ONLY the specific issue
- No refactoring, improvements, or "while we're here" changes
- Code reviewer specifically checks for scope creep

### 3. No Side Effects
- Code reviewer checks that fix doesn't affect other functionality
- Run full test suite after fix
- Verify no new warnings or errors

### 4. Link to Source
- If bug was discovered in another context (analysis, feature work)
- Use `discovered-from` link in beads
- Maintain traceability

## Condensed Process

Bug fix uses a faster process than feature development:

| Aspect | Feature | Bug Fix |
|--------|---------|---------|
| Planning iterations | 5 max | 2 max |
| Interview required | Yes | No |
| Research phase | Optional | Included in investigation |
| Test strategy | Planned | Regression test only |
| Iterations | Multiple (3-5) | Single (1-2) |

## Executor System

The pipeline uses **executor:role** references for stack-specific agents:

| Reference | Resolves to |
|-----------|-------------|
| `executor:debugger` | `executors/<stack>/debugger.md` |
| `executor:reviewer` | `executors/<stack>/reviewer.md` |

Executor is auto-detected from project files or set in `.agent-forge/config.yaml`.

## Verification Checklist

At completion, verify:
- [ ] Root cause documented in KV
- [ ] Regression test written and passes
- [ ] Minimal fix implemented
- [ ] Code review approved
- [ ] No side effects introduced
- [ ] Full test suite passes
- [ ] Bug issue closed in beads

## Output

At completion, the output includes:
- **Bug ID** - The generated semantic ID
- **Root Cause** - What was causing the bug
- **Fix Summary** - What was changed
- **Regression Test** - Path to the new test
- **Files Changed** - List of modified files
- **Verification** - All checks passed
- **Beads Reference** - Link to bug issue

## Resume Support

If interrupted, the flow can be resumed by reading current state from beads and continuing from the last checkpoint.
