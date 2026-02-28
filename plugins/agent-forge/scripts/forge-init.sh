#!/bin/bash
# forge-init.sh - Initialize agent-forge in a project
# Usage: forge-init.sh [--executor <name>] [--force] [--minimal] [--skip-gitignore]
#
# This script:
# 1. Detects project executor
# 2. Creates .agent-forge directory structure
# 3. Generates config.yaml with defaults
# 4. Creates executor.context
# 5. Updates .gitignore

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
EXECUTORS_DIR="${PLUGIN_DIR}/executors"

# Default values
FORGE_EXECUTOR=""
FORCE=false
MINIMAL=false
SKIP_GITIGNORE=false
CONFIG_DIR=".agent-forge"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
CONTEXT_FILE="${CONFIG_DIR}/executor.context"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
log_info() { echo -e "${BLUE}[forge-init]${NC} $1"; }
log_success() { echo -e "${GREEN}[forge-init]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[forge-init]${NC} $1"; }
log_error() { echo -e "${RED}[forge-init]${NC} $1"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --executor)
            FORGE_EXECUTOR="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --minimal)
            MINIMAL=true
            shift
            ;;
        --skip-gitignore)
            SKIP_GITIGNORE=true
            shift
            ;;
        -h|--help)
            echo "Usage: forge-init.sh [options]"
            echo ""
            echo "Options:"
            echo "  --executor <name>  Explicitly set executor (kotlin, rust, python, etc.)"
            echo "  --force            Overwrite existing configuration"
            echo "  --minimal          Create minimal config (only executor)"
            echo "  --skip-gitignore   Don't update .gitignore"
            echo "  -h, --help         Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if config exists
if [ -f "$CONFIG_FILE" ] && [ "$FORCE" != true ]; then
    log_warn "Configuration already exists at ${CONFIG_FILE}"
    log_info "Use --force to overwrite"
    exit 0
fi

# ============================================
# 1. DETECT EXECUTOR
# ============================================

detect_executor() {
    # Check for explicit executor first
    if [ -n "$FORGE_EXECUTOR" ]; then
        echo "$FORGE_EXECUTOR"
        return
    fi

    # Kotlin/JVM projects (Gradle)
    if [ -f "build.gradle.kts" ] || [ -f "settings.gradle.kts" ]; then
        echo "kotlin"
        return
    fi

    if [ -f "build.gradle" ] || [ -f "settings.gradle" ]; then
        if [ -d "src/main/kotlin" ] || find . -name "*.kt" -type f 2>/dev/null | head -1 | grep -q .; then
            echo "kotlin"
            return
        fi
    fi

    # Rust projects
    if [ -f "Cargo.toml" ]; then
        echo "rust"
        return
    fi

    # Python projects
    if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ]; then
        echo "python"
        return
    fi

    # TypeScript/JavaScript projects
    if [ -f "package.json" ]; then
        if [ -f "tsconfig.json" ] || find . -name "*.ts" -type f 2>/dev/null | head -1 | grep -q .; then
            echo "typescript"
            return
        fi
        echo "typescript"
        return
    fi

    # Go projects
    if [ -f "go.mod" ]; then
        echo "go"
        return
    fi

    # Default
    echo "default"
}

get_executor_json_value() {
    local executor="$1"
    local path="$2"
    local default="$3"
    local json_file="${EXECUTORS_DIR}/${executor}/executor.json"

    if [ -f "$json_file" ]; then
        local value=$(jq -r "$path // empty" "$json_file" 2>/dev/null)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            echo "$value"
            return
        fi
    fi
    echo "$default"
}

get_executor_display_name() {
    local executor="$1"
    get_executor_json_value "$executor" '.displayName' "$executor"
}

# Detect executor
EXECUTOR=$(detect_executor)
EXECUTOR_DISPLAY=$(get_executor_display_name "$EXECUTOR")

if [ -n "$FORGE_EXECUTOR" ]; then
    log_info "Using explicit executor: ${EXECUTOR_DISPLAY}"
else
    log_info "Detected executor: ${EXECUTOR_DISPLAY}"
fi

# ============================================
# 2. CREATE DIRECTORIES
# ============================================

log_info "Creating directory structure..."

mkdir -p "${CONFIG_DIR}/context"
mkdir -p "${CONFIG_DIR}/prd"
mkdir -p "${CONFIG_DIR}/plan"
mkdir -p "${CONFIG_DIR}/diagnosis"
mkdir -p "${CONFIG_DIR}/findings"
mkdir -p "${CONFIG_DIR}/phases"

log_success "Created directories"

# ============================================
# 3. CREATE CONFIG.YAML
# ============================================

