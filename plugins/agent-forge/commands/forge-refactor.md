---
name: forge-refactor
description: Execute safe, multi-phase refactoring with rollback capability. Use when restructuring code while preserving behavior. Includes baseline snapshots, phase gates, and automatic rollback on failure.
user_invocable: true
---

# /forge-refactor - Refactoring Pipeline

Execute safe, multi-phase refactoring with rollback capability and behavior preservation guarantees.

## Usage

```
/forge-refactor <описание рефакторинга>
```

**Никаких флагов** - просто команда и описание.

## Examples

```
/forge-refactor вынести UserService в интерфейс для тестирования
/forge-refactor упростить логику обработки заказов в OrderService
/forge-refactor разбить большой класс DataProcessor на модули
/forge-refactor заменить колбэки на корутины в сетевом слое
/forge-refactor консолидировать дублирующийся код валидации
```

## Safety Guarantees

| Guarantee | Implementation |
|-----------|----------------|
| Behavior Preserved | Test suite as oracle |
| Rollback Points | Git tags after each phase |
| Phase Gates | Entry/exit criteria |
| Automatic Rollback | On any test failure |
| Progress Tracking | Full history in beads |

## Pipeline Stages

### Phase 0: Snapshot & Baseline

1. **Generate ID** (e.g., REFACTOR-USER-SVC-001)
2. **Create Baseline Snapshot**
   ```bash
   git tag "refactor/REFACTOR-USER-SVC-001/baseline"
   ```
3. **Run Full Test Suite** → Must be GREEN
4. **Store Baseline in KV**
   ```yaml
   baseline:
     commit: <sha>
     tag: "refactor/REFACTOR-USER-SVC-001/baseline"
     test_summary:
       total: 150
       passed: 150
       failed: 0
   ```
5. **Create Refactor EPIC in beads**

**Gate:** BASELINE_ESTABLISHED (tests pass, snapshot created)

### Phase 1: Impact Analysis

1. Launch impact-analyst agent
2. Identify affected files
3. Find dependencies and callers
4. Check test coverage
5. Assess risk level

**Risk Levels:**
- **LOW** - Isolated changes, good coverage, no API changes
- **MEDIUM** - Multiple files, adequate tests, internal API changes
- **HIGH** - Core modules, partial tests, public API changes
- **CRITICAL** - Shared infrastructure, minimal tests, breaking changes

**Gate:** IMPACT_ANALYZED (scope understood, risk assessed)

### Phase 2: Multi-Phase Planning

1. Launch refactor-planner agent
2. Break into atomic phases
3. Each phase: single responsibility, testable
4. Define phase dependencies
5. Set rollback triggers

**Phase Sizing Guidelines:**
- Ideal: 1-2 hours implementation
- Maximum: 4 hours (split if larger)
- Minimum: Meaningful atomic change

**Gate:** PLAN_APPROVED (phases defined, dependencies clear)

### Phase 3: Incremental Implementation

```
FOR each phase:
    │
    ├── 3a. Pre-Phase Gate
    │   - Verify previous phase complete
    │   - Create ROLLBACK_POINT (git tag)
    │   - Record phase start in KV
    │
    ├── 3b. Phase Implementation
    │   - implementer agent executes phase
    │   - Run affected tests
    │   - Update phase ISSUE status
    │
    └── 3c. Phase Verification
        - code-reviewer validates changes
        - Run FULL test suite
        - Compare against BASELINE
        │
        ├── If PASS:
        │   - Mark phase VERIFIED
        │   - Commit with phase tag
        │   - Continue to next phase
        │
        └── If FAIL:
            - TRIGGER ROLLBACK
            - Restore from ROLLBACK_POINT
            - Mark phase FAILED
            - Halt for manual intervention
NEXT phase
```

### Phase 4: Final Verification

1. Run full test suite
2. Compare behavior with BASELINE
3. Performance regression check (if applicable)
4. Code quality checks (lint, complexity)

**Gate:** ALL_VERIFIED (all tests pass, behavior preserved)

### Phase 5: Completion

