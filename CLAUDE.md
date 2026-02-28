# Agent Forge

Pluggable development pipeline for Claude Code. Structured workflows (feature, fix, analyze, refactor) with executor system for stack-specific implementations.

## Architecture

```
plugins/agent-forge/
├── commands/       # /forge-* workflow definitions
├── agents/         # Specialized agents (intake, investigator, base/*)
├── executors/      # Stack implementations (kotlin/, rust/, python/, ...)
├── hooks/          # resolve-executor.sh for auto-detection
└── scripts/        # beads-helpers.sh
```

Flow: Command → intake agent → beads structure → executor:implementer → executor:reviewer

## Development Commands

```bash
./gradlew test              # Run tests
./gradlew ktlintFormat      # Format code
./gradlew build             # Build

bd ready                    # Show available issues
bd create -t task           # Create issue
bd close <id>               # Complete work
bd sync                     # Sync beads with git
```

## Adding New Flows

**Workflow:**
1. Create `commands/forge-<name>.md` with pipeline stages
2. Create `agents/<name>-*.md` if specialized behavior needed
3. Update `plugin.json` features.workflows

**Executor:**
1. Create `executors/<name>/` with `executor.json` + `{implementer,reviewer,tester,debugger}.md`
2. Add detection to `hooks/resolve-executor.sh`
3. Update `plugin.json` features.executors

## Conventions

- Semantic IDs: `FEATURE-AUTH-OAUTH-001`, `FIX-CRASH-PERM-001`
- executor:role resolves via `.agent-forge/executor.context`
- Ralph Wiggum loop: task → implementer → reviewer → commit
- Max iterations: PRD 5x, Plan 5x, Fix Plan 2x
- Always: `bd create` → `bd close` → `bd sync`

## References

@plugins/agent-forge/scripts/beads-helpers.sh - beads utilities
@plugins/agent-forge/executors/kotlin/executor.json - example executor config
