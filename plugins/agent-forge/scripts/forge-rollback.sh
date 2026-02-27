#!/bin/bash
# forge-rollback.sh - Rollback utilities for refactoring flow
# Usage: bash forge-rollback.sh <command> [args]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/beads-helpers.sh"

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    list)
        # List all rollback points for a refactoring
        ID="$1"
        if [ -z "$ID" ]; then
            echo "Usage: forge-rollback.sh list <id>"
            exit 1
        fi

        echo "=== Rollback Points: ${ID} ==="
        echo ""

        # Get baseline
        BASELINE_TAG=$(bd kv get "refactor/${ID}/baseline_tag" 2>/dev/null || echo "refactor/${ID}/baseline")
        BASELINE_COMMIT=$(bd kv get "refactor/${ID}/baseline_commit" 2>/dev/null || echo "unknown")

        echo "BASELINE:"
        echo "  Tag: ${BASELINE_TAG}"
        echo "  Commit: ${BASELINE_COMMIT}"
        echo ""

        # Get phase rollback points
        echo "PHASE ROLLBACK POINTS:"
        bd kv list "refactor/${ID}/rollback_points" 2>/dev/null | while read -r line; do
            if [ -n "$line" ]; then
                local phase=$(echo "$line" | sed 's/phase_//' | sed 's|/.*||')
                local tag=$(bd kv get "refactor/${ID}/rollback_points/phase_${phase}/tag" 2>/dev/null || echo "unknown")
                local commit=$(bd kv get "refactor/${ID}/rollback_points/phase_${phase}/commit" 2>/dev/null || echo "unknown")
                echo "  Phase ${phase}:"
                echo "    Tag: ${tag}"
                echo "    Commit: ${commit}"
            fi
        done
        ;;

    to)
        # Rollback to a specific point
        ID="$1"
        PHASE="$2"

        if [ -z "$ID" ] || [ -z "$PHASE" ]; then
            echo "Usage: forge-rollback.sh to <id> <phase|baseline>"
            exit 1
        fi

        # Determine tag
        if [ "$PHASE" = "baseline" ]; then
            TAG=$(bd kv get "refactor/${ID}/baseline_tag" 2>/dev/null || echo "refactor/${ID}/baseline")
        else
            # Phase number provided - rollback to BEFORE this phase
            PREV_PHASE=$((PHASE - 1))
            if [ $PREV_PHASE -eq 0 ]; then
                TAG=$(bd kv get "refactor/${ID}/baseline_tag" 2>/dev/null || echo "refactor/${ID}/baseline")
            else
                TAG="refactor/${ID}/pre-phase-${PHASE}"
            fi
        fi

        echo "=== Rolling Back: ${ID} ==="
        echo "Target: ${TAG}"
        echo ""

        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            echo "WARNING: You have uncommitted changes"
            echo "Stashing changes..."
            git stash push -m "refactor-rollback-${ID}-$(date +%Y%m%d%H%M%S)"
        fi

        # Get commit for tag
        COMMIT=$(git rev-parse "$TAG" 2>/dev/null)
        if [ -z "$COMMIT" ]; then
            echo "ERROR: Tag not found: ${TAG}"
            exit 1
        fi

        echo "Resetting to: ${COMMIT}"
        git reset --hard "$COMMIT"

        # Update beads status
        if [ "$PHASE" != "baseline" ]; then
            bd label add "bd-${ID}-PHASE-${PHASE}" refactor:rolled-back 2>/dev/null || true
            bd kv set "refactor/${ID}/phases/${PHASE}/status" "rolled-back"
            bd comments add "bd-${ID}" "Rolled back to before Phase ${PHASE}"
        else
            bd comments add "bd-${ID}" "Rolled back to baseline"
        fi

        echo ""
        echo "Rollback complete!"
        echo "Current state: ${COMMIT}"
        ;;

    verify)
        # Verify rollback point integrity
        ID="$1"
        if [ -z "$ID" ]; then
            echo "Usage: forge-rollback.sh verify <id>"
            exit 1
        fi

        echo "=== Verifying Rollback Points: ${ID} ==="

        # Check baseline
        BASELINE_TAG=$(bd kv get "refactor/${ID}/baseline_tag" 2>/dev/null || echo "refactor/${ID}/baseline")
        if git rev-parse "$BASELINE_TAG" >/dev/null 2>&1; then
            echo "✓ Baseline tag exists: ${BASELINE_TAG}"
        else
            echo "✗ Baseline tag missing: ${BASELINE_TAG}"
        fi

        # Check phase tags
        PHASE_COUNT=$(bd kv get "refactor/${ID}/plan/phases_count" 2>/dev/null || echo "0")
        for i in $(seq 1 $PHASE_COUNT); do
            TAG="refactor/${ID}/pre-phase-$((i+1))"
            if git rev-parse "$TAG" >/dev/null 2>&1; then
                echo "✓ Phase ${i} rollback point exists: ${TAG}"
            else
                echo "- Phase ${i} rollback point not created yet"
            fi
        done
        ;;

    create)
        # Create a rollback point
        ID="$1"
        PHASE="$2"

        if [ -z "$ID" ] || [ -z "$PHASE" ]; then
            echo "Usage: forge-rollback.sh create <id> <phase>"
            exit 1
        fi

        # Tag name for BEFORE the next phase
        NEXT_PHASE=$((PHASE + 1))
        TAG="refactor/${ID}/pre-phase-${NEXT_PHASE}"

        echo "Creating rollback point: ${TAG}"

        # Create git tag
        git tag "$TAG"

        # Store in beads
        bd kv set "refactor/${ID}/rollback_points/phase_${PHASE}/tag" "$TAG"
        bd kv set "refactor/${ID}/rollback_points/phase_${PHASE}/commit" "$(git rev-parse HEAD)"
        bd kv set "refactor/${ID}/rollback_points/phase_${PHASE}/created" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

        echo "Rollback point created: ${TAG}"
        ;;

    clean)
        # Clean up rollback points after successful refactoring
        ID="$1"
        if [ -z "$ID" ]; then
            echo "Usage: forge-rollback.sh clean <id>"
            exit 1
        fi

        echo "=== Cleaning Rollback Points: ${ID} ==="

        # Delete phase tags
        PHASE_COUNT=$(bd kv get "refactor/${ID}/plan/phases_count" 2>/dev/null || echo "0")
        for i in $(seq 1 $PHASE_COUNT); do
            TAG="refactor/${ID}/pre-phase-$((i+1))"
            if git rev-parse "$TAG" >/dev/null 2>&1; then
                echo "Deleting tag: ${TAG}"
                git tag -d "$TAG"
            fi
        done

        # Optionally keep baseline
        read -p "Delete baseline tag? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BASELINE_TAG=$(bd kv get "refactor/${ID}/baseline_tag" 2>/dev/null || echo "refactor/${ID}/baseline")
            git tag -d "$BASELINE_TAG"
            echo "Baseline tag deleted"
        fi

        echo "Rollback points cleaned"
        ;;

    help|*)
        echo "Agent-Forge Rollback Utilities"
        echo ""
        echo "Usage: forge-rollback.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  list <id>                     List all rollback points"
        echo "  to <id> <phase|baseline>      Rollback to specific point"
        echo "  verify <id>                   Verify rollback point integrity"
        echo "  create <id> <phase>           Create a rollback point"
        echo "  clean <id>                    Clean up rollback points"
        echo ""
        echo "Examples:"
        echo "  forge-rollback.sh list REFACTOR-USER-SVC-001"
        echo "  forge-rollback.sh to REFACTOR-USER-SVC-001 2"
        echo "  forge-rollback.sh create REFACTOR-USER-SVC-001 1"
        echo "  forge-rollback.sh verify REFACTOR-USER-SVC-001"
        ;;
esac
