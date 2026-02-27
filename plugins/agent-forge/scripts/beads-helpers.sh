#!/bin/bash
# beads-helpers.sh - Common beads CLI operations
# Usage: source beads-helpers.sh

set -e

# Check if beads is installed
check_beads() {
    if ! command -v bd &> /dev/null; then
        echo "ERROR: beads CLI (bd) not found"
        echo "Install from: https://github.com/steveyegge/beads"
        exit 1
    fi
}

# Generate semantic ID from description
generate_semantic_id() {
    local description="$1"
    local flow_type="$2"

    # Extract key words (remove common words, take first 3 significant words)
    local keywords=$(echo "$description" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/добавить\|исправить\|починить\|проверить\|проанализировать\|найти\|add\|fix\|check\|analyze\|find\|the\|a\|an\|in\|for\|to\|of\|and\|or\|с\|в\|на\|для\|и\|или//g' | \
        tr -d '[:punct:]' | \
        tr ' ' '\n' | \
        grep -v '^$' | \
        head -3 | \
        tr '\n' '-' | \
        sed 's/-$//' | \
        cut -c1-20 | \
        tr '[:lower:]' '[:upper:]')

    # Get next number
    local number=$(get_next_number "$flow_type" "$keywords")
    printf "%s-%s-%03d" "$flow_type" "$keywords" "$number"
}

# Get next available number for ID
get_next_number() {
    local flow_type="$1"
    local semantic="$2"

    # Try to find existing issues with same prefix
    local existing=$(bd list --id "${flow_type}-${semantic}-*" --format count 2>/dev/null || echo "0")
    echo $((existing + 1))
}

# Initialize feature flow in beads
init_feature_flow() {
    local id="$1"
    local description="$2"

    # Create epic
    bd create --type epic --title "Feature: ${description}" --id "bd-${id}" --silent

    # Create child molecules
    bd create --type molecule --title "PRD: ${id}" --parent "bd-${id}" --id "bd-${id}-prd" --silent
    bd create --type molecule --title "Research: ${id}" --parent "bd-${id}" --id "bd-${id}-research" --silent
    bd create --type molecule --title "Plan: ${id}" --parent "bd-${id}" --id "bd-${id}-plan" --silent

    # Initialize KV store
    bd kv set "feature/${id}/description" "$description"
    bd kv set "feature/${id}/flow_type" "feature"
    bd kv set "feature/${id}/created_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Set labels
    bd label add "bd-${id}" forge:feature forge:ideation

    echo "bd-${id}"
}

# Initialize fix flow in beads
init_fix_flow() {
    local id="$1"
    local description="$2"

    # Create bug issue
    bd create --type bug --title "Bug: ${description}" --id "bd-${id}" --silent

    # Initialize KV store
    bd kv set "fix/${id}/description" "$description"
    bd kv set "fix/${id}/flow_type" "fix"
    bd kv set "fix/${id}/created_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    bd kv set "fix/${id}/status" "pending_diagnosis"

    # Set labels
    bd label add "bd-${id}" forge:fix forge:pending_diagnosis

    echo "bd-${id}"
}

# Initialize analyze flow in beads
init_analyze_flow() {
    local id="$1"
    local description="$2"
    local analysis_type="$3"

    # Create analysis issue
    bd create --type analysis --title "Analysis: ${description}" --id "bd-${id}" --silent

    # Initialize KV store
    bd kv set "analysis/${id}/description" "$description"
    bd kv set "analysis/${id}/flow_type" "analyze"
    bd kv set "analysis/${id}/analysis_type" "$analysis_type"
    bd kv set "analysis/${id}/created_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    bd kv set "analysis/${id}/status" "pending_research"

    # Set labels
    bd label add "bd-${id}" forge:analyze forge:pending_research

    echo "bd-${id}"
}

# Initialize refactor flow in beads
init_refactor_flow() {
    local id="$1"
    local description="$2"

    # Create epic
    bd create --type epic --title "Refactor: ${description}" --id "bd-${id}" --silent

    # Initialize KV store
    bd kv set "refactor/${id}/description" "$description"
    bd kv set "refactor/${id}/flow_type" "refactor"
    bd kv set "refactor/${id}/created_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    bd kv set "refactor/${id}/risk_level" "pending_assessment"
    bd kv set "refactor/${id}/status" "pending_baseline"

    # Set labels
    bd label add "bd-${id}" forge:refactor forge:pending_baseline

    # Create baseline snapshot
    git tag "refactor/${id}/baseline" 2>/dev/null || true
    bd kv set "refactor/${id}/baseline_commit" "$(git rev-parse HEAD)"
    bd kv set "refactor/${id}/baseline_tag" "refactor/${id}/baseline"

    echo "bd-${id}"
}

# Detect analysis type from description
detect_analysis_type() {
    local description="$1"
    local desc_lower=$(echo "$description" | tr '[:upper:]' '[:lower:]')

    # Security keywords
    if echo "$desc_lower" | grep -qE 'безопасност|уязвимост|security|vulnerab|auth|защит|protect'; then
        echo "security"
        return
    fi

    # Performance keywords
    if echo "$desc_lower" | grep -qE 'производительност|медленн|performance|slow|bottleneck|оптимиз|optim'; then
        echo "performance"
        return
    fi

    # Architecture keywords
    if echo "$desc_lower" | grep -qE 'архитектур|architect|структур|structure|component|module|модул'; then
        echo "architecture"
        return
    fi

    # Code quality keywords
    if echo "$desc_lower" | grep -qE 'долг|качеств|debt|quality|smell|refactor|рефакторинг'; then
        echo "code-quality"
        return
    fi

    # Dependency keywords
    if echo "$desc_lower" | grep -qE 'зависимост|dependency|библиотек|library|package|пакет'; then
        echo "dependency"
        return
    fi

    # Default
    echo "general"
}

# Get current flow state
get_flow_state() {
    local id="$1"
    local labels=$(bd show "bd-${id}" --format labels 2>/dev/null)

    # Extract forge: state
    echo "$labels" | grep -oE 'forge:[a-z_]+' | head -1 | sed 's/forge://'
}

# Update flow state
update_flow_state() {
    local id="$1"
    local new_state="$2"
    local reason="${3:-}"

    # Remove old forge: labels
    local old_labels=$(bd show "bd-${id}" --format labels 2>/dev/null | grep -oE 'forge:[a-z_]+')
    for label in $old_labels; do
        bd label remove "bd-${id}" "$label" 2>/dev/null || true
    done

    # Add new state label
    bd label add "bd-${id}" "forge:${new_state}"

    # Add comment if reason provided
    if [ -n "$reason" ]; then
        bd comments add "bd-${id}" "State transition: ${new_state} - ${reason}"
    fi
}

# Create context pack
create_context_pack() {
    local id="$1"
    local flow_type="$2"
    local description="$3"
    local next_agent="$4"

    local pack_dir=".agent-forge/context"
    mkdir -p "$pack_dir"

    cat > "${pack_dir}/${id}.pack.md" <<EOF
# Context Pack: ${id}

## Metadata
- id: ${id}
- flow_type: ${flow_type}
- description: ${description}
- created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- beads_id: bd-${id}

## Paths
- context: .agent-forge/context/${id}.pack.md

## State
- current_phase: intake
- next_agent: ${next_agent}

## What To Do Now
Launch ${next_agent} agent to begin the flow.
EOF

    echo "${pack_dir}/${id}.pack.md"
}

# Check if beads is available at script load
check_beads