create_full_config() {
    local executor="$1"
    local timestamp=$(date -u +%Y-%m-%d)

    # Get defaults from executor.json
    local test_cmd=$(get_executor_json_value "$executor" '.tools.test' "")
    local test_all_cmd=$(get_executor_json_value "$executor" '.tools.testAll' "")
    local test_cov_cmd=$(get_executor_json_value "$executor" '.tools.testCoverage' "")
    local lint_cmd=$(get_executor_json_value "$executor" '.tools.lint' "")
    local format_cmd=$(get_executor_json_value "$executor" '.tools.format' "")
    local build_cmd=$(get_executor_json_value "$executor" '.tools.build' "")
    local src_dir=$(get_executor_json_value "$executor" '.patterns.srcDir' "")
    local test_dir=$(get_executor_json_value "$executor" '.patterns.testDir' "")

    cat > "$CONFIG_FILE" <<EOF
# Agent Forge Configuration
# Generated by /forge-init at ${timestamp}

# Executor - overrides auto-detection
# Available: kotlin, rust, python, typescript, go, default
executor: ${executor}
EOF

    # Add tools section if we have values
    if [ -n "$test_cmd" ] || [ -n "$test_all_cmd" ] || [ -n "$lint_cmd" ] || [ -n "$format_cmd" ] || [ -n "$build_cmd" ]; then
        cat >> "$CONFIG_FILE" <<EOF

# Tool overrides (optional)
# Use this to customize commands for your project
tools:
EOF
        [ -n "$test_cmd" ] && echo "  test: \"${test_cmd}\"" >> "$CONFIG_FILE"
        [ -n "$test_all_cmd" ] && echo "  testAll: \"${test_all_cmd}\"" >> "$CONFIG_FILE"
        [ -n "$test_cov_cmd" ] && echo "  testCoverage: \"${test_cov_cmd}\"" >> "$CONFIG_FILE"
        [ -n "$lint_cmd" ] && echo "  lint: \"${lint_cmd}\"" >> "$CONFIG_FILE"
        [ -n "$format_cmd" ] && echo "  format: \"${format_cmd}\"" >> "$CONFIG_FILE"
        [ -n "$build_cmd" ] && echo "  build: \"${build_cmd}\"" >> "$CONFIG_FILE"
    fi

    # Add patterns section if we have values
    if [ -n "$src_dir" ] || [ -n "$test_dir" ]; then
        cat >> "$CONFIG_FILE" <<EOF

# Pattern overrides (optional)
# Customize source/test directory locations
patterns:
EOF
        [ -n "$src_dir" ] && echo "  srcDir: \"${src_dir}\"" >> "$CONFIG_FILE"
        [ -n "$test_dir" ] && echo "  testDir: \"${test_dir}\"" >> "$CONFIG_FILE"
    fi

    # Add defaults section
    cat >> "$CONFIG_FILE" <<EOF

# Flow defaults (optional)
defaults:
  # Bug fix: write regression test before fixing
  testFirst: true

  # Planning: maximum review iterations
  maxPlanIterations: 5
  maxPrdIterations: 5
EOF
}

create_minimal_config() {
    local executor="$1"
    cat > "$CONFIG_FILE" <<EOF
# Agent Forge Configuration
executor: ${executor}
EOF
}

log_info "Creating config.yaml..."

if [ "$MINIMAL" = true ]; then
    create_minimal_config "$EXECUTOR"
else
    create_full_config "$EXECUTOR"
fi

log_success "Created ${CONFIG_FILE}"

# ============================================
# 4. CREATE EXECUTOR CONTEXT
# ============================================

log_info "Creating executor context..."

EXECUTOR_SOURCE="detected"
[ -n "$FORGE_EXECUTOR" ] && EXECUTOR_SOURCE="config"

EXECUTOR_DESCRIPTION=$(get_executor_json_value "$EXECUTOR" '.description' "")

cat > "$CONTEXT_FILE" <<EOF
# Executor Context
# Generated by forge-init.sh
# DO NOT EDIT MANUALLY - this file is auto-generated

executor: ${EXECUTOR}
executor_source: ${EXECUTOR_SOURCE}
executor_display: ${EXECUTOR_DISPLAY}
$(if [ -n "$EXECUTOR_DESCRIPTION" ]; then echo "executor_description: ${EXECUTOR_DESCRIPTION}"; fi)
detected_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

log_success "Created ${CONTEXT_FILE}"

# ============================================
# 5. UPDATE .GITIGNORE
# ============================================

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
        log_info "Creating .gitignore..."
        printf '%s\n' "${entries[@]}" > "$gitignore"
        log_success "Created .gitignore"
        return
    fi

    # Check if already has agent-forge entries
    if grep -q "agent-forge" "$gitignore" 2>/dev/null; then
        log_info ".gitignore already has agent-forge entries"
        return
    fi

    # Append entries
    log_info "Updating .gitignore..."
    printf '\n%s\n' "${entries[@]}" >> "$gitignore"
    log_success "Updated .gitignore"
}

if [ "$SKIP_GITIGNORE" != true ]; then
    update_gitignore
fi

# ============================================
# SUMMARY
# ============================================

echo ""
log_success "==========================================="
log_success "  Agent Forge initialized successfully!"
log_success "==========================================="
echo ""
echo "  Executor:     ${EXECUTOR_DISPLAY}"
echo "  Config:       ${CONFIG_FILE}"
echo "  Context:      ${CONTEXT_FILE}"
echo ""
echo "  Directories:"
echo "    - .agent-forge/context/    (flow context packs)"
echo "    - .agent-forge/prd/        (requirements)"
echo "    - .agent-forge/plan/       (implementation plans)"
echo "    - .agent-forge/diagnosis/  (bug diagnoses)"
echo "    - .agent-forge/findings/   (analysis findings)"
echo "    - .agent-forge/phases/     (refactoring phases)"
echo ""
echo "  Next steps:"
echo "    /forge-feature <description>  - Start a new feature"
echo "    /forge-fix <description>      - Fix a bug"
echo "    /forge-analyze <description>  - Analyze codebase"
echo "    /forge-refactor <description> - Refactor code"
echo ""
