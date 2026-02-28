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

## Common Anti-Patterns

1. **Fixing symptoms, not root cause**
2. **Scope creep during fix**
3. **Skipping regression test**
4. **Not running full test suite**
5. **Over-engineering the solution**
