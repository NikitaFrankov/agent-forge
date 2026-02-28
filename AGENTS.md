# Agent Forge

Pluggable development pipeline for Claude Code with structured workflows
(feature, fix, analyze, refactor) and executor system for stack-specific implementations.

## Setup Commands

```bash
# Issue Tracking (beads)
bd ready                    # Show available issues
bd show <id>                # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>               # Complete work
bd sync                     # Sync with git

# Plugin Development (this project)
# No build step - just markdown, bash, and JSON configs
# Validate changes by reviewing modified files
```

## Project Structure

```
plugins/agent-forge/
├── commands/       # /forge-* workflow definitions
├── agents/         # Specialized agents (intake, investigator, etc.)
├── executors/      # Stack implementations (kotlin/, rust/, python/, ...)
├── hooks/          # Auto-detection hooks
└── scripts/        # Bash helpers
```

## Code Style

- Markdown: Use proper headings, code blocks with language hints
- Bash: Follow shellcheck recommendations, use `set -e`
- JSON: 2-space indentation, validate with `jq . < file.json`
- Naming: kebab-case for files, descriptive directory names

## Testing Instructions

- This is a plugin project with no automated tests
- Test workflows by running `/forge-*` commands in target projects
- Validate JSON configs: `jq . executors/*/executor.json`
- Check bash scripts: `shellcheck scripts/*.sh`

## Conventions

- Semantic IDs: `FEATURE-AUTH-OAUTH-001`, `FIX-CRASH-PERM-001`
- All work tracked in beads: `bd create` → `bd close` → `bd sync`
- Max iterations: PRD 5x, Plan 5x, Fix Plan 2x
- Agent files reference executor roles via `executor:implementer` pattern

## Target Project Commands

When using agent-forge in a Kotlin target project:

```bash
./gradlew test              # Run tests
./gradlew build             # Build project
./gradlew ktlintFormat      # Format code
```

## Session Completion

When ending a work session:
1. Close finished issues: `bd close <id>`
2. Sync and push:
   ```bash
   git pull --rebase
   bd sync
   git push
   ```
3. Verify: `git status` must show "up to date with origin"
