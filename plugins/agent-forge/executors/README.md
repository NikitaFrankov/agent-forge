# Executors

Executors provide stack-specific implementations for workflow agents. Each executor defines the tools, patterns, and conventions for a specific technology stack.

## Available Executors

| Executor | Language | Build System | Status |
|----------|----------|--------------|--------|
| kotlin | Kotlin/JVM | Gradle | ✅ Implemented |
| rust | Rust | Cargo | 📋 Planned |
| python | Python | pip/poetry | 📋 Planned |
| typescript | TypeScript | npm/yarn | 📋 Planned |
| go | Go | go mod | 📋 Planned |
| default | Generic | - | ✅ Fallback |

## Executor Structure

```
executors/<name>/
├── executor.json      # Executor definition
├── implementer.md     # Code implementation agent
├── reviewer.md        # Code review agent
├── tester.md          # Test writing agent
└── debugger.md        # Debugging agent
```

## executor.json Schema

```json
{
  "name": "kotlin",
  "displayName": "Kotlin/JVM",
  "description": "Description of the executor",
  "detection": {
    "files": ["build.gradle.kts"],
    "extensions": [".kt", ".kts"],
    "directories": ["src/main/kotlin"]
  },
  "tools": {
    "test": "./gradlew test --tests \"{test}\"",
    "testAll": "./gradlew test",
    "build": "./gradlew build",
    "lint": "./gradlew detekt",
    "format": "./gradlew ktlintFormat"
  },
  "patterns": {
    "srcDir": "src/main/kotlin",
    "testDir": "src/test/kotlin"
  },
  "agents": {
    "implementer": "executors/kotlin/implementer.md",
    "reviewer": "executors/kotlin/reviewer.md",
    "tester": "executors/kotlin/tester.md",
    "debugger": "executors/kotlin/debugger.md"
  }
}
```

## How Executors Work

### Resolution Flow

```
Command: executor:implementer
              ↓
Read: .agent-forge/executor.context
              ↓
executor: kotlin
              ↓
Read: executors/kotlin/executor.json
              ↓
agents.implementer → executors/kotlin/implementer.md
              ↓
Execute stack-specific agent
```

### Auto-Detection

The `hooks/resolve-executor.sh` script automatically detects the project stack:

1. Check `.agent-forge/config.yaml` for explicit `executor:` setting
2. Scan project files:
   - `build.gradle.kts` → kotlin
   - `Cargo.toml` → rust
   - `pyproject.toml` → python
   - `package.json` + `tsconfig.json` → typescript
   - `go.mod` → go
3. Fallback to `default`

### Context File

After detection, context is written to `.agent-forge/executor.context`:

```
executor: kotlin
executor_source: detected
executor_display: Kotlin/JVM
detected_at: 2025-01-15T10:30:00Z
```

## Adding a New Executor

### 1. Create Directory Structure

```bash
mkdir -p executors/<name>
```

### 2. Create executor.json

Define the executor with detection rules, tools, and patterns:

```json
{
  "name": "rust",
  "displayName": "Rust",
  "description": "Executor for Rust projects with Cargo",
  "detection": {
    "files": ["Cargo.toml"],
    "extensions": [".rs"]
  },
  "tools": {
    "test": "cargo test {test}",
    "testAll": "cargo test",
    "build": "cargo build",
    "lint": "cargo clippy",
    "format": "cargo fmt"
  },
  "patterns": {
    "srcDir": "src",
    "testDir": "tests"
  },
  "agents": {
    "implementer": "executors/rust/implementer.md",
    "reviewer": "executors/rust/reviewer.md",
    "tester": "executors/rust/tester.md",
    "debugger": "executors/rust/debugger.md"
  }
}
```

### 3. Create Agent Files

Each agent should:
- Extend `base-implementer`, `base-reviewer`, or `base-tester`
- Include stack-specific patterns and idioms
- Define appropriate tools and commands

### 4. Update Detection Script

Add detection logic to `hooks/resolve-executor.sh`:

```bash
if [ -f "Cargo.toml" ]; then
    write_executor_context "rust" "detected"
    exit 0
fi
```

## Using Executors in Commands

Reference agents by role in workflow commands:

```markdown
### Stage 4: Implementation
1. Launch executor:implementer agent
2. Run tests (via executor tools)
3. Launch executor:reviewer agent
4. If APPROVED: commit
```

## Overriding Executor Detection

Create `.agent-forge/config.yaml`:

```yaml
executor: kotlin

# Optional: Override specific tools
tools:
  test: "./gradlew test --parallel"
```
