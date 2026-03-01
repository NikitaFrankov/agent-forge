---
name: forge-fix
description: |
  Execute deterministic bug fix with autonomous diagnosis, root cause analysis,
  regression test creation, and verification. Use when fixing bugs, debugging
  issues, investigating crashes, or when user describes any error/problem/bug.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Task, Skill
rigidity_level: standard
enforcement:
  blocking_gates: true
  evidence_required: true
  checkpoint_tracking: true
---

# Forge Fix - Bug Fix Pipeline

<skill_overview>
Deterministic bug fix pipeline with enforced TDD cycle: diagnosis → regression test → minimal fix → verification.
</skill_overview>

<freedom_level>
STANDARD FREEDOM - Follow stage gates strictly. Adapt investigation and fix approaches to codebase context.

Violating blocking gates or skipping regression tests is violating the workflow.
</freedom_level>

<quick_reference>

| Stage | Blocking Gate | Must Complete Before Next |
|-------|--------------|---------------------------|
| **Intake** | Bug ID in beads | ✓ bd issue created |
| **Investigation** | Root cause documented | ✓ KV has diagnosis |
| **Planning** | Plan status: READY | ✓ Max 2 iterations |
| **Implementation** | Regression test PASSES | ✓ Test wrote first, fix approved |
| **Verification** | Full suite passes | ✓ All checks complete |

**FORBIDDEN:** Fix without bd issue, fix without regression test, skip stages
**REQUIRED:** Every bug gets tracked, tested, verified before closing

</quick_reference>

## When to Use

- User describes a bug, crash, error, or problem
- Need to fix an issue in the code
- Root cause diagnosis is required
- Regression test is needed

## Iron Law

**NO TRACKING OR REGRESSION TEST = NOT FIXED**

Every bug fix MUST:
1. Have a bd issue tracking it
2. Have a regression test proving the fix works

If either is missing, the bug is not fixed. No exceptions.

## MANDATORY FIRST RESPONSE PROTOCOL

**BEFORE doing ANYTHING else, you MUST complete this checklist:**

### ☐ Step 1: Announce Workflow
Say: "I'm using **forge-fix** to fix this bug with enforced TDD workflow."

### ☐ Step 2: Create Tracking Issue
```bash
bd create --type bug --title "Bug: {description}"
```
- Note the issue ID (e.g., `bd-123`)

### ☐ Step 3: Initialize Context
Create `.agent-forge/context/{bug-id}.pack.md` with:
- Bug description
- Bug ID from beads
- Current stage: `intake`
- Next step: `investigation`

### ☐ Step 4: Verify Prerequisites
- [ ] Bug description is not empty
- [ ] bd issue was created successfully
- [ ] Context pack was initialized

**ONLY AFTER all checkboxes are complete:** Proceed to Stage 1 (Intake).

**If you skip this protocol:** STOP. You are not following the workflow.

## Pipeline Stages

### Stage 1: Intake

**ENTRY REQUIREMENTS:**
- [ ] Bug description provided by user
- [ ] No existing bd issue for this bug

**STOP:** If bug description is empty, ask user for details before proceeding.

1. Parse bug description from user
2. Generate semantic ID (e.g., `FIX-CRASH-PERM-001`)
3. Create bug issue in beads: `bd create --type bug --title "Bug: {description}"`
4. Initialize diagnosis KV store
5. Set state: `forge:pending_diagnosis`

**Intake Agent:** Launch `agent-forge:intake` to parse command and initialize beads structure.

**GATE: Intake Complete**

Before proceeding to Investigation, verify:
- [ ] Bug ID exists in beads
- [ ] Labels set: `forge:fix`, `forge:pending_diagnosis`
- [ ] KV store initialized

If any checkbox is empty: **DO NOT PROCEED.** Fix the issue first.

---

### Stage 2: Investigation

**ENTRY REQUIREMENTS:**
- [ ] Bug ID from Stage 1
- [ ] Bug description in beads

**STOP:** If Bug ID is missing, return to Stage 1.

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

**GATE: Investigation Complete**

Before proceeding to Planning, verify:
- [ ] Root cause documented in KV: `bd kv get fix/{id}/diagnosis/root_cause`
- [ ] Affected files listed
- [ ] Reproduction steps documented

If root cause is unknown: **DO NOT PROCEED.** Continue investigation or escalate to user.

---

### Stage 3: Fix Planning

**ENTRY REQUIREMENTS:**
- [ ] Diagnosis report complete
- [ ] Root cause identified

**STOP:** If root cause is unclear, return to Stage 2.

1. Create condensed fix plan (max 2 iterations - faster than feature)
2. Plan must include:
   - Files to modify
   - Minimal change scope
   - Regression test location
