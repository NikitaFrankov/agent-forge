#!/bin/bash
# detect-executor.sh - Auto-detect executor from project files
# Usage: bash detect-executor.sh [project_root]

PROJECT_ROOT="${1:-$(pwd)}"

detect_executor() {
    # Check for explicit config
    if [ -f "${PROJECT_ROOT}/.agent-forge/config.yaml" ]; then
        EXECUTOR=$(grep -E "^executor:" "${PROJECT_ROOT}/.agent-forge/config.yaml" | sed 's/executor: *//' | tr -d ' ')
        if [ -n "$EXECUTOR" ]; then
            echo "$EXECUTOR"
            return 0
        fi
    fi

    # Auto-detect from project files
    if [ -f "${PROJECT_ROOT}/build.gradle.kts" ] || [ -f "${PROJECT_ROOT}/build.gradle" ]; then
        echo "kotlin"
        return 0
    fi

    if [ -f "${PROJECT_ROOT}/Cargo.toml" ]; then
        echo "rust"
        return 0
    fi

    if [ -f "${PROJECT_ROOT}/pyproject.toml" ] || [ -f "${PROJECT_ROOT}/setup.py" ] || [ -f "${PROJECT_ROOT}/requirements.txt" ]; then
        echo "python"
        return 0
    fi

    if [ -f "${PROJECT_ROOT}/package.json" ]; then
        if grep -q "typescript" "${PROJECT_ROOT}/package.json" 2>/dev/null; then
            echo "typescript"
        else
            echo "javascript"
        fi
        return 0
    fi

    if [ -f "${PROJECT_ROOT}/go.mod" ]; then
        echo "go"
        return 0
    fi

    # Unknown
    echo "unknown"
    return 1
}

detect_executor
