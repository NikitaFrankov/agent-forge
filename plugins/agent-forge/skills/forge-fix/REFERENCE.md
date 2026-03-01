# Forge Fix - Reference Documentation

This document provides extended documentation for the forge-fix skill.

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

## Stage Details

### Stage 1: Intake

**Purpose:** Parse command and initialize tracking.

**Steps:**
1. Parse bug description from user input
2. Generate semantic ID using pattern: `FIX-{KEYWORD1}-{KEYWORD2}-{NUMBER}`
   - Extract 2-3 key words from description
   - Examples: `FIX-CRASH-PERM-001`, `FIX-NULL-POINTER-001`
3. Create bug issue in beads:
   ```bash
   bd create --type bug --title "Bug: {description}" --id "bd-{id}"
   ```
4. Initialize KV store for diagnosis
5. Set labels: `forge:fix`, `forge:pending_diagnosis`

**Output:** Bug ID and beads issue created

### Stage 2: Investigation

**Purpose:** Find root cause through systematic analysis.

**Investigator Agent Tasks:**
1. Read error messages and stack traces
2. Locate relevant code files
3. Trace execution flow to find failure point
4. Identify root cause
5. Document findings

**Diagnosis Report Format:**
```markdown
# Diagnosis Report: FIX-XXX-XXX-001

## Root Cause
[Clear description of what causes the bug]

## Affected Files
- file1.kt:45-50
- file2.kt:120-135

## Suspected Location
`src/main/kotlin/com/example/Service.kt:45`

## Reproduction Steps
1. [Step 1]
2. [Step 2]
3. [Observe error]

## Recommended Fix
[Brief description of what needs to change]
```

**State Transition:** `forge:pending_diagnosis` → `forge:diagnosed`

### Stage 3: Fix Planning

**Purpose:** Create minimal fix plan with clear scope.

**Condensed Process (max 2 iterations):**
1. Review diagnosis report
2. Identify minimal changes needed
3. Create fix plan
4. Self-review or quick review
5. If issues found, iterate once more

**Fix Plan Format:**
```markdown
# Fix Plan: FIX-XXX-XXX-001

## Scope
- Fix ONLY the specific issue
- No refactoring or improvements

## Changes
1. File: `Service.kt`
   - Line 45: Add null check
   - Reason: Prevents NPE when X is null

## Regression Test
- Location: `ServiceTest.kt`
- Test: `testNullCaseThrowsException()`

## Verification
- [ ] Test fails before fix
- [ ] Test passes after fix
- [ ] No other tests broken
```

### Stage 4: Implementation

**Purpose:** Implement fix with regression test.

**Order of Operations:**
1. **Write regression test FIRST**
   - Test must FAIL (proves bug exists)
   - Test should be minimal but complete
2. **Implement minimal fix**
   - Address only the root cause
   - No scope creep
3. **Verify test passes**
4. **Run code review**
   - Use executor:reviewer for stack-specific review
5. **Commit if approved**

**Code Review Criteria:**
- Fix addresses root cause
- No unnecessary changes
- No side effects
- Follows coding standards
- Test coverage adequate

### Stage 5: Verification

**Purpose:** Ensure complete and safe fix.

**Verification Checklist:**
1. [ ] Regression test passes
2. [ ] Full test suite passes
3. [ ] No new warnings/errors
4. [ ] Root cause addressed
5. [ ] No side effects in related code
6. [ ] Documentation updated (if needed)

**Close Bug:**
```bash
bd close FIX-XXX-XXX-001 --reason "Fixed: {summary}"
bd sync
```

## Agent Orchestration

| Stage | Agent | Purpose |
|-------|-------|---------|
| Intake | `agent-forge:intake` | Parse command, create structure |
| Investigation | `agent-forge:investigator` | Find root cause |
| Planning | Planner (inline) | Create minimal plan |
| Implementation | `executor:implementer` | Write test + fix |
| Review | `executor:reviewer` | Stack-specific review |
| Verification | Tester (inline) | Run tests, verify |

## Error Handling

### Investigation Fails
- If root cause not found, escalate to user
- Suggest additional information needed
- Create investigation notes in KV

### Plan Review Rejected (2x)
- Escalate to user for clarification
- Document blockers
- Pause flow until resolved

