---
name: forge-plan
description: |
  Create detailed implementation plan from PRD.
  Runs planner → plan-reviewer loop until READY.

argument-hint: <ticket>
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Task
---

# /forge-plan - Implementation Planning

Create a detailed implementation plan from the PRD.

## Usage

```bash
/forge-plan <ticket>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<ticket>` | Yes | Ticket identifier (e.g., AUTH-123) |

## Prerequisites

- PRD must exist at `.agent-forge/prd/<ticket>.prd.md`
- PRD must have Status: READY

If PRD doesn't exist or isn't ready:
```
ERROR: PRD not ready for planning
Run /forge-idea <ticket> first
```

## Workflow

### 1. Verify PRD Ready
```
Read .agent-forge/prd/<ticket>.prd.md
Check: ## PRD Review → Status: READY
```

### 2. Read Research (if exists)
```
Read .agent-forge/research/<ticket>.md
Integrate findings into plan
```

### 3. Launch Planner Agent
```
Task: planner agent
- Analyze PRD and research
- Decompose into iterations (3-5)
- Create tasks (1-2 hours each)
- Define test strategy
- Identify risks
- Detect executor
```

### 4. Plan Review Loop (up to 5 iterations)
```
Task: plan-reviewer agent
- Validate plan completeness
- Check task quality
- Verify test strategy
- Set status: READY or NEEDS_WORK
- If NEEDS_WORK → planner addresses → re-review
```

### 5. Completion
When Plan Status: READY:
```
## Planning Complete

**Plan:** .agent-forge/plan/<ticket>.md
**Status:** READY
**Executor:** <detected executor>

**Summary:**
- <count> iterations
- <count> tasks
- Estimated: <duration>

**Next Step:** /forge-exec <ticket>
```

## Plan Format

```markdown
# Implementation Plan: <ticket>

## Metadata
- **Ticket:** <ticket>
- **Status:** DRAFT → READY
- **Created:** <date>
- **PRD:** .agent-forge/prd/<ticket>.prd.md

## Overview
<summary>

## Research Findings Summary
<if research exists>

## Iterations

### Iteration 1: <Title>
**Definition of Done:** <criteria>

**Tasks:**
1. **[TASK-001]** <description>
   - **File:** `path/to/file.kt`
   - **Acceptance:** <criteria>
   - **Tests:** <requirements>
   - **Status:** pending

## Test Strategy
- Unit tests: <requirements>
- Integration tests: <requirements>

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| <risk> | <level> | <mitigation> |

## Executor Selection
**Detected:** <executor>
**Reasoning:** <why>

## Plan Review
- **Status:** READY
- **Review Iteration:** N/5
```

## Examples

```bash
# Create plan from PRD
/forge-plan AUTH-123-add-oauth

# Re-plan (overwrites existing)
/forge-plan AUTH-123
```

## Verification

At completion, verify:
- [ ] Plan exists with all iterations
- [ ] Each task has file, acceptance, tests, status
- [ ] Test strategy defined
- [ ] Risks identified
- [ ] Executor selected
- [ ] Plan Status: READY