3. When Plan Status: READY → proceed to implementation

**GATE: Plan Ready**

Before proceeding to Implementation, verify:
- [ ] Fix plan has Status: READY
- [ ] Files to modify identified
- [ ] Regression test location specified
- [ ] Max 2 planning iterations reached OR plan approved

If plan is not READY: **DO NOT PROCEED.** Iterate on planning.

---

### Stage 4: Implementation

**ENTRY REQUIREMENTS:**
- [ ] Plan status: READY
- [ ] Regression test location known

**STOP:** If plan is not ready, return to Stage 3.

**CRITICAL: Regression Test First**
1. Write test that reproduces the bug (must FAIL before fix)
2. Implement minimal fix
3. Verify regression test PASSES
4. Launch **executor:reviewer** agent (stack-specific)
5. If APPROVED: commit
6. If ISSUES_FOUND: address and re-review

**GATE: Implementation Complete**

Before proceeding to Verification, verify:
- [ ] Regression test written and FAILS (before fix)
- [ ] Minimal fix implemented
- [ ] Regression test PASSES (after fix)
- [ ] Code review APPROVED

If test passes before fix: **NOT A VALID REGRESSION TEST.** Rewrite test.
If review is ISSUES_FOUND: **ADDRESS ISSUES.** Do not proceed to commit.

---

### Stage 5: Verification

**ENTRY REQUIREMENTS:**
- [ ] Regression test passing
- [ ] Code review approved

**STOP:** If test is failing or review is pending, return to Stage 4.

1. All regression tests pass
2. No side effects introduced
3. Root cause addressed
4. Close bug issue: `bd close <bug-id>`

**GATE: Bug Fix Complete**

Before closing, verify ALL:
- [ ] Root cause addressed
- [ ] Regression test passes
- [ ] Full test suite passes
- [ ] No side effects introduced
- [ ] bd issue closed: `bd close <id>`
- [ ] Synced with remote: `bd sync`

If ANY checkbox is empty: **BUG IS NOT FIXED.** Complete the missing items.

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

## Hard Constraints

### FORBIDDEN

These actions will cause the fix to be rejected:

- **NO** fix without creating bd bug issue first
- **NO** fix without writing regression test first
- **NO** fixing symptoms instead of root cause
- **NO** refactoring or improvements during bug fix ("while we're here")
- **NO** skipping stages or blocking gates
- **NO** claiming fixed without running verification commands
- **NO** committing before code review approval

### REQUIRED

These actions are mandatory for every bug fix:

- **MUST** create bd issue: `bd create --type bug --title "Bug: {description}"`
- **MUST** write regression test that FAILS before fix
- **MUST** verify regression test PASSES after fix
- **MUST** get code review approval before commit
- **MUST** run full test suite after fix
- **MUST** close bd issue after verification: `bd close <id>`
- **MUST** sync with remote: `bd sync`

## Anti-Patterns

### Anti-Pattern 1: Fixing Without Tracking

**What happens:**
```
Developer sees bug, immediately starts fixing code.
No bd issue created, no tracking.
```

**Result:**
- Bug may not be fully understood
- No regression test to prevent recurrence
- No visibility into what was fixed
- Team cannot verify the fix

**Correct approach:** Create bd issue FIRST, then investigate.

---

### Anti-Pattern 2: Fixing Symptoms Instead of Root Cause

**What happens:**
```
Developer sees NullPointerException, adds null check.
Root cause was actually data corruption upstream.
```

**Result:**
- Bug appears fixed initially
- Same issue resurfaces in different form
- Time wasted on ineffective fix

**Correct approach:** Trace back to WHY data was null. Fix the source.

---

### Anti-Pattern 3: Skipping Regression Test

**What happens:**
```
Developer fixes bug, verifies manually, commits.
No automated test written.
```

**Result:**
- Bug can reappear in future without detection
- No proof the fix actually works
- Future developers don't understand the edge case

**Correct approach:** Write test FIRST, watch it FAIL, then fix.

---

### Anti-Pattern 4: Scope Creep During Fix

**What happens:**
```
Developer fixes bug, notices nearby code could be cleaner.
Refactors while fixing.
```

**Result:**
- Large diff harder to review
- If tests fail, unclear which change broke it
- Introduces risk unrelated to the bug

**Correct approach:** Fix ONLY the bug. Create separate task for refactoring.

---

### Anti-Pattern 5: Claiming Fixed Without Verification

**What happens:**
```
Developer implements fix, assumes it works.
Does not run tests. Commits and closes issue.
```

**Result:**
- Fix may not actually work
- May have broken other tests
- False sense of completion