### Tests Fail After Fix
- Review fix for correctness
- Check for side effects
- May need additional investigation

## Best Practices

1. **Start with the error message** - It often points directly to the problem
2. **Reproduce the bug first** - Understand it before fixing
3. **Make smallest possible change** - Less risk of side effects
4. **Test edge cases** - Ensure fix handles all scenarios
5. **Document the fix** - Help future maintainers

## Enforcement Patterns

This section documents the enforcement mechanisms in forge-fix SKILL.md.

### Iron Law

The single inviolable principle:
```
NO TRACKING OR REGRESSION TEST = NOT FIXED
```

Every bug fix must satisfy both conditions:
1. Tracked in beads (bd issue exists)
2. Verified with regression test (test proves fix works)

### Mandatory First Response Protocol

Before any bug fix work begins:

1. **Announce**: "I'm using **forge-fix** to fix this bug with enforced TDD workflow."
2. **Track**: `bd create --type bug --title "Bug: {description}"`
3. **Initialize**: Create context pack in `.agent-forge/context/{bug-id}.pack.md`
4. **Verify**: All prerequisites complete before proceeding

### Stage Gates

Each stage has entry requirements and exit gates:

| Stage | Entry Requires | Exit Gate |
|-------|---------------|-----------|
| Intake | Bug description | Bug ID in beads |
| Investigation | Bug ID | Root cause in KV |
| Planning | Diagnosis report | Plan status: READY |
| Implementation | Ready plan | Test passes, review approved |
| Verification | Test passing | All checks complete |

**GATE protocol:**
- Checkboxes MUST all be checked before proceeding
- If any unchecked: STOP and complete
- No partial credit, no "mostly done"

### Evidence Requirements

Claims require fresh evidence:

| Claim | Proof Command |
|-------|--------------|
| Bug tracked | `bd show {id}` shows issue |
| Root cause found | `bd kv get fix/{id}/diagnosis/root_cause` non-empty |
| Test fails (before) | `./gradlew test --tests "{Test}"` shows FAILED |
| Test passes (after) | `./gradlew test --tests "{Test}"` shows SUCCESS |
| Full suite passes | `./gradlew test` shows 0 failures |
| Bug closed | `bd show {id}` shows status: closed |

**Evidence protocol:**
1. Identify proof command
2. Run fresh (not cached)
3. Read output
4. Verify matches expectation
5. Only then make claim

### Anti-Pattern Enforcement

Common anti-patterns are explicitly documented with:
- **What happens**: The bad behavior
- **Result**: Why it fails
- **Correct approach**: What to do instead

This makes anti-patterns visible and preventable.

### Common Excuses Rejection

Pre-defined list of rationalizations that mean "STOP":

- "This is a simple fix" → Still needs tracking and test
- "I'll add the test later" → Later never comes
- "The existing test covers it" → Then why does the bug exist?
- "Manual testing is enough" → Doesn't prevent recurrence

When an excuse appears, the workflow is being skipped. Follow anyway.

## Common Anti-Patterns

1. **Fixing symptoms, not root cause**
2. **Scope creep during fix**
3. **Skipping regression test**
4. **Not running full test suite**
5. **Over-engineering the solution**

## Troubleshooting

### Skill Not Being Followed

If Claude is not following the forge-fix workflow:

1. **Check skill activation**: Ensure description triggers correctly
   - User says: "fix this bug", "there's a crash", "error when..."

2. **Verify rigidity level**: SKILL.md should have `rigidity_level: standard`

3. **Check for common issues**:
   - Skipping first response protocol → Add reminder to CLAUDE.md
   - Missing gates → Verify GATE sections exist in SKILL.md
   - No evidence verification → Check Evidence Requirements table

4. **Hook-based enforcement** (advanced):
   - Add PreToolUse hook to check bd issue before Write/Edit
   - Add PostToolUse hook to verify tests after implementation

### Stuck at a Gate

If workflow is blocked at a gate:

1. Read the gate requirements
2. Identify which checkbox is unchecked
3. Complete the missing item
4. Re-verify all checkboxes
5. Proceed only when ALL are checked

### Investigation Not Finding Root Cause

If Stage 2 is stuck:

1. Try `executor:debugger` for stack-specific tools
2. Use `agent-forge:investigator` for systematic analysis
3. Escalate to user if more information needed
4. Document what was tried in KV
