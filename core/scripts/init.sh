#!/bin/bash
# init.sh - Initialize .agent-forge/ workspace structure
# Usage: bash ${CLAUDE_PLUGIN_ROOT}/core/scripts/init.sh

set -e

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
FORGE_DIR="${PROJECT_ROOT}/.agent-forge"

echo "🔥 Initializing agent-forge workspace..."

# Create directory structure
mkdir -p "${FORGE_DIR}/context"
mkdir -p "${FORGE_DIR}/ideas"
mkdir -p "${FORGE_DIR}/prd"
mkdir -p "${FORGE_DIR}/research"
mkdir -p "${FORGE_DIR}/plan"
mkdir -p "${FORGE_DIR}/tasklist"
mkdir -p "${FORGE_DIR}/activity"
mkdir -p "${FORGE_DIR}/screenshots"
mkdir -p "${FORGE_DIR}/archive"

# Create PROMPT.md template
cat > "${FORGE_DIR}/PROMPT.md.template" << 'EOF'
# Implementation Iteration: $TICKET

## Pre-Iteration Checks

1. **Read Codebase Patterns**
   ```
   Read .agent-forge/activity/$TICKET.md
   ```
   Look for `## Codebase Patterns` section at the top.

2. **Verify Correct Branch**
   ```bash
   git branch --show-current
   ```
   Should be: `feature/$TICKET-<slug>`

## Your Task

1. Find the next task with `Status: pending` or `Status: failing` in the plan
2. Read task requirements from `.agent-forge/plan/$TICKET.md`
3. Load executor guidance from `.agent-forge/executors/<executor>/`
4. Implement the task following executor patterns
5. Run tests using executor-specific commands
6. Report completion (DO NOT COMMIT until code-reviewer APPROVES)

## After Implementation

- Update `.agent-forge/activity/$TICKET.md` with changes made
- Wait for code-reviewer agent APPROVAL
- Only after APPROVAL: commit and mark task as `Status: passing`

## Completion

When ALL tasks have `Status: passing`, output:
```
<promise>COMPLETE</promise>
```

## Ralph Principles

1. Fresh context per iteration
2. Single task per iteration
3. Two-stage review (implementer → code-reviewer)
4. Commit only after APPROVAL
5. 50 retry strategy for errors
EOF

# Create AGENTS.md template
cat > "${FORGE_DIR}/AGENTS.md.template" << 'EOF'
# Codebase Documentation: $PROJECT_NAME

## Purpose
<Brief description of the project's purpose>

## Key Files
- `src/` - Source code
- `tests/` - Test files
- `<config>` - Configuration

## Patterns
<Discovered patterns will be added here>

## Gotchas
<Common pitfalls will be documented here>
EOF

# Create initial config.yaml
cat > "${FORGE_DIR}/config.yaml" << 'EOF'
# Agent Forge Configuration

# Executor selection (optional - auto-detected if not set)
# executor: kotlin

# Auto-detect from project files:
# - build.gradle.kts → kotlin
# - Cargo.toml → rust
# - pyproject.toml → python
# - package.json → typescript

# Branch naming
branch_prefix: feature/
EOF

# Create initial activity file with patterns section
cat > "${FORGE_DIR}/activity/.gitkeep" << 'EOF'
# Activity logs will be created per ticket
# Format: .agent-forge/activity/<ticket>.md
EOF

# Add .agent-forge/ to .gitignore if not already present
if [ -f "${PROJECT_ROOT}/.gitignore" ]; then
    if ! grep -q ".agent-forge/" "${PROJECT_ROOT}/.gitignore"; then
        echo "" >> "${PROJECT_ROOT}/.gitignore"
        echo "# Agent Forge workspace" >> "${PROJECT_ROOT}/.gitignore"
        echo ".agent-forge/" >> "${PROJECT_ROOT}/.gitignore"
        echo "Added .agent-forge/ to .gitignore"
    fi
fi

# Detect project type and suggest executor
DETECTED_EXECUTOR=""
if [ -f "${PROJECT_ROOT}/build.gradle.kts" ] || [ -f "${PROJECT_ROOT}/build.gradle" ]; then
    DETECTED_EXECUTOR="kotlin"
elif [ -f "${PROJECT_ROOT}/Cargo.toml" ]; then
    DETECTED_EXECUTOR="rust"
elif [ -f "${PROJECT_ROOT}/pyproject.toml" ] || [ -f "${PROJECT_ROOT}/setup.py" ]; then
    DETECTED_EXECUTOR="python"
elif [ -f "${PROJECT_ROOT}/package.json" ]; then
    DETECTED_EXECUTOR="typescript"
fi

echo ""
echo "✅ Agent Forge workspace initialized at ${FORGE_DIR}"
echo ""
echo "📁 Created structure:"
echo "   .agent-forge/"
echo "   ├── context/      # Context Packs"
echo "   ├── ideas/        # Interview notes"
echo "   ├── prd/          # Product Requirements"
echo "   ├── research/     # Research findings"
echo "   ├── plan/         # Implementation plans"
echo "   ├── activity/     # Progress logs"
echo "   ├── screenshots/  # UI screenshots"
echo "   ├── archive/      # Previous runs"
echo "   └── config.yaml   # Configuration"
echo ""

if [ -n "$DETECTED_EXECUTOR" ]; then
    echo "🔍 Detected executor: ${DETECTED_EXECUTOR}"
    echo "   Run: echo 'executor: ${DETECTED_EXECUTOR}' >> ${FORGE_DIR}/config.yaml"
fi

echo ""
echo "🚀 Ready to use:"
echo "   /forge-idea <ticket>   # Collect requirements"
echo "   /forge-plan <ticket>   # Create plan"
echo "   /forge-exec <ticket>   # Implement"
echo "   /forge-run <ticket>    # Full pipeline"
