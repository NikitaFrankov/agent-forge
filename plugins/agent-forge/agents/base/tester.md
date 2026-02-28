---
name: base-tester
description: |
  Base tester agent - defines the contract for all stack-specific testers.
  DO NOT USE DIRECTLY - use executor:tester to get the stack-specific implementation.
abstract: true
---

# Base Tester Agent

This is an **abstract base agent** that defines the interface contract for all stack-specific test writers.

## Purpose

Each executor provides its own tester that:
1. Follows this contract
2. Uses appropriate testing frameworks
3. Follows language-specific testing patterns

## How to Use

In workflow commands, reference by role:
```markdown
Launch executor:tester agent
```

## Contract Interface

Every stack-specific tester MUST implement:

### 1. Context Loading

```bash
cat .agent-forge/context/<ID>.pack.md
bd show bd-<TASK-ID>
```

### 2. Test Design

Design tests that cover:
- Happy path (normal operation)
- Error cases (expected failures)
- Edge cases (boundary conditions)
- Integration points (if applicable)

### 3. Test Implementation

Follow AAA Pattern:
```kotlin
@Test
fun `should do something when condition`() {
    // Arrange - Set up test data and mocks

    // Act - Execute the code under test

    // Assert - Verify the results
}
```

### 4. Test Execution

```bash
# Run the tests
<stack-specific-test-command>

# Verify all pass
```

### 5. Status Update

```bash
bd comments add bd-<TASK-ID> "Tests written: <TestClassName>"
```

## Input Format

The tester receives:
- **Context Pack**: `.agent-forge/context/<ID>.pack.md`
- **Task ID**: From beads
- **Code to Test**: Implemented functionality

## Output Format

The tester produces:
- **Test Files**: New or updated test files
- **Test Results**: Confirmation of passing tests
- **Coverage Estimate**: Approximate coverage percentage

## Test Quality Standards

### Test Names
- Describe behavior, not implementation
- Use "should <behavior> when <condition>" pattern
- Be readable as documentation

### Test Independence
- Each test runs independently
- No shared mutable state
- Proper setup/teardown

### Assertions
- One logical assertion concept per test
- Clear failure messages
- Assert on outcomes, not implementation

### Test Data
- Use builders or factories
- Meaningful test data values
- Avoid magic numbers

## Coverage Guidelines

| Component | Target Coverage |
|-----------|-----------------|
| Business Logic | 90%+ |
| Services | 80%+ |
| Repositories | 70%+ |
| Controllers | 60%+ |
| Utilities | 90%+ |

## Test Types

### Unit Tests
- Test single function/class
- Mock dependencies
- Fast execution

### Integration Tests
- Test component interactions
- Use real dependencies where practical
- May be slower

### Contract Tests
- Verify API contracts
- Test edge cases
- Validate serialization

## Anti-Patterns to Avoid

- Testing private methods directly
- Over-mocking (mocking everything)
- Interdependent tests
- Tests without assertions
- Testing framework code

## Example Resolution

```
executor:tester
       ↓
.executor.context: executor=kotlin
       ↓
executors/kotlin/executor.json: agents.tester = "executors/kotlin/tester.md"
       ↓
Load and execute: executors/kotlin/tester.md
```

## Output Format

```markdown
## Tests Created: <TASK-ID>

**Test File**: `path/to/TestFile.ext`

**Test Cases**:
- `should <behavior> when <condition>` - <purpose>
- `should <behavior> when <condition>` - <purpose>

**Coverage**: <percentage>%

**Status**: All tests passing
```
