# Agent Forge

**Pluggable development pipeline with executor system** - skeleton + stack-specific executors.

## Overview

Agent Forge is a Claude Code plugin that provides a complete development pipeline with a pluggable executor system. The skeleton handles the universal workflow (ideation → planning → implementation → review), while executors provide stack-specific guidance (Kotlin, Python, Rust, etc.).

## How It Works

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          /forge-run AUTH-123                                │
└───────────────────────────────────┬────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  STAGE 1: IDEATION (универсальный)                                         │
│                                                                            │
│  1. ideation agent → интервью через AskUserQuestion (8+ раундов)          │
│  2. researcher agent → исследование codebase (если есть AIDD hints)        │
│  3. prd-reviewer → валидация PRD                                           │
│                                                                            │
│  Результат: .agent-forge/prd/AUTH-123.prd.md (Status: READY)              │
└───────────────────────────────────┬────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  STAGE 2: PLANNING (универсальный)                                         │
│                                                                            │
│  1. planner agent → декомпозиция PRD на итерации и задачи                 │
│  2. plan-reviewer → валидация плана                                        │
│                                                                            │
│  Результат: .agent-forge/plan/AUTH-123.md (Status: READY)                 │
└───────────────────────────────────┬────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  STAGE 3: EXECUTOR SELECTION                                               │
│                                                                            │
│  Приоритет:                                                                │
│  a) --executor kotlin (флаг)                                               │
│  b) .agent-forge/config.yaml → executor: kotlin                           │
│  c) Автоопределение: build.gradle.kts → kotlin                            │
│                                                                            │
│  Скрипт: core/scripts/detect-executor.sh                                   │
└───────────────────────────────────┬────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  STAGE 4: PROMPT GENERATION (инъекция executor контекста)                  │
│                                                                            │
│  Скрипт: core/scripts/generate-prompt.sh AUTH-123 kotlin                   │
│                                                                            │
│  Загружает:                                                                │
│  ┌─────────────────────────────────────────────────────────────────┐      │
│  │ executors/kotlin/executor.json → команды (test, lint, build)    │      │
│  │ executors/kotlin/generator.md  → паттерны кода                  │      │
│  │ executors/kotlin/debugger.md   → стратегия отладки              │      │
│  └─────────────────────────────────────────────────────────────────┘      │
│                          │                                                 │
│                          ▼                                                 │
│  Генерирует: .agent-forge/PROMPT.md                                        │
│  (содержит инструкции + kotlin-специфичные паттерны)                       │
└───────────────────────────────────┬────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│  STAGE 5: IMPLEMENTATION LOOP (Ralph Wiggum)                               │
│                                                                            │
│  FOR iteration = 1 TO 50:                                                  │
│                                                                            │
│    ┌──────────────────────────────────────────────────────────────────┐   │
│    │ implementer agent (читает PROMPT.md с kotlin паттернами)         │   │
│    │   → Читает Codebase Patterns                                     │   │
│    │   → Реализует одну задачу по kotlin паттернам                    │   │
│    │   → Запускает: ./gradlew test --tests "..."                      │   │
│    │   → Запускает: ./gradlew detekt                                  │   │
│    │   → Отчитывается о завершении (НЕ коммитит!)                     │   │
│    └──────────────────────────────────────────────────────────────────┘   │
│                              │                                             │
│                              ▼                                             │
│    ┌──────────────────────────────────────────────────────────────────┐   │
│    │ code-reviewer agent                                              │   │
│    │   → Читает реальный код (не отчёт!)                              │   │
│    │   → Проверяет по kotlin/reviewer.md чеклисту                     │   │
│    │   → APPROVED или ISSUES_FOUND                                    │   │
│    └──────────────────────────────────────────────────────────────────┘   │
│                              │                                             │
│                              ▼                                             │
│    If APPROVED:                                                            │
│      → git commit                                                          │
│      → Mark task Status: passing                                           │
│      → Update activity log                                                 │
│                                                                            │
│    If ISSUES_FOUND:                                                        │
│      → implementer исправляет                                              │
│      → re-review                                                           │
│                                                                            │
│    If ALL tasks passing:                                                   │
│      → Output: <promise>COMPLETE</promise>                                 │
│      → Exit loop                                                           │
│                                                                            │
│  NEXT iteration                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  PIPELINE SKELETON                          │
│                                                             │
│  /forge-run <ticket>                                        │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────┐   ┌─────────┐   ┌──────────┐   ┌────────────┐ │
│  │ IDEATION│──►│ PLANNING│──►│IMPLEMENT │──►│  REVIEW    │ │
│  └────┬────┘   └────┬────┘   └────┬─────┘   └─────┬──────┘ │
└───────┼─────────────┼─────────────┼────────────────┼────────┘
        │             │             │                │
        ▼             ▼             ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                    EXECUTOR PLUGINS                         │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ kotlin-exec │  │ python-exec │  │ rust-exec   │  ...     │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## Installation

