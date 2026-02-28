# Forge Feature - Reference Documentation

This document provides extended documentation for the forge-feature skill.

## Beads Structure

```yaml
bd-FEATURE-AUTH-OAUTH-001              # Epic (type=epic)
├── bd-...-prd                         # Mol: PRD artifact
├── bd-...-research                    # Mol: Research findings (optional)
├── bd-...-plan                        # Mol: Implementation plan
├── bd-...-iter-1                      # Iteration 1 container
│   ├── bd-...-task-001                # Task
│   │   ├── impl-001                   # Wisp (ephemeral)
│   │   └── review-001                 # Digest
│   └── bd-...-task-002                # Task
├── bd-...-iter-2                      # Iteration 2 container
│   └── ...
└── bd-...-digest                      # Final digest
```

## Stage Details

### Stage 1: Intake

**Purpose:** Parse command and initialize tracking.

**Steps:**
1. Parse feature description from user input
2. Generate semantic ID using pattern: `FEATURE-{KEYWORD1}-{KEYWORD2}-{NUMBER}`
   - Extract 2-3 key words from description
   - Examples: `FEATURE-AUTH-OAUTH-001`, `FEATURE-DARK-THEME-001`
3. Create epic in beads:
   ```bash
   bd create --type epic --title "Feature: {description}" --id "bd-{id}"
   ```
4. Create child molecules for PRD, research, plan
5. Initialize KV store for feature tracking
6. Set labels: `forge:feature`, `forge:ideation`

**Output:** Feature ID and beads epic created

**Intake Agent Tasks:**
- Parse natural language command
- Generate semantic ID
- Create beads structure
- Create context pack

### Stage 2: Ideation

**Purpose:** Gather requirements and create PRD.

**Analyst Agent Tasks:**
1. Conduct structured interview (if needed)
2. Generate PRD with AIDD sections:
   - Overview
   - User Stories
   - Acceptance Criteria
   - Technical Constraints
   - RESEARCH_HINTS (if areas need investigation)

**PRD Review Loop (max 5 iterations):**
1. Analyst generates/updates PRD
2. Review for completeness
3. If issues: iterate
4. When Status: READY → proceed

**PRD Format:**
```markdown
# PRD: FEATURE-XXX-XXX-001

## Status: DRAFT | REVIEW | READY

## Overview
[Feature description]

## User Stories
- As a [user], I want [goal] so that [benefit]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Technical Constraints
- Constraint 1
- Constraint 2

## AIDD:RESEARCH_HINTS (optional)
- Area needing investigation
```

**State Transition:** `forge:ideation` → `forge:planning`

### Stage 3: Planning

**Purpose:** Create implementation plan with tasks.

**Planner Agent Tasks:**
1. Read PRD and research findings
2. Break down into iterations and tasks
3. Define dependencies between tasks
4. Estimate complexity
5. Create verification criteria per task

**Plan Review Loop (max 5 iterations):**
1. Planner creates/updates plan
2. Review for completeness
3. If issues: iterate
4. When Status: READY → proceed

**Plan Format:**
```markdown
# Implementation Plan: FEATURE-XXX-XXX-001

## Status: DRAFT | REVIEW | READY

## Iteration 1: Foundation
### Task 1.1: Core Implementation
- File: `Service.kt`
- Description: Add base functionality
- Dependencies: none
- Verification: Unit tests pass

### Task 1.2: Integration
- File: `Controller.kt`
- Description: Wire up endpoints
- Dependencies: Task 1.1
- Verification: Integration tests pass

## Iteration 2: Polish
...
```

**State Transition:** `forge:planning` → `forge:implementation`

### Stage 4: Implementation (Ralph Wiggum Loop)

**Purpose:** Implement tasks with review gates.

**Per-Task Flow:**
1. **Implement** - executor:implementer writes code
2. **Test** - Run tests via executor tools
3. **Review** - executor:reviewer checks quality
4. **Decision:**
   - APPROVED → commit, mark task passing
   - ISSUES_FOUND → fix, go to step 1

**Ralph Wiggum Loop Rules:**
- One task at a time
- No skipping review
- Commit only after approval
- Track attempts per task

**Implementation Output:**
```yaml
task-001:
  status: passing
  attempts: 2
  commits: [abc123, def456]
  files_changed: [Service.kt, ServiceTest.kt]
```