**Correct approach:** Run verification commands. See green tests. Then claim fixed.

## Common Excuses

**All of these mean: STOP. You are trying to skip the workflow.**

| Excuse | Why It's Wrong |
|--------|----------------|
| "This is a simple fix" | Simple fixes still need tracking and tests. Bugs recur. |
| "I'll add the test later" | Later never comes. Write it now while context is fresh. |
| "The existing test covers it" | If it did, the bug wouldn't exist. Add regression test. |
| "I don't want to create a bd issue for this" | No tracking = no visibility = not fixed. |
| "Manual testing is enough" | Manual testing doesn't prevent recurrence. Automate. |
| "I'm being pragmatic, not dogmatic" | Pragmatism without process creates technical debt. |
| "The bug is urgent, no time for process" | Rushed fixes cause more bugs. Process saves time. |
| "I can skip investigation, I know the cause" | Assumptions cause misdiagnosis. Verify with evidence. |
| "Code review isn't needed for small fixes" | Small fixes cause big problems. Always review. |

**When you catch yourself making excuses:** Follow the workflow anyway.

## Condensed Process

Bug fix uses a faster process than feature development:

| Aspect | Feature | Bug Fix |
|--------|---------|---------|
| Planning iterations | 5 max | 2 max |
| Interview required | Yes | No |
| Research phase | Optional | Included in investigation |
| Test strategy | Planned | Regression test only |
| Iterations | Multiple (3-5) | Single (1-2) |

## Evidence Requirements

**Every claim MUST be backed by fresh verification evidence.**

| Claim | Verification Command | Expected Output | NOT Sufficient |
|-------|---------------------|-----------------|----------------|
| **Bug tracked** | `bd show {id}` | Issue exists with `forge:fix` label | "I created it" |
| **Root cause found** | `bd kv get fix/{id}/diagnosis/root_cause` | Non-empty string | "I think it's..." |
| **Regression test fails** | `./gradlew test --tests "{TestName}"` | `FAILED` in output | "It should fail" |
| **Regression test passes** | `./gradlew test --tests "{TestName}"` | `BUILD SUCCESSFUL`, 0 failures | "I fixed it" |
| **Full suite passes** | `./gradlew test` | All tests pass, 0 failures | "Tests look good" |
| **No side effects** | `./gradlew test` + visual check | Same test count, no new failures | "Seems fine" |
| **Code reviewed** | Review agent output | `APPROVED` or `PASS` | "Looks good to me" |
| **Bug closed** | `bd show {id}` | Status: `closed` | "I'm done" |

### Evidence Protocol

**Before claiming ANY completion:**

1. **Identify** what command proves this claim
2. **Run** the full command fresh (not cached output)
3. **Read** the output completely
4. **Verify** output confirms the claim
5. **Only then** make the claim

**Red flags that you're skipping evidence:**
- Using "should", "probably", "seems to"
- Expressing satisfaction before verification
- About to commit without running tests
- Saying "done" without bd sync

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

## Integration

### This Skill Calls

| Skill/Agent | When | Purpose |
|-------------|------|---------|
| `agent-forge:intake` | Stage 1 | Parse command, create beads structure |
| `agent-forge:investigator` | Stage 2 | Systematic root cause investigation |
| `executor:debugger` | Stage 2 (optional) | Stack-specific debugging |
| `executor:implementer` | Stage 4 | Stack-specific code implementation |
| `executor:reviewer` | Stage 4 | Stack-specific code review |
| `bd` CLI | All stages | Tracking, state management |

### This Skill Is Called By

| Trigger | User says/does |
|---------|---------------|
| Explicit invocation | `/forge-fix {description}` |
| Bug description | "fix this bug", "there's a crash", "error when..." |
| Test failure | "this test is failing", "fix the broken test" |
| Issue reference | "fix BUG-123", "address the issue" |

### Agents Used

| Agent | Role | Tools |
|-------|------|-------|
| `agent-forge:intake` | Parse and initialize | Read, Bash (bd) |
| `agent-forge:investigator` | Root cause analysis | Read, Grep, Glob, Bash, Task |
| `executor:debugger` | Stack-specific debugging | Stack-dependent |
| `executor:implementer` | Write test + fix | Read, Write, Edit, Bash |
| `executor:reviewer` | Code review | Read, Grep, Glob |

### External Dependencies

- **beads CLI (`bd`)**: Required for tracking and state management
- **Executor context**: `.agent-forge/executor.context` must exist (auto-created if missing)
- **Test framework**: Project must have runnable tests (Gradle, pytest, etc.)

## Resume Support

If interrupted, the flow can be resumed by reading current state from beads and continuing from the last checkpoint.
