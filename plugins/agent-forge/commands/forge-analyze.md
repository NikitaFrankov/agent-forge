---
name: forge-analyze
description: Conduct deep codebase analysis with structured report generation. Use for security audits, performance analysis, architecture reviews, and technical debt assessment.
user_invocable: true
---

# /forge-analyze - Analysis Pipeline

Conduct deep codebase analysis with structured report generation and follow-up recommendations.

## Usage

```
/forge-analyze <описание анализа>
```

**Никаких флагов** - тип анализа определяется автоматически из описания.

## Examples

```
/forge-analyze проверить безопасность модуля авторизации
/forge-analyze проанализировать производительность API endpoints
/forge-analyze найти технический долг в модуле платежей
/forge-analyze проверить зависимости на уязвимости
/forge-analyze оценить архитектуру микросервисов
```

## Auto-Detected Analysis Types

Coordinator determines analysis type from description keywords:

| Keywords (RU/EN) | Analysis Type | Focus |
|------------------|---------------|-------|
| безопасность, уязвимост*, security, vulnerab*, auth | **security** | Vulnerabilities, compliance |
| производительност*, медленн*, performance, slow*, bottleneck | **performance** | Bottlenecks, optimization |
| архитектур*, architect*, структура, structure, component | **architecture** | Design, modularity |
| долг*, качеств*, debt, quality, smell, refactor* | **code-quality** | Technical debt, maintainability |
| зависимост*, dependency*, библиотек*, library, package | **dependency** | Health, licenses, updates |
| (default) | **general** | General codebase review |

## Pipeline Stages

### Stage 1: Intake
1. Parse command and description
2. Generate semantic ID (e.g., ANALYZE-SEC-AUTH-001)
3. Detect analysis type from keywords
4. Create analysis issue in beads
5. Initialize findings KV store

### Stage 2: Deep Research
1. Launch analysis-researcher agent
2. Targeted investigation based on analysis type
3. Use Glob/Grep/Read to examine code
4. Document findings in beads KV
5. Create graph links to code areas
6. Apply severity labels

### Stage 3: Synthesis
1. Launch analysis-synthesizer agent
2. Aggregate all findings
3. Identify patterns and relationships
4. Prioritize by severity and impact
5. Cross-reference with existing issues

### Stage 4: Report Generation
1. Launch analysis-reporter agent
2. Generate structured report
3. Create executive summary
4. Document all findings with evidence
5. Create digest in beads

### Stage 5: Follow-up (Optional)
1. User can request follow-up issues
2. Create REMEDIATE issues for actionable findings
3. Link to analysis (discovered-from)
4. Set priorities based on severity

## Flow Diagram

```
/forge-analyze проверить безопасность модуля авторизации
        │
        ▼
┌───────────────────┐
│  INTAKE           │ Generate ID: ANALYZE-SEC-AUTH-001
│  intake agent     │ Detect type: security
└─────────┬─────────┘
          │
          ▼
┌───────────────────────────────────────────────────┐
│  DEEP RESEARCH                                    │
│                                                   │
│  analysis-researcher agent:                       │
│  - Glob/Grep/Read target files                    │
│  - Find patterns, issues, risks                   │
│  - Store findings in beads KV                     │
│  - Create graph links to code areas               │
└───────────────────────┬───────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  ANALYSIS SYNTHESIS           │
        │  analysis-synthesizer agent:  │
        │  - Aggregate findings         │
        │  - Identify patterns          │
        │  - Prioritize recommendations │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  REPORT GENERATION            │
        │  analysis-reporter agent:     │
        │  - Generate structured report │
        │  - Create digest in beads     │
        │  - Executive summary          │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  FOLLOW-UP (optional)         │
        │  - Create REMEDIATE issues    │
        │  - Link to analysis           │
        │  - Set priorities             │
        └───────────────────────────────┘
```

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

## Report Structure

The generated report includes:

```markdown
# Analysis Report: <ID>

## Metadata
- Analysis ID: ANALYZE-<SEMANTIC>-001
- Type: <security|performance|architecture|code-quality|dependency>
- Created: <timestamp>
- Completed: <timestamp>

## Executive Summary
<1-2 paragraphs summarizing key findings>

## Scope
<What was analyzed>

## Key Findings Summary
| ID | Severity | Title | Location |
|----|----------|-------|----------|
| FINDING-001 | Critical | <title> | file:line |
| FINDING-002 | High | <title> | file:line |

## Detailed Findings
### FINDING-001: <Title>
**Severity:** Critical
**Location:** `path/to/file:line`

**Description:**
<Detailed description>

**Evidence:**
```kotlin
// Code snippet showing the issue
```

**Recommendation:**
<How to address this finding>

## Recommendations (Prioritized)
1. <Recommendation 1> (Critical)
2. <Recommendation 2> (High)
...

## Follow-up Actions
- [ ] REMEDIATE-...-001: <Action>
- [ ] REMEDIATE-...-002: <Action>

## Metrics
| Metric | Value |
|--------|-------|
| Files Analyzed | X |
| Total Findings | Y |
| Critical | A |
| High | B |
| Medium | C |
```

## Output

At completion, the output includes:
- **Analysis ID** - The generated semantic ID
- **Analysis Type** - Detected type
- **Summary** - Key findings overview
- **Report Path** - Path to full report
- **Findings Count** - By severity
- **Follow-up Issues** - Created remediate issues (if requested)
- **Beads Reference** - Link to analysis issue

## Resume Support

If interrupted, the flow can be resumed:
```
/forge-analyze resume ANALYZE-SEC-AUTH-001
```

The system reads current state from beads and continues from the last checkpoint.

## Output Modes

### Interactive Mode (default)
- Progress updates during analysis
- Summary displayed at completion
- Prompt to create follow-up issues

### Silent Mode (for automation)
- All output goes to beads
- Report generated automatically
- No interactive prompts
