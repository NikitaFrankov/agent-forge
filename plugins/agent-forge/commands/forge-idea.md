---
name: forge-idea
description: Collect and structure requirements for a new feature through structured interviews. Use when starting ideation for a new ticket or feature. Runs analyst interview, optional research, and PRD review loop.
user_invocable: true
---

# /forge-idea - Requirements Collection

Collect comprehensive requirements through structured interviews.

## Usage

```bash
/forge-idea <ticket>
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<ticket>` | Yes | Ticket identifier (e.g., AUTH-123, user-auth) |

## Workflow

### 1. Check Existing Artifacts
```
Check for:
- .agent-forge/context/<ticket>.pack.md (Context Pack)
- .agent-forge/ideas/<ticket>.md (Raw ideas)
- .agent-forge/prd/<ticket>.prd.md (Existing PRD)
```

### 2. Create Feature Branch
```bash
git checkout -b feature/<ticket>-<slug>
```

### 3. Create Context Pack
```markdown
# Context Pack: <ticket>

- ticket: <ticket>
- stage: ideation
- paths:
  - context: .agent-forge/context/<ticket>.pack.md
  - ideas: .agent-forge/ideas/<ticket>.md
  - prd: .agent-forge/prd/<ticket>.prd.md
- what_to_do_now: "Launch analyst agent to conduct interview"
```

### 4. Launch Analyst Agent
```
Task: analyst agent
- Conduct 8+ rounds of interview via AskUserQuestion
- Cover all question categories
- Generate PRD with AIDD sections
```

### 5. Research (if AIDD:RESEARCH_HINTS exist)
```
Task: researcher agent
- Investigate codebase for integration points
- Document reusable patterns
- Identify technical risks
```

### 6. PRD Review Loop (up to 5 iterations)
```
Task: prd-reviewer agent
- Validate PRD completeness
- Check AIDD sections
- Set status: READY or NEEDS_WORK
- If NEEDS_WORK → analyst addresses → re-review
```

### 7. Completion
When PRD Status: READY:
```
## Ideation Complete

**PRD:** .agent-forge/prd/<ticket>.prd.md
**Status:** READY

**Next Step:** /forge-plan <ticket>
```

## PRD Format

```markdown
# PRD: <ticket>

## Metadata
- **Ticket:** <ticket>
- **Status:** DRAFT → READY
- **Created:** <date>

## Overview
<description>

## Goals
1. <goal>
2. <goal>

### AIDD:ACCEPTANCE
- [ ] <testable criterion>
- [ ] <testable criterion>

### AIDD:OPEN_QUESTIONS
- <question for research>

### AIDD:ANSWERS
- **Q:** <question> → **A:** <answer>

### AIDD:RESEARCH_HINTS
- **Hint:** <research guidance>

## Constraints
- <constraint>

## Dependencies
- <dependency>

## Success Metrics
- <metric>

## PRD Review
- **Status:** READY
- **Review Iteration:** N/5
```

## Examples

```bash
# Start new ideation
/forge-idea AUTH-123-add-oauth

# Continue existing ideation
/forge-idea user-auth  # Uses existing artifacts
```

## Verification

At completion, verify:
- [ ] Context Pack exists
- [ ] PRD exists with AIDD sections
- [ ] PRD Status: READY
- [ ] No TBD/TODO in PRD
- [ ] Feature branch created
