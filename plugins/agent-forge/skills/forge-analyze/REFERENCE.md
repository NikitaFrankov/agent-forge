# Forge Analyze - Reference Documentation

This document provides extended documentation for the forge-analyze skill.

## Beads Structure

```yaml
ANALYZE-SEC-AUTH-001                # Analysis issue (type=analysis)
├── analysis-...-findings           # KV: All findings with evidence
│   ├── finding-001:
│   │   ├── severity: critical
│   │   ├── title: "<finding title>"
│   │   ├── location: "file:line"
│   │   ├── description: "<details>"
│   │   ├── evidence: "<code snippet>"
│   │   └── recommendation: "<how to fix>"
│   ├── finding-002: ...
│   └── metrics:
│       ├── files_analyzed: X
│       └── findings_count: Y
├── graph-links                     # relates_to: discovered modules
├── analysis-...-report             # Digest: Final report
└── REMEDIATE-...-001               # Follow-up issue (optional)
```

## Stage Details

### Stage 1: Intake

**Purpose:** Parse command and initialize tracking.

**Steps:**
1. Parse analysis description from user input
2. Generate semantic ID using pattern: `ANALYZE-{TYPE}-{KEYWORDS}-{NUMBER}`
   - Extract analysis type from keywords
   - Extract 2-3 key words from description
   - Examples: `ANALYZE-SEC-AUTH-001`, `ANALYZE-PERF-DB-001`
3. Detect analysis type from keywords
4. Create analysis issue in beads:
   ```bash
   bd create --type analysis --title "Analysis: {description}" --id "bd-{id}"
   ```
5. Initialize findings KV store
6. Set labels: `forge:analyze`, `forge:pending_research`

**Output:** Analysis ID and beads issue created

**Intake Agent Tasks:**
- Parse natural language command
- Detect analysis type
- Generate semantic ID
- Create beads structure
- Create context pack

### Stage 2: Deep Research

**Purpose:** Conduct targeted codebase investigation.

**Analysis Researcher Agent Tasks:**
1. Receive analysis type and scope from intake
2. Select appropriate investigation strategy:
   - **security**: Look for auth patterns, input validation, secrets
   - **performance**: Profile hot paths, resource usage, bottlenecks
   - **architecture**: Module boundaries, dependencies, cohesion
   - **code-quality**: Code smells, complexity, test coverage
   - **dependency**: Outdated packages, license issues, vulnerabilities
3. Use Glob/Grep/Read to examine code
4. Document each finding with:
   - Severity (critical/high/medium/low)
   - Location (file:line)
   - Description
   - Evidence (code snippet)
   - Recommendation
5. Store findings in beads KV
6. Create graph links to discovered code areas

**Finding Format:**
```yaml
finding-001:
  id: FINDING-001
  severity: critical
  title: "SQL Injection in UserQuery"
  location: "src/main/kotlin/UserService.kt:42"
  description: "User input is directly concatenated into SQL query"
  evidence: |
    val query = "SELECT * FROM users WHERE name = '${name}'"
  recommendation: "Use parameterized queries with PreparedStatement"
  cwe: CWE-89
  owasp: A03:2021
```

**State Transition:** `forge:pending_research` → `forge:research_complete`

### Stage 3: Synthesis

**Purpose:** Aggregate findings and identify patterns.

**Analysis Synthesizer Agent Tasks:**
1. Read all findings from KV store
2. Group findings by:
   - Component/module
   - Root cause
   - Pattern type
3. Identify relationships between findings
4. Calculate aggregate metrics
5. Prioritize recommendations
6. Cross-reference with existing issues

**Synthesis Output:**
```yaml
synthesis:
  total_findings: 12
  by_severity:
    critical: 2
    high: 4
    medium: 5
    low: 1
  by_component:
    auth-module: 5
    data-layer: 4
    api-handlers: 3
  patterns:
    - pattern: "Missing input validation"
      occurrences: 6
      files: [UserService.kt, OrderService.kt, ...]
    - pattern: "Hardcoded credentials"
      occurrences: 2
      files: [Config.kt, TestUtils.kt]
  priority_order:
    - finding-001
    - finding-003
    - finding-007
    - ...
```

**State Transition:** `forge:research_complete` → `forge:synthesis_complete`

### Stage 4: Report Generation

**Purpose:** Create structured analysis report.

**Analysis Reporter Agent Tasks:**
1. Read synthesis results
2. Generate executive summary (1-2 paragraphs)
3. Format detailed findings
4. Create prioritized recommendations
5. Generate follow-up actions
6. Create digest in beads

**Report Location:**
```
.agent-forge/findings/ANALYZE-XXX-XXX-001-report.md
```

**State Transition:** `forge:synthesis_complete` → `forge:complete`

### Stage 5: Follow-up (Optional)

**Purpose:** Create actionable remediation issues.

**Steps:**
1. User requests follow-up issues
2. For high/critical findings, create REMEDIATE issues:
   ```bash
   bd create --type task --title "Remediate: {finding title}" --parent "bd-{analysis-id}"
   ```
3. Link to original analysis
4. Set priority based on severity

