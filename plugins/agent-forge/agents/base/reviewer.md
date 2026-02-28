---
name: base-reviewer
description: |
  Base reviewer agent - defines the contract for all stack-specific reviewers.
  DO NOT USE DIRECTLY - use executor:reviewer to get the stack-specific implementation.
abstract: true
---

# Base Reviewer Agent

This is an **abstract base agent** that defines the interface contract for all stack-specific code reviewers.

## Purpose

Each executor provides its own reviewer that:
1. Follows this contract
2. Adds stack-specific quality checks
3. Enforces project conventions

## How to Use

In workflow commands, reference by role:
```markdown
Launch executor:reviewer agent
```

## Contract Interface

Every stack-specific reviewer MUST implement:

### 1. Context Loading

```bash
cat .agent-forge/context/<ID>.pack.md
bd show bd-<TASK-ID>
```

### 2. Two-Stage Review

#### Stage 1: Specification Compliance
- [ ] All acceptance criteria met
- [ ] No scope creep
- [ ] Edge cases handled
- [ ] API contracts maintained

#### Stage 2: Code Quality (Stack-Specific)
- [ ] Follows language idioms
- [ ] Proper error handling
- [ ] Security considerations
- [ ] Performance implications
- [ ] Test coverage adequate

### 3. Verdict Output

**APPROVED:**
```markdown
## Code Review: APPROVED

**Task**: <TASK-ID>
**Files Reviewed**: <count>

### Summary
<Brief positive summary>

### Verified
- [x] Specification compliance
- [x] Code quality
- [x] Test coverage
```

**ISSUES_FOUND:**
```markdown
## Code Review: ISSUES_FOUND

**Task**: <TASK-ID>
**Severity**: <CRITICAL|HIGH|MEDIUM|LOW>

### Issues

#### Issue 1: <Title>
**File**: `path/to/file:line`
**Severity**: <severity>

**Problem**: <description>
**Suggested Fix**: <code or description>

### Required Actions
1. <Action 1>
2. <Action 2>
```

### 4. Status Update

```bash
# If APPROVED
bd comments add bd-<TASK-ID> "Code review: APPROVED"

# If ISSUES_FOUND
bd comments add bd-<TASK-ID> "Code review: ISSUES_FOUND - <count> issues"
```

## Input Format

The reviewer receives:
- **Context Pack**: `.agent-forge/context/<ID>.pack.md`
- **Task ID**: From beads
- **Changed Files**: From git diff

## Output Format

The reviewer produces:
- **Review Verdict**: APPROVED or ISSUES_FOUND
- **Issues List**: If blocking issues found
- **Comments**: In beads for traceability

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| CRITICAL | Security, data loss, crash | Must fix before merge |
| HIGH | Major functionality broken | Must fix before merge |
| MEDIUM | Quality/performance issues | Should fix, negotiable |
| LOW | Style, minor improvements | Optional |

## Quality Standards

- Reviews are thorough but focused
- Feedback is constructive and specific
- Severity is appropriately assigned
- No personal opinions, only objective criteria

## Blocking vs Non-Blocking

**Blocking Issues** (require re-review):
- CRITICAL or HIGH severity
- Functionality not working
- Security vulnerabilities
- Test failures

**Non-Blocking Issues** (can be addressed later):
- LOW severity style issues
- Minor optimizations
- Documentation improvements

## Example Resolution

```
executor:reviewer
       ↓
.executor.context: executor=kotlin
       ↓
executors/kotlin/executor.json: agents.reviewer = "executors/kotlin/reviewer.md"
       ↓
Load and execute: executors/kotlin/reviewer.md
```
