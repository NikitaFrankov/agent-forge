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

    # Ensure executor context exists
    ensure_executor_context

    # Read executor info
    local executor=$(grep "^executor:" .agent-forge/executor.context 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "default")

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
- executor: ${executor}

## Executor
- name: ${executor}
- agents:
  - implementer: executors/${executor}/implementer.md
  - reviewer: executors/${executor}/reviewer.md
  - tester: executors/${executor}/tester.md
  - debugger: executors/${executor}/debugger.md

## Paths
- context: .agent-forge/context/${id}.pack.md
- executor_context: .agent-forge/executor.context

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

# ============================================
# Executor Detection Functions
# ============================================

# Detect executor from project files
detect_executor() {
    # Check explicit config first
    if [ -f ".agent-forge/config.yaml" ]; then
        local config_executor=$(grep -E "^executor:" .agent-forge/config.yaml | head -1 | sed 's/^executor:[[:space:]]*//' | tr -d '[:space:]')
        if [ -n "$config_executor" ]; then
            echo "$config_executor"
            return
        fi
    fi

    # Auto-detect from project files
    if [ -f "build.gradle.kts" ] || [ -f "settings.gradle.kts" ]; then
        echo "kotlin"
        return
    fi

    if [ -f "build.gradle" ]; then
        if [ -d "src/main/kotlin" ] || find . -name "*.kt" -type f 2>/dev/null | head -1 | grep -q .; then
            echo "kotlin"
            return
        fi
    fi

    if [ -f "Cargo.toml" ]; then
        echo "rust"
        return
    fi

    if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
        echo "python"
        return
    fi

    if [ -f "package.json" ]; then
        if [ -f "tsconfig.json" ] || find . -name "*.ts" -type f 2>/dev/null | head -1 | grep -q .; then
            echo "typescript"
            return
        fi
        echo "typescript"
        return
    fi

    if [ -f "go.mod" ]; then
        echo "go"
        return
    fi

    echo "default"
}

# Write executor context
write_executor_context() {
    local executor="$1"
    local source="${2:-detected}"
    local context_dir=".agent-forge"

    mkdir -p "$context_dir"

    cat > "${context_dir}/executor.context" <<EOF
# Executor Context
# Generated by beads-helpers.sh
# DO NOT EDIT MANUALLY

executor: ${executor}
executor_source: ${source}
detected_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
}

# Ensure executor context exists
ensure_executor_context() {
    if [ ! -f ".agent-forge/executor.context" ]; then
        local executor=$(detect_executor)
        write_executor_context "$executor" "detected"
    fi
}

# ============================================
# Agent Forge Initialization Functions
# ============================================

# Initialize agent-forge directory structure
init_agent_forge_dirs() {
    local config_dir=".agent-forge"

    mkdir -p "${config_dir}/context"
    mkdir -p "${config_dir}/prd"
    mkdir -p "${config_dir}/plan"
    mkdir -p "${config_dir}/diagnosis"
    mkdir -p "${config_dir}/findings"
    mkdir -p "${config_dir}/phases"

    echo "Created .agent-forge directory structure"
}