**Follow-up Format:**
```yaml
REMEDIATE-SEC-SQL-001:
  parent: ANALYZE-SEC-AUTH-001
  priority: P1
  finding: FINDING-001
  title: "Fix SQL Injection in UserQuery"
  description: "Implement parameterized queries"
```

## Agent Orchestration

| Stage | Agent | Purpose |
|-------|-------|---------|
| Intake | `agent-forge:intake` | Parse command, detect type, create structure |
| Research | `agent-forge:analysis-researcher` | Deep code investigation |
| Synthesis | `agent-forge:analysis-synthesizer` | Aggregate findings, identify patterns |
| Report | `agent-forge:analysis-reporter` | Generate structured report |
| Follow-up | `agent-forge:analysis-reporter` | Create remediation issues |

## Analysis Type Detection Rules

### Security Analysis

**Keywords:** безопасность, уязвимост*, security, vulnerab*, auth, защит*, protect, OWASP, injection, XSS, CSRF

**Focus Areas:**
- Authentication and authorization
- Input validation and sanitization
- Secrets management
- SQL/NoSQL injection
- XSS and CSRF vulnerabilities
- insecure configurations
- Cryptographic weaknesses

### Performance Analysis

**Keywords:** производительност*, медленн*, performance, slow*, bottleneck, оптимиз*, optim, latency, throughput

**Focus Areas:**
- Hot paths and bottlenecks
- Resource usage (CPU, memory, I/O)
- Database query efficiency
- Caching opportunities
- Async/await patterns
- Connection pooling

### Architecture Analysis

**Keywords:** архитектур*, architect*, структура, structure, component, module, модул*, design pattern, dependency

**Focus Areas:**
- Module boundaries and cohesion
- Dependency graph
- Layer separation
- API design
- Scalability concerns
- Technical architecture debt

### Code Quality Analysis

**Keywords:** долг*, качеств*, debt, quality, smell, refactor*, maintainability, complexity, coverage

**Focus Areas:**
- Code smells
- Complexity metrics
- Test coverage
- Documentation status
- Naming conventions
- DRY violations

### Dependency Analysis

**Keywords:** зависимост*, dependency*, библиотек*, library, package, пакет*, version, outdated, license

**Focus Areas:**
- Outdated dependencies
- Security vulnerabilities in dependencies
- License compliance
- Dependency conflicts
- Unused dependencies

## Severity Classification

| Severity | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Immediate security risk, data loss potential, system instability | SQL injection, auth bypass, data corruption |
| **High** | Significant security risk, major performance impact, architectural violation | XSS, missing auth check, N+1 queries |
| **Medium** | Moderate risk, code quality issues, minor performance impact | Missing rate limiting, code duplication |
| **Low** | Best practice violations, minor improvements | Missing documentation, naming issues |

## Executor System

### Executor Selection

**Priority order:**
1. `.agent-forge/config.yaml` - Explicit `executor: <name>`
2. Auto-detection from project files

### Context File

After resolution, executor context is written to `.agent-forge/executor.context`:
```
executor: kotlin
executor_source: detected
```

### Usage in Analysis

Stack-specific executors may be used for:
- `executor:reviewer` - If creating remediation follow-ups
- `executor:tester` - For verification of fixes

## Comparison with Other Flows

| Aspect | Feature | Bug Fix | Analysis | Refactor |
|--------|---------|---------|----------|----------|
| Planning iterations | 5 max | 2 max | N/A | 3 max |
| Interview required | Yes | No | No | No |
| Research phase | Optional | Included | Primary | Optional |
| Test strategy | Planned | Regression | N/A | Baseline |
| Iterations | Multiple | Single | N/A | Phases |
| Risk level | Medium | Low | Low | High |
| Output | Feature | Fix commit | Report | Refactored code |

## Resume Support

If interrupted, the flow can be resumed:

```
/forge-analyze resume ANALYZE-SEC-AUTH-001
```

Resume process:
1. Read current state from beads
2. Identify last completed stage
3. Continue from that point
4. Preserve all progress

State is tracked in:
- Beads issue labels (`forge:*`)
- KV store (`analysis/{id}/status`)
- Context pack (`.agent-forge/context/{id}.pack.md`)

## Best Practices

1. **Be specific in description** - Better keywords lead to better analysis type detection
2. **Review findings incrementally** - Don't wait for full report to start addressing issues
3. **Prioritize critical findings** - Address critical/high severity first
4. **Create follow-up issues** - Convert findings into actionable tasks
5. **Re-run after fixes** - Verify issues are resolved

## Common Anti-Patterns

1. **Vague analysis scope** - Too broad description leads to unfocused analysis
2. **Ignoring severity** - Treating all findings equally
3. **No follow-up** - Analysis without action is waste
4. **One-time analysis** - Should be repeated periodically
5. **Siloed findings** - Share findings with team

## Metrics Tracked

| Metric | Description |
|--------|-------------|
| `files_analyzed` | Number of files examined |
| `findings_count` | Total findings |
| `findings_by_severity` | Count per severity level |
| `findings_by_component` | Count per component |
| `patterns_identified` | Number of patterns found |
| `duration_ms` | Analysis duration |
