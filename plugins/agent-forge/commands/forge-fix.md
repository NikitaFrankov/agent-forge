---
name: forge-fix
description: Execute deterministic bug fix with autonomous diagnosis. Use when fixing bugs - includes root cause analysis, regression test creation, and verification.
user_invocable: true
---

# /forge-fix - Bug Fix Pipeline

Execute deterministic bug fix with autonomous diagnosis and verification.

## Usage

```
/forge-fix <описание проблемы>
```

**Никаких флагов** - просто команда и описание проблемы на естественном языке.

## Examples

```
/forge-fix исправить краш приложения при запросе разрешений
/forge-fix починить утечку памяти в UserService
/forge-fix исправить некорректное отображение дат в календаре
/forge-fix устранить дублирование записей в базе данных
/forge-fix исправить ошибку 500 при загрузке файлов
```

## Pipeline Stages

### Stage 1: Intake
1. Parse command and description
2. Generate semantic ID (e.g., FIX-CRASH-PERM-001)
3. Create bug issue in beads
4. Initialize diagnosis KV store

### Stage 2: Investigation
1. Launch investigator agent
2. Analyze codebase to find root cause
3. Document diagnosis in beads KV
4. Identify affected files and components
5. State: diagnosed

### Stage 3: Fix Planning
1. Launch fix-planner agent (condensed process)
2. Create minimal fix plan
3. Plan review (up to 2 iterations - faster than feature)
4. When Plan Status: READY → proceed

### Stage 4: Implementation
1. **Regression Test First** - Write test that reproduces the bug
2. Implement minimal fix
3. Verify regression test passes
4. Launch code-reviewer agent
5. If APPROVED: commit
6. If ISSUES_FOUND: address and re-review

### Stage 5: Verification
1. All regression tests pass
2. No side effects introduced
3. Root cause addressed
4. Close bug issue

## Flow Diagram

```
/forge-fix исправить краш при запросе разрешений
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
        │  4. code-reviewer           │
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

## Beads Structure

```yaml
FIX-CRASH-PERM-001                  # Bug issue (type=bug)
├── diagnosis-report                # KV: Root cause analysis
│   ├── root_cause: "<description>"
│   ├── affected_files: [list]
│   ├── suspected_location: "file:line"
│   └── reproduction_steps: [steps]
├── fix-plan                        # Mol: Fix plan (condensed)
├── FIX-...-task-001                # Task: Write regression test
├── FIX-...-task-002                # Task: Implement fix
└── verification-report             # Digest: Verification results
```

## Key Principles

### 1. Regression Test First
- ALWAYS write a test that reproduces the bug BEFORE fixing
- This test becomes the acceptance criteria
- Test must fail before fix, pass after fix

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

If interrupted, the flow can be resumed:
```
/forge-fix resume FIX-CRASH-PERM-001
```

The system reads current state from beads and continues from the last checkpoint.