1. Mark EPIC as COMPLETE
2. Archive refactoring artifacts
3. Generate refactoring report
4. Clean up rollback points (optional)

## Flow Diagram

```
/forge-refactor вынести UserService в интерфейс
        │
        ▼
┌───────────────────────────────────────────────────────┐
│  PHASE 0: SNAPSHOT & BASELINE                         │
│                                                       │
│  Generate ID: REFACTOR-USER-SVC-001                  │
│  1. git tag refactor/REFACTOR-.../baseline           │
│  2. Run full test suite → Must be GREEN              │
│  3. Store baseline in KV                             │
└───────────────────────────┬───────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────┐
│  PHASE 1: IMPACT ANALYSIS                             │
│                                                       │
│  impact-analyst agent:                                │
│  - Identify affected files                            │
│  - Assess risk level (LOW/MEDIUM/HIGH/CRITICAL)      │
│  - Generate impact report                             │
└───────────────────────────┬───────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────┐
│  PHASE 2: MULTI-PHASE PLANNING                        │
│                                                       │
│  refactor-planner agent:                              │
│  - Break into atomic phases                           │
│  - Each phase: single responsibility                  │
│  - Create PHASE_ISSUES with dependencies             │
└───────────────────────────┬───────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────┐
│  PHASE 3: INCREMENTAL IMPLEMENTATION                  │
│                                                       │
│  FOR each phase:                                      │
│    ┌───────────────────────────────────────────────┐ │
│    │  3a. Create ROLLBACK_POINT (git tag)         │ │
│    └───────────────────────┬───────────────────────┘ │
│                            │                          │
│    ┌───────────────────────▼───────────────────────┐ │
│    │  3b. implementer: Execute phase               │ │
│    └───────────────────────┬───────────────────────┘ │
│                            │                          │
│    ┌───────────────────────▼───────────────────────┐ │
│    │  3c. code-reviewer + refactor-tester          │ │
│    │                                               │ │
│    │      If PASS: → Commit, Continue             │ │
│    │      If FAIL: → ROLLBACK, Halt               │ │
│    └───────────────────────────────────────────────┘ │
│  NEXT phase                                           │
└───────────────────────────┬───────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────┐
│  PHASE 4: FINAL VERIFICATION                          │
│                                                       │
│  - Full test suite                                    │
│  - Behavior comparison with BASELINE                 │
│  - Performance regression check                      │
└───────────────────────────┬───────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   COMPLETE    │
                    └───────────────┘
```

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

## Phase Gates

### Entry Gate (Pre-Phase)

```markdown
## Entry Gate Checklist

- [ ] Previous phase is VERIFIED
- [ ] Working tree is clean
- [ ] Rollback point created
- [ ] Phase plan is clear
```

### Exit Gate (Post-Phase)

```markdown
## Exit Gate Checklist

- [ ] All affected code modified as planned
- [ ] Code review APPROVED
- [ ] Full test suite passes
- [ ] No new test failures
- [ ] No behavior regression
- [ ] Lint/format checks pass
```

## Output

At completion, the output includes:
- **Refactor ID** - The generated semantic ID
- **Risk Level** - Assessed risk (LOW/MEDIUM/HIGH/CRITICAL)
- **Phases Completed** - Number of phases
- **Summary** - What was refactored
- **Behavior Preserved** - Test suite comparison
- **Files Changed** - List of modified files
- **Commits** - List of commit hashes per phase
- **Rollback Points** - Available git tags
- **Beads Reference** - Link to epic

## Resume Support

If interrupted, the flow can be resumed:
```
/forge-refactor resume REFACTOR-USER-SVC-001
```

The system:
1. Reads current state from beads
2. Determines current phase
3. Continues from last verified state
4. If uncommitted changes exist, offers to stash or rollback

## Manual Rollback

User can manually rollback at any time:
```
/forge-refactor rollback REFACTOR-USER-SVC-001 --phase 1
```

This will:
1. Reset to the rollback point for phase 1
2. Update beads status
3. Mark subsequent phases as invalid
