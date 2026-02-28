---
name: base-implementer
description: |
  Base implementer agent - defines the contract for all stack-specific implementers.
  DO NOT USE DIRECTLY - use executor:implementer to get the stack-specific implementation.
abstract: true
---

# Base Implementer Agent

This is an **abstract base agent** that defines the interface contract for all stack-specific implementers.

## Purpose

Each executor (kotlin, rust, python, typescript, etc.) provides its own implementer that:
1. Follows this contract
2. Adds stack-specific knowledge and patterns
3. Uses appropriate tools and commands

## How to Use

In workflow commands, reference by role:
```markdown
Launch executor:implementer agent
```

The system resolves this to the correct agent based on the detected executor.

## Contract Interface

Every stack-specific implementer MUST implement the following:

### 1. Context Loading

```bash
# Read the context pack
cat .agent-forge/context/<ID>.pack.md

# Read task details
bd show bd-<TASK-ID>
```

### 2. Task Implementation

Given a task from the plan, the implementer:
- Reads and understands the task requirements
- Implements the code changes
- Follows project conventions
- Maintains existing patterns

### 3. Testing

After implementation:
- Run relevant tests
- Verify all tests pass
- Add new tests if required by task

### 4. Status Update

Update beads with progress:
```bash
bd comments add bd-<TASK-ID> "Implementation complete"
bd update bd-<TASK-ID> --status=completed
```

## Input Format

The implementer receives:
- **Context Pack**: `.agent-forge/context/<ID>.pack.md`
- **Task ID**: From beads
- **Task Description**: Detailed requirements

## Output Format

The implementer produces:
- **Code Changes**: Modified/created files
- **Test Results**: Verification that tests pass
- **Status Update**: Beads task marked complete

## Error Handling

If blocked:
1. Document the blocker in beads
2. Keep task in `in_progress` status
3. Provide clear description of what's needed

```bash
bd comments add bd-<TASK-ID> "BLOCKED: <reason>"
# Do NOT mark as completed
```

## Quality Standards

- Code compiles without errors
- All existing tests pass
- New code has appropriate test coverage
- Code follows project conventions
- No security vulnerabilities introduced

## Executor Resolution

When a command references `executor:implementer`:

1. Read `.agent-forge/executor.context` to get executor name
2. Look up agent path in `executors/<name>/executor.json`
3. Load the stack-specific implementer agent
4. Execute with full context

## Example Resolution

```
executor:implementer
       ↓
.executor.context: executor=kotlin
       ↓
executors/kotlin/executor.json: agents.implementer = "executors/kotlin/implementer.md"
       ↓
Load and execute: executors/kotlin/implementer.md
```