### Option 1: Claude Code CLI

```bash
claude mcp add --transport stdio agent-forge -- /path/to/agent-forge
```

### Option 2: Manual Configuration

Add to `~/.claude.json` or project's `.claude.json`:

```json
{
  "mcpServers": {
    "agent-forge": {
      "command": "claude",
      "args": ["--plugin-dir", "/path/to/agent-forge"]
    }
  }
}
```

## Quick Start

### 1. Initialize Workspace

```bash
cd /your/project
bash /path/to/agent-forge/core/scripts/init.sh
```

This creates `.agent-forge/` directory with:
```
.agent-forge/
├── context/      # Context Packs
├── ideas/        # Interview notes
├── prd/          # Product Requirements
├── research/     # Research findings
├── plan/         # Implementation plans
├── activity/     # Progress logs
├── screenshots/  # UI screenshots
├── archive/      # Previous runs
└── config.yaml   # Configuration
```

### 2. Run Full Pipeline

```bash
# Auto-detect executor from project
/forge-run AUTH-123-add-oauth

# Explicit executor
/forge-run AUTH-123 --executor kotlin
```

### 3. Or Run Stages Separately

```bash
/forge-idea AUTH-123    # Collect requirements → PRD
/forge-plan AUTH-123    # Create plan from PRD
/forge-exec AUTH-123    # Implement plan
```

## Commands

| Command | Description |
|---------|-------------|
| `/forge-run <ticket>` | Full pipeline: idea → implementation |
| `/forge-idea <ticket>` | Requirements collection → PRD |
| `/forge-plan <ticket>` | Implementation planning |
| `/forge-exec <ticket>` | Ralph Wiggum implementation loop |

## Agents

### Core Agents (Skeleton)

| Agent | Role | When Used |
|-------|------|-----------|
| **ideation** | Gather requirements | `/forge-idea` first stage |
| **analyst** | Deep interviews | During ideation |
| **researcher** | Investigate codebase | When AIDD:RESEARCH_HINTS exist |
| **planner** | Create implementation plans | `/forge-plan` |
| **plan-reviewer** | Validate plans | After planning |
| **implementer** | Write code | `/forge-exec` iterations |
| **code-reviewer** | Review code | After each implementation |

### Key Principles

1. **Separation of Concerns** - Implementer never reviews own code
2. **Two-Stage Review** - Spec compliance + Code quality
3. **Ralph Wiggum Loop** - Fresh context per iteration
4. **50 Retry Strategy** - For persistent errors

## Executors

### Available Executors

| Executor | Language | Status |
|----------|----------|--------|
| **kotlin** | Kotlin/JVM | ✅ Ready |
| python | Python | 📋 Planned |
| rust | Rust | 📋 Planned |
| typescript | TypeScript | 📋 Planned |

### Executor Selection Priority

1. Explicit `--executor <name>` flag
2. `.agent-forge/config.yaml` setting
3. Auto-detection from project files:
   - `build.gradle.kts` → kotlin
   - `pyproject.toml` → python
   - `Cargo.toml` → rust
   - `package.json` → typescript

### Creating a New Executor

```
executors/<name>/
├── executor.json    # Metadata, tools, patterns
├── generator.md     # Code generation guidance
├── debugger.md      # Debugging strategies
├── tester.md        # Testing guidance
└── reviewer.md      # Code review checklist
```

## Artifacts

### PRD Format (`.agent-forge/prd/<ticket>.prd.md`)

```markdown
# PRD: <ticket>

## Metadata
## Overview
## Goals
### AIDD:ACCEPTANCE
### AIDD:OPEN_QUESTIONS
### AIDD:ANSWERS
### AIDD:RESEARCH_HINTS
## Constraints
## Dependencies
## Success Metrics
## PRD Review
```

### Plan Format (`.agent-forge/plan/<ticket>.md`)

```markdown
# Implementation Plan: <ticket>

## Metadata
## Overview
## Iterations
### Iteration N: <Title>
**Tasks:**
1. **[TASK-ID]** Description
   - **File:** path/to/file.kt
   - **Acceptance:** criteria
   - **Tests:** requirements
   - **Status:** pending|passing
## Test Strategy
## Risks & Mitigations
## Plan Review
```

## Executor-Specific Commands

### Kotlin

```bash
# Test
./gradlew test --tests "com.example.TestClass"

# Lint
./gradlew detekt

# Format
./gradlew ktlintFormat

# Build
./gradlew build
```

## Hooks

Currently, hooks are not configured. Future hooks may include:

| Event | Purpose |
|-------|---------|
| `PreToolUse` | Format check before Write/Edit |
| `PostToolUse` | Fast tests after code changes |
| `SubagentStop` | Log progress after agent completion |

## Configuration

### `.agent-forge/config.yaml`

```yaml
# Executor selection (optional - auto-detected if not set)
executor: kotlin

# Branch naming
branch_prefix: feature/
```

## License

MIT

## Author

NikitaFrankov