# Get executor default from executor.json
get_executor_default() {
    local executor="$1"
    local json_path="$2"
    local default="$3"
    local plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local json_file="${plugin_dir}/executors/${executor}/executor.json"

    if [ -f "$json_file" ]; then
        local value=$(jq -r "${json_path} // empty" "$json_file" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return
        fi
    fi
    echo "$default"
}

# Create full config.yaml with defaults from executor.json
create_config_yaml() {
    local executor="$1"
    local minimal="${2:-false}"
    local config_file=".agent-forge/config.yaml"
    local timestamp=$(date -u +%Y-%m-%d)

    if [ "$minimal" = "true" ]; then
        cat > "$config_file" <<EOF
# Agent Forge Configuration
executor: ${executor}
EOF
        echo "$config_file"
        return
    fi

    # Get defaults from executor.json
    local test_cmd=$(get_executor_default "$executor" '.tools.test' "")
    local test_all_cmd=$(get_executor_default "$executor" '.tools.testAll' "")
    local test_cov_cmd=$(get_executor_default "$executor" '.tools.testCoverage' "")
    local lint_cmd=$(get_executor_default "$executor" '.tools.lint' "")
    local format_cmd=$(get_executor_default "$executor" '.tools.format' "")
    local build_cmd=$(get_executor_default "$executor" '.tools.build' "")
    local src_dir=$(get_executor_default "$executor" '.patterns.srcDir' "")
    local test_dir=$(get_executor_default "$executor" '.patterns.testDir' "")
    local display_name=$(get_executor_default "$executor" '.displayName' "$executor")

    cat > "$config_file" <<EOF
# Agent Forge Configuration
# Generated by /forge-init at ${timestamp}

# Executor - overrides auto-detection
# Available: kotlin, rust, python, typescript, go, default
executor: ${executor}
EOF

    # Add tools section if we have values
    if [ -n "$test_cmd" ] || [ -n "$test_all_cmd" ] || [ -n "$lint_cmd" ] || [ -n "$format_cmd" ] || [ -n "$build_cmd" ]; then
        cat >> "$config_file" <<EOF

# Tool overrides (optional)
# Use this to customize commands for your project
tools:
EOF
        [ -n "$test_cmd" ] && echo "  test: \"${test_cmd}\"" >> "$config_file"
        [ -n "$test_all_cmd" ] && echo "  testAll: \"${test_all_cmd}\"" >> "$config_file"
        [ -n "$test_cov_cmd" ] && echo "  testCoverage: \"${test_cov_cmd}\"" >> "$config_file"
        [ -n "$lint_cmd" ] && echo "  lint: \"${lint_cmd}\"" >> "$config_file"
        [ -n "$format_cmd" ] && echo "  format: \"${format_cmd}\"" >> "$config_file"
        [ -n "$build_cmd" ] && echo "  build: \"${build_cmd}\"" >> "$config_file"
    fi

    # Add patterns section if we have values
    if [ -n "$src_dir" ] || [ -n "$test_dir" ]; then
        cat >> "$config_file" <<EOF

# Pattern overrides (optional)
# Customize source/test directory locations
patterns:
EOF
        [ -n "$src_dir" ] && echo "  srcDir: \"${src_dir}\"" >> "$config_file"
        [ -n "$test_dir" ] && echo "  testDir: \"${test_dir}\"" >> "$config_file"
    fi

    # Add defaults section
    cat >> "$config_file" <<EOF

# Flow defaults (optional)
defaults:
  # Bug fix: write regression test before fixing
  testFirst: true

  # Planning: maximum review iterations
  maxPlanIterations: 5
  maxPrdIterations: 5
EOF

    echo "$config_file"
}

# Update .gitignore with agent-forge entries
update_gitignore() {
    local gitignore=".gitignore"
    local entries=(
        ""
        "# Agent Forge"
        ".agent-forge/*.context"
        ".agent-forge/context/"
    )

    # Check if .gitignore exists
    if [ ! -f "$gitignore" ]; then
        printf '%s\n' "${entries[@]}" > "$gitignore"
        echo "Created .gitignore with agent-forge entries"
        return
    fi

    # Check if already has agent-forge entries
    if grep -q "agent-forge" "$gitignore" 2>/dev/null; then
        echo ".gitignore already has agent-forge entries"
        return
    fi

    # Append entries
    printf '\n%s\n' "${entries[@]}" >> "$gitignore"
    echo "Updated .gitignore with agent-forge entries"
}

# Full initialization of agent-forge
init_agent_forge() {
    local executor="${1:-}"
    local minimal="${2:-false}"
    local force="${3:-false}"

    # Detect executor if not provided
    if [ -z "$executor" ]; then
        executor=$(detect_executor)
    fi

    # Check if already initialized
    if [ -f ".agent-forge/config.yaml" ] && [ "$force" != "true" ]; then
        echo "Agent Forge already initialized. Use force=true to reinitialize."
        return 1
    fi

    # Create directories
    init_agent_forge_dirs

    # Create config
    create_config_yaml "$executor" "$minimal"

    # Create executor context
    write_executor_context "$executor" "init"

    echo "Agent Forge initialized with executor: ${executor}"
}
