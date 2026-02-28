# Forge Refactor - Reference Documentation

This document provides extended documentation for the forge-refactor skill.

## Beads Structure

```yaml
REFACTOR-USER-SVC-001                    # Epic (type=refactoring)
├── baseline/                            # KV: Baseline snapshot
│   ├── commit: "<sha>"
│   ├── tag: "refactor/REFACTOR-USER-SVC-001/baseline"
│   ├── test_summary: {...}
│   └── created: "<timestamp>"
├── impact-report                        # Mol: Impact analysis
├── phase-plan                           # Mol: Phase breakdown
├── REFACTOR-...-PHASE-1                 # Phase issue
│   ├── rollback-point                   # KV: Pre-phase checkpoint
│   ├── test-results                     # KV: Phase verification
│   └── status: planned|in-progress|verified|failed
├── REFACTOR-...-PHASE-2                 # Phase issue
│   └── ...
├── rollback-points                      # KV: All rollback points
└── completion-report                    # Digest: Final report
```

## Rollback Mechanism

### Rollback Points

Created automatically:
1. **Baseline** - Before any changes
2. **Pre-Phase N** - Before each phase implementation

### Rollback Triggers

| Trigger | Action |
|---------|--------|
| Any test failure | Rollback to previous phase rollback point |
| New test failure | Rollback immediately |
| Behavior regression | Rollback, investigate |
| Manual `ROLLBACK` | Rollback to specified point |
| Phase timeout | Alert user, offer rollback |

### Rollback Procedure

```bash
# Automatic rollback
rollback_to_phase() {
  local target_phase=$1
  local tag="refactor/${ID}/pre-phase-${target_phase}"

  # Stash any uncommitted changes
  git stash push -m "refactor-rollback-${ID}"

  # Reset to rollback point
  git reset --hard $(git rev-parse $tag)

  # Update beads status
  bd label add ${ID}-PHASE-${current} refactor:rolled-back
  bd kv set refactor/${ID}/phases/${current}/status rolled-back
}
```

## Phase Details

### Phase 0: Snapshot & Baseline

**Purpose:** Establish a known-good state before any changes.

**Steps:**
1. Generate semantic ID using pattern: `REFACTOR-{KEYWORD1}-{KEYWORD2}-{NUMBER}`
2. Create baseline git tag
3. Run full test suite - must be completely GREEN
4. Store baseline metadata in beads KV
5. Create refactoring epic in beads

**Baseline Metadata Format:**
```yaml
baseline:
  commit: "abc123def456"
  tag: "refactor/REFACTOR-USER-SVC-001/baseline"
  test_summary:
    total: 150
    passed: 150
    failed: 0
    skipped: 0
  created: "2024-01-15T10:30:00Z"
```

**State Transition:** Initialize → `forge:baseline_established`

### Phase 1: Impact Analysis

**Purpose:** Understand scope and assess risk.

**Impact-Analyst Agent Tasks:**
1. Identify all files that will be modified
2. Find all dependencies (what imports/uses this code)
3. Find all callers (what code calls this)
4. Check test coverage for affected areas
5. Assess overall risk level

**Impact Report Format:**
```markdown
# Impact Report: REFACTOR-USER-SVC-001

## Summary
- Risk Level: MEDIUM
- Files Affected: 8
- Dependencies: 12
- Test Coverage: 78%

## Affected Files
| File | Impact | Coverage |
|------|--------|----------|
| UserService.kt | Direct | 92% |
| UserController.kt | Dependent | 85% |
| AuthModule.kt | Caller | 70% |

## Risk Assessment
- Internal API changes affect 3 modules
- Good test coverage in core areas
- Some callers have partial coverage

## Recommendations
- Add integration tests for UserController
- Consider deprecation path for old API
```

**Risk Level Criteria:**

| Level | Criteria | Example |
|-------|----------|---------|
| LOW | Isolated, well-tested, no API changes | Extract private method |
| MEDIUM | Multiple files, adequate tests, internal API | Extract interface |
| HIGH | Core modules, partial tests, public API | Replace async framework |
| CRITICAL | Infrastructure, minimal tests, breaking | Change DI framework |

**State Transition:** `forge:baseline_established` → `forge:impact_analyzed`

### Phase 2: Multi-Phase Planning

**Purpose:** Break refactoring into safe, atomic phases.

**Refactor-Planner Agent Tasks:**
1. Review impact report
2. Design incremental phases
3. Each phase must be independently testable
4. Define phase dependencies
5. Set rollback triggers

**Phase Plan Format:**
```markdown
# Phase Plan: REFACTOR-USER-SVC-001

## Overview
- Total Phases: 4
- Estimated Time: 6-8 hours
- Risk Level: MEDIUM

## Phase Breakdown

### Phase 1: Create Interface (Est: 1-2h)
- Create IUserService interface
- No behavior changes
- Dependency: None
- Rollback Trigger: Any test failure

### Phase 2: Extract Implementation (Est: 2h)
- Move UserService logic to UserServiceImpl
- UserService becomes facade
- Dependency: Phase 1
- Rollback Trigger: Any test failure

### Phase 3: Update Consumers (Est: 2h)
- Update all callers to use interface
- Dependency: Phase 2
- Rollback Trigger: Any test failure

### Phase 4: Remove Old Code (Est: 1h)
- Clean up old implementation
- Update documentation
- Dependency: Phase 3
- Rollback Trigger: Any test failure
```

**State Transition:** `forge:impact_analyzed` → `forge:plan_approved`

### Phase 3: Incremental Implementation

**Purpose:** Execute phases safely with rollback capability.

**Per-Phase Flow:**