**State:** `forge:implementation` (stays until all tasks complete)

### Stage 5: Completion

**Purpose:** Finalize and close feature.

**Completion Checklist:**
1. [ ] All tasks Status: passing
2. [ ] All tests pass
3. [ ] Code review approved
4. [ ] No TODOs remaining
5. [ ] Documentation updated (if needed)

**Generate Digest:**
```markdown
# Feature Complete: FEATURE-XXX-XXX-001

## Summary
[What was implemented]

## Commits
- abc123: Task 1.1 - Core implementation
- def456: Task 1.2 - Integration

## Files Changed
- src/main/kotlin/Service.kt
- src/test/kotlin/ServiceTest.kt

## Metrics
- Iterations: 2
- Tasks: 5
- Total commits: 6
```

**Close Epic:**
```bash
bd close bd-FEATURE-XXX-XXX-001 --reason "Feature complete: {summary}"
bd sync
```

**State Transition:** `forge:implementation` → `forge:complete`

## Agent Orchestration

| Stage | Agent | Purpose |
|-------|-------|---------|
| Intake | `agent-forge:intake` | Parse command, create structure |
| Ideation | `agent-forge:analyst` | Generate PRD |
| Research | `agent-forge:researcher` | Investigate technical areas |
| Planning | `agent-forge:planner` | Create implementation plan |
| Implementation | `executor:implementer` | Write code |
| Review | `executor:reviewer` | Code review |
| Verification | `executor:tester` | Run tests |

## Executor System

### Executor Selection

**Priority order:**
1. `.agent-forge/config.yaml` - Explicit `executor: <name>`
2. Auto-detection from project files (via hooks/resolve-executor.sh):
   - `build.gradle.kts` → kotlin
   - `Cargo.toml` → rust
   - `pyproject.toml` → python
   - `package.json` → typescript
   - `go.mod` → go

### Context File

After resolution, executor context is written to `.agent-forge/executor.context`:
```
executor: kotlin
executor_source: detected
executor_display: Kotlin/JVM
```

### Resolution Flow

```
Command references: executor:implementer
         ↓
Read: .agent-forge/executor.context → executor=kotlin
         ↓
Read: executors/kotlin/executor.json → agents.implementer
         ↓
Execute: executors/kotlin/implementer.md
```

## Error Handling

### PRD Review Rejected (5x)
- Escalate to user for clarification
- Document blockers
- Pause flow until resolved

### Plan Review Rejected (5x)
- Escalate to user
- May need additional research
- Consider breaking into smaller features

### Task Implementation Failing
- After 3 attempts, escalate
- May need plan revision
- Consider splitting task

### Tests Failing
- Do not commit
- Fix implementation
- Re-run review cycle

## Best Practices

1. **Start with clear requirements** - Good PRD leads to good implementation
2. **Break down into small tasks** - Easier to implement and review
3. **Test as you go** - Don't accumulate test debt
4. **Commit after each task** - Atomic, reviewable changes
5. **Document decisions** - Help future maintainers

## Common Anti-Patterns

1. **Skipping PRD review** - Leads to unclear requirements
2. **Large tasks** - Hard to implement and review
3. **Commit without review** - Quality issues
4. **Ignoring test failures** - Technical debt
5. **Scope creep** - Feature never completes

## Comparison with Other Flows

| Aspect | Feature | Bug Fix | Analysis | Refactor |
|--------|---------|---------|----------|----------|
| Planning iterations | 5 max | 2 max | N/A | 3 max |
| Interview required | Yes | No | No | No |
| Research phase | Optional | Included | Primary | Optional |
| Test strategy | Planned | Regression | N/A | Baseline |
| Iterations | Multiple | Single | N/A | Phases |
| Risk level | Medium | Low | Low | High |

## Resume Support

If interrupted, the flow can be resumed:

```
/forge-feature resume FEATURE-AUTH-OAUTH-001
```

Resume process:
1. Read current state from beads
2. Identify last completed stage
3. Continue from that point
4. Preserve all progress

State is tracked in:
- Beads issue labels (`forge:*`)
- KV store (`feature/{id}/status`)
- Context pack (`.agent-forge/context/{id}.pack.md`)
