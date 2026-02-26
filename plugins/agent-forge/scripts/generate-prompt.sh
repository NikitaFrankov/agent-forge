#!/bin/bash
# generate-prompt.sh - Generate iteration PROMPT.md with executor context
# Usage: bash generate-prompt.sh <ticket> [executor]

set -e

TICKET="$1"
EXPLICIT_EXECUTOR="$2"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
FORGE_DIR="${PROJECT_ROOT}/.agent-forge"
PLUGIN_ROOT="${PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"

if [ -z "$TICKET" ]; then
    echo "Usage: generate-prompt.sh <ticket> [executor]"
    exit 1
fi

# Detect or use explicit executor
if [ -n "$EXPLICIT_EXECUTOR" ]; then
    EXECUTOR="$EXPLICIT_EXECUTOR"
else
    EXECUTOR=$(bash "${PLUGIN_ROOT}/scripts/detect-executor.sh" "$PROJECT_ROOT")
fi

if [ "$EXECUTOR" = "unknown" ]; then
    echo "ERROR: Could not detect executor. Please specify with --executor <name>"
    exit 1
fi

EXECUTOR_DIR="${PLUGIN_ROOT}/executors/${EXECUTOR}"

if [ ! -d "$EXECUTOR_DIR" ]; then
    echo "ERROR: Executor '$EXECUTOR' not found at $EXECUTOR_DIR"
    exit 1
fi

# Load executor config
if [ -f "${EXECUTOR_DIR}/executor.json" ]; then
    # Extract tool commands from JSON (simple parsing)
    TEST_CMD=$(grep -A1 '"test"' "${EXECUTOR_DIR}/executor.json" | grep -o '"[^"]*"' | tail -1 | tr -d '"')
    LINT_CMD=$(grep -A1 '"lint"' "${EXECUTOR_DIR}/executor.json" | grep -o '"[^"]*"' | tail -1 | tr -d '"')
    BUILD_CMD=$(grep -A1 '"build"' "${EXECUTOR_DIR}/executor.json" | grep -o '"[^"]*"' | tail -1 | tr -d '"')
else
    TEST_CMD=""
    LINT_CMD=""
    BUILD_CMD=""
fi

# Load executor guidance
GENERATOR_GUIDANCE=""
DEBUGGER_GUIDANCE=""

if [ -f "${EXECUTOR_DIR}/generator.md" ]; then
    # Include key patterns from generator (first 50 lines as context)
    GENERATOR_GUIDANCE=$(head -100 "${EXECUTOR_DIR}/generator.md" | sed 's/^/  /')
fi

if [ -f "${EXECUTOR_DIR}/debugger.md" ]; then
    # Include 50 retry strategy summary
    DEBUGGER_GUIDANCE=$(head -50 "${EXECUTOR_DIR}/debugger.md" | sed 's/^/  /')
fi

# Generate PROMPT.md
cat > "${FORGE_DIR}/PROMPT.md" << EOF
# Implementation Iteration: ${TICKET}

## Executor: ${EXECUTOR}

This iteration uses the **${EXECUTOR}** executor. Follow the patterns and commands below.

---

## Pre-Iteration Checks

1. **Read Codebase Patterns**
   \`\`\`
   Read .agent-forge/activity/${TICKET}.md
   \`\`\`
   Look for \`## Codebase Patterns\` section at the top.

2. **Verify Correct Branch**
   \`\`\`bash
   git branch --show-current
   \`\`\`
   Should be: \`feature/${TICKET}-<slug>\`

---

## Your Task

1. Find the next task with \`Status: pending\` or \`Status: failing\` in the plan
2. Read task requirements from \`.agent-forge/plan/${TICKET}.md\`
3. **Follow executor patterns below** for implementation
4. Implement the task
5. Run tests using executor commands
6. Report completion (DO NOT COMMIT until code-reviewer APPROVES)

---

## Executor Commands

### Testing
\`\`\`bash
${TEST_CMD:-# Test command not defined}
\`\`\`

### Linting
\`\`\`bash
${LINT_CMD:-# Lint command not defined}
\`\`\`

### Building
\`\`\`bash
${BUILD_CMD:-# Build command not defined}
\`\`\`

---

## Executor Code Patterns (${EXECUTOR})

${GENERATOR_GUIDANCE}

---

## Debugging Strategy (50 Retry)

${DEBUGGER_GUIDANCE}

---

## After Implementation

1. Update \`.agent-forge/activity/${TICKET}.md\` with changes made
2. Report completion for code review
3. Wait for APPROVAL before committing
4. Only after APPROVAL: commit and mark task as \`Status: passing\`

---

## Completion

When ALL tasks have \`Status: passing\`, output:
\`\`\`
<promise>COMPLETE</promise>
\`\`\`

---

## Ralph Principles

1. Fresh context per iteration
2. Single task per iteration
3. Two-stage review (implementer → code-reviewer)
4. Commit only after APPROVAL
5. 50 retry strategy for errors
6. Follow executor patterns exactly
EOF

echo "Generated: ${FORGE_DIR}/PROMPT.md"
echo "Executor: ${EXECUTOR}"
echo ""
echo "Executor guidance loaded from:"
echo "  - ${EXECUTOR_DIR}/executor.json (commands)"
echo "  - ${EXECUTOR_DIR}/generator.md (patterns)"
echo "  - ${EXECUTOR_DIR}/debugger.md (debugging)"