```
┌─────────────────────────────────────────────────────────┐
│ PRE-PHASE                                               │
│                                                         │
│ 1. Verify previous phase VERIFIED                       │
│ 2. git tag "refactor/{ID}/pre-phase-{N}"               │
│ 3. Record phase start in KV                            │
│ 4. Update state: forge:phase_{N}_in_progress           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ IMPLEMENTATION                                          │
│                                                         │
│ 1. executor:implementer executes phase plan            │
│ 2. Run affected tests                                  │
│ 3. Fix any issues found                                │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│ VERIFICATION                                            │
│                                                         │
│ 1. executor:reviewer validates changes                 │
│ 2. Run FULL test suite                                 │
│ 3. Compare with baseline                               │
│                                                         │
│ IF PASS:                                                │
│   - Mark phase VERIFIED                                │
│   - Commit with message                                │
│   - git tag "refactor/{ID}/phase-{N}-complete"         │
│                                                         │
│ IF FAIL:                                                │
│   - TRIGGER ROLLBACK                                   │
│   - git reset --hard "refactor/{ID}/pre-phase-{N}"     │
│   - Mark phase FAILED                                  │
│   - HALT for manual intervention                       │
└─────────────────────────────────────────────────────────┘
```

**Phase Commit Message Format:**
```
refactor({scope}): {description}

Phase {N} of {TOTAL} - REFACTOR-{ID}

- {change_summary}

Beads: bd-REFACTOR-{ID}-PHASE-{N}
```

### Phase 4: Final Verification

**Purpose:** Ensure complete safety before completion.

**Verification Checklist:**
1. [ ] All phases completed successfully
2. [ ] Full test suite passes
3. [ ] Test count matches baseline (no skipped tests)
4. [ ] Performance regression check (if applicable)
5. [ ] Code quality checks pass (lint, complexity)
6. [ ] Documentation updated

**Comparison Report:**
```markdown
# Final Verification: REFACTOR-USER-SVC-001

## Test Suite Comparison
| Metric | Baseline | Final | Status |
|--------|----------|-------|--------|
| Total | 150 | 150 | ✅ |
| Passed | 150 | 150 | ✅ |
| Failed | 0 | 0 | ✅ |
| Skipped | 0 | 0 | ✅ |

## Code Quality
- Lint: PASS
- Complexity: No increase
- Coverage: 78% → 79% (+1%)

## Behavior Verification
- All existing tests pass
- No new test failures
- Performance: Within 5% of baseline

## Result: APPROVED
```

### Phase 5: Completion

**Purpose:** Finalize and report.

**Completion Tasks:**
1. Mark epic as COMPLETE in beads
2. Archive refactoring artifacts
3. Generate final report
4. Optionally clean up rollback points

**Final Report Format:**
```markdown
# Refactoring Report: REFACTOR-USER-SVC-001

## Summary
- **Description:** Extract UserService to interface
- **Risk Level:** MEDIUM
- **Phases Completed:** 4/4
- **Duration:** 6 hours

## Changes
- Files Modified: 12
- Lines Changed: +450/-280
- New Files: 2 (interface + impl)

## Verification
- All tests pass: ✅
- Behavior preserved: ✅
- No regressions: ✅

## Commits
1. `abc123` - Phase 1: Create interface
2. `def456` - Phase 2: Extract implementation
3. `ghi789` - Phase 3: Update consumers
4. `jkl012` - Phase 4: Clean up

## Rollback Points
- `refactor/REFACTOR-USER-SVC-001/baseline`
- `refactor/REFACTOR-USER-SVC-001/pre-phase-1`
- `refactor/REFACTOR-USER-SVC-001/pre-phase-2`
- `refactor/REFACTOR-USER-SVC-001/pre-phase-3`
- `refactor/REFACTOR-USER-SVC-001/pre-phase-4`

## Beads Reference
- Epic: `bd-REFACTOR-USER-SVC-001`
```

## Error Handling

### Baseline Tests Fail

If baseline test suite is not GREEN:
1. Do NOT proceed with refactoring
2. Report failing tests to user
3. Suggest fixing existing issues first
4. Exit with clear error message

### Impact Analysis Uncertain

If impact cannot be fully determined:
1. Mark as HIGH risk
2. Recommend manual review
3. Suggest starting with smaller scope
4. Offer to create investigation task

### Phase Verification Fails

When a phase fails verification:
1. Automatic rollback to pre-phase checkpoint
2. Mark phase as FAILED
3. Document failure reason
4. Offer options:
   - Retry phase with different approach
   - Abort refactoring
   - Manual intervention

### All Phases Complete But Final Verification Fails

If final verification fails:
1. Do NOT mark as complete
2. Investigate what changed
3. May need to roll back to specific phase
4. User decides next action

## Best Practices

### 1. Start Green, End Green
- Never begin with failing tests
- All tests must pass at completion
- Any test failure triggers rollback

### 2. Atomic Phases
- Each phase should be reversible
- Each phase should be independently verifiable
- Avoid phases larger than 4 hours

### 3. Trust the Tests
- Test suite is the oracle for behavior preservation
- If tests pass, behavior is preserved
- Add tests if coverage is inadequate

### 4. Document as You Go
- Each phase gets a commit with context
- Beads tracks all decisions and changes
- Final report summarizes everything

### 5. Rollback is Not Failure
- Rolling back is a safety feature working correctly
- Investigate why rollback was needed
- Adjust plan and try again

## Common Anti-Patterns

1. **Skipping baseline** - Always establish baseline first
2. **Phases too large** - Break into smaller, safer phases
3. **Ignoring risk level** - HIGH/CRITICAL needs more caution
4. **No rollback points** - Every phase needs a checkpoint
5. **Scope creep** - Stick to the plan, defer improvements
