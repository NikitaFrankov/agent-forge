#!/bin/bash
# forge-state.sh - State management utilities for agent-forge flows
# Usage: bash forge-state.sh <command> [args]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/beads-helpers.sh"

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    get)
        # Get current state of a flow
        ID="$1"
        if [ -z "$ID" ]; then
            echo "Usage: forge-state.sh get <id>"
            exit 1
        fi
        get_flow_state "$ID"
        ;;

    set)
        # Set state of a flow
        ID="$1"
        STATE="$2"
        REASON="$3"
        if [ -z "$ID" ] || [ -z "$STATE" ]; then
            echo "Usage: forge-state.sh set <id> <state> [reason]"
            exit 1
        fi
        update_flow_state "$ID" "$STATE" "$REASON"
        echo "State updated: bd-${ID} -> ${STATE}"
        ;;

    show)
        # Show detailed state info
        ID="$1"
        if [ -z "$ID" ]; then
            echo "Usage: forge-state.sh show <id>"
            exit 1
        fi
        bd show "bd-${ID}" --json 2>/dev/null | jq '{
            id: .id,
            title: .title,
            status: .status,
            labels: .labels,
            created: .created_at
        }'
        ;;

    list)
        # List all flows by type
        TYPE="$1"
        case "$TYPE" in
            feature|fix|analyze|refactor)
                bd list --label "forge:${TYPE}" --format table
                ;;
            all|"")
                echo "=== Features ==="
                bd list --label "forge:feature" --format table 2>/dev/null || echo "None"
                echo ""
                echo "=== Fixes ==="
                bd list --label "forge:fix" --format table 2>/dev/null || echo "None"
                echo ""
                echo "=== Analysis ==="
                bd list --label "forge:analyze" --format table 2>/dev/null || echo "None"
                echo ""
                echo "=== Refactoring ==="
                bd list --label "forge:refactor" --format table 2>/dev/null || echo "None"
                ;;
            *)
                echo "Unknown type: $TYPE"
                echo "Valid types: feature, fix, analyze, refactor, all"
                exit 1
                ;;
        esac
        ;;

    progress)
        # Show progress of a specific flow
        ID="$1"
        if [ -z "$ID" ]; then
            echo "Usage: forge-state.sh progress <id>"
            exit 1
        fi

        echo "=== Flow Progress: ${ID} ==="
        echo ""

        # Get flow type
        FLOW_TYPE=$(bd show "bd-${ID}" --format labels 2>/dev/null | grep -oE 'forge:(feature|fix|analyze|refactor)' | sed 's/forge://')

        case "$FLOW_TYPE" in
            feature)
                echo "PRD Status:"
                bd show "bd-${ID}-prd" --format status 2>/dev/null || echo "  Not started"
                echo ""
                echo "Plan Status:"
                bd show "bd-${ID}-plan" --format status 2>/dev/null || echo "  Not started"
                echo ""
                echo "Tasks:"
                bd list --parent "bd-${ID}" --type task --format table 2>/dev/null || echo "  None"
                ;;
            fix)
                echo "Diagnosis:"
                bd kv get "fix/${ID}/status" 2>/dev/null || echo "  Not started"
                echo ""
                echo "Fix Plan:"
                bd show "bd-${ID}-plan" --format status 2>/dev/null || echo "  Not started"
                ;;
            analyze)
                echo "Analysis Status:"
                bd kv get "analysis/${ID}/status" 2>/dev/null || echo "  Not started"
                echo ""
                echo "Findings Count:"
                bd kv list "analysis/${ID}/findings" 2>/dev/null | wc -l || echo "  0"
                ;;
            refactor)
                echo "Risk Level:"
                bd kv get "refactor/${ID}/risk_level" 2>/dev/null || echo "  Not assessed"
                echo ""
                echo "Phases:"
                bd list --parent "bd-${ID}" --type task --format table 2>/dev/null || echo "  Not started"
                echo ""
                echo "Rollback Points:"
                bd kv list "refactor/${ID}/rollback_points" 2>/dev/null || echo "  None"
                ;;
            *)
                echo "Unknown flow type: ${FLOW_TYPE}"
                ;;
        esac
        ;;

    kv)
        # KV store operations
        ACTION="$1"
        PATH="$2"
        VALUE="$3"

        case "$ACTION" in
            get)
                bd kv get "$PATH"
                ;;
            set)
                bd kv set "$PATH" "$VALUE"
                ;;
            list)
                bd kv list "$PATH"
                ;;
            delete)
                bd kv delete "$PATH"
                ;;
            *)
                echo "Usage: forge-state.sh kv <get|set|list|delete> <path> [value]"
                exit 1
                ;;
        esac
        ;;

    help|*)
        echo "Agent-Forge State Management"
        echo ""
        echo "Usage: forge-state.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  get <id>              Get current state of a flow"
        echo "  set <id> <state>      Set state of a flow"
        echo "  show <id>             Show detailed state info"
        echo "  list [type]           List all flows (type: feature|fix|analyze|refactor|all)"
        echo "  progress <id>         Show progress of a specific flow"
        echo "  kv <get|set|list|delete> <path> [value]"
        echo "                        KV store operations"
        echo ""
        echo "Examples:"
        echo "  forge-state.sh get FEATURE-AUTH-001"
        echo "  forge-state.sh set FEATURE-AUTH-001 planning"
        echo "  forge-state.sh list feature"
        echo "  forge-state.sh progress REFACTOR-USER-SVC-001"
        echo "  forge-state.sh kv get feature/AUTH-001/executor"
        ;;
esac
