---
description: Core autonomous workflow orchestration v2.0
---

# Autonomous Workflow Skill v2.0

This skill implements the 9-phase autonomous development workflow with hierarchical task management, agent pool coordination, and build/test automation.

## Workflow Phases

The workflow progresses through 9 phases:

| Phase | Agent(s) | Parallel | Description |
|-------|----------|----------|-------------|
| 1. **Plan** | planner | No | Hierarchical task decomposition, DAG dependencies |
| 2. **Explore** | explorer (3) | Yes | Parallel codebase analysis |
| 3. **Design** | architect (3) | No | Sequential architecture approaches |
| 4. **Implement** | implementer | Partial | Parallel by dependency groups |
| 5. **Build** | builder | No | Build with auto-retry (NEW) |
| 6. **Validate** | validator (3) | Yes | Parallel code review + code quality enforcement (ENHANCED) |
| 7. **Test** | tester (2) | Yes | Unit + E2E in worktree (ENHANCED) |
| 8. **Requirements** | requirements-validator | No | Validate acceptance criteria (NEW) |
| 9. **Document** | documenter | No | Generate documentation |

## State File Location

`.claude/claude-bot.local.md`

## State Schema v2.0

```yaml
workflow_state:
  version: "2.0"
  status: "active|paused|completed|blocked"
  current_phase: "plan|explore|design|implement|build|validate|test|requirements|document|complete"
  started_at: "ISO timestamp"
  updated_at: "ISO timestamp"

goal:
  original_request: "user's original request"
  refined_requirements: []
  accepted: true

# NEW: Hierarchical tasks
tasks:
  - id: "task-1"
    parent_id: null
    status: "pending|in_progress|completed|blocked"
    assigned_agent: "agent-name"
    dependencies: ["task-2"]
    progress: 0-100
    subtasks: ["task-1-1", "task-1-2"]
    milestone: true|false
    description: "Task description"
    complexity: "low|medium|high"

# NEW: Agent tracking
agents:
  - name: "planner"
    status: "idle|working|completed"
    current_task: "task-id"
    assigned_tasks: ["task-1", "task-2"]
    capabilities: ["planning", "decomposition"]

# NEW: Dependency graph
dependencies:
  graph:
    task-1: ["task-2"]
    task-2: ["task-3"]
  parallel_ready: ["task-4", "task-5"]
  critical_path: ["task-1", "task-2", "task-5"]

# NEW: Progress tracking
progress:
  total_tasks: 10
  completed_tasks: 5
  overall_percentage: 50
  milestones_completed: 2
  total_milestones: 4

# NEW: Worktree tracking
worktrees:
  - id: "worktree-1"
    path: "/path/to/worktree"
    branch: "feature/test"
    purpose: "playwright-testing"
    status: "active|cleaning|archived"

# NEW: Build status
build:
  status: "pending|running|success|failed"
  attempts: 0
  artifacts: []
  errors: []
  retry_history: []

# NEW: Test results
testing:
  playwright:
    status: "pending|passed|failed"
    screenshots_dir: "/path"
    test_results: []
  unit_tests:
    status: "pending|passed|failed"
    results: []

# NEW: Requirements validation
requirements_validation:
  status: "pending|passed|failed"
  acceptance_criteria: []
  validation_results: []
  gaps: []

phases:
  plan:
    status: "pending|in_progress|completed|blocked"
    tasks: []
    blockers: []
  # ... (same structure for each phase)

decisions_made: []
agent_history: []
next_actions: []
```

## Starting a Workflow

To start a new workflow:

1. Check for existing state in `.claude/claude-bot.local.md`
2. If exists and active, ask to resume or stop
3. If none or completed, create new state with v2.0 schema
4. Launch coordinator agent
5. Coordinator invokes planner for hierarchical task breakdown

## Resuming a Workflow

To resume a paused/blocked workflow:

1. Load existing state
2. Check state version (migrate if v1.0)
3. Check current_phase and blockers
4. Apply any resolution provided
5. Launch coordinator to continue

## Phase Execution Rules

### Parallel Phases (Explore, Validate, Test)

Use separate Task calls in a single message:

```xml
<invoke name="Task">
<parameter name="subagent_type">general-purpose</parameter>
<parameter name="prompt">Explore focus area 1</parameter>
</invoke>
<invoke name="Task">
<parameter name="subagent_type">general-purpose</parameter>
<parameter name="prompt">Explore focus area 2</parameter>
</invoke>
```

Wait for all to complete, then consolidate results.

**For Validate phase (parallel review):**
- Validator-1: Security + Correctness focus
- Validator-2: Quality + Performance focus
- Validator-3: Code Quality Enforcement focus (no mocks/placeholders, naming consistency, latest standards via web search)

**For Test phase (parallel unit + E2E):**
- Tester-1: Unit tests in main repository
- Tester-2: E2E tests with Playwright in worktree

### Sequential Phases (Design, Requirements)

Launch one agent, wait for result, launch next:

```xml
<invoke name="Task">
<parameter name="subagent_type">general-purpose</parameter>
<parameter name="prompt">Design approach 1</parameter>
</invoke>
```

After result, launch approach 2 (can see approach 1's work).

### Linear Phases (Plan, Implement, Build, Document)

Launch single agent, wait for completion.

### Dependency-Based Parallel Execution (Implement phase)

1. Build dependency graph from tasks
2. Find tasks with no pending dependencies (parallel_ready)
3. Launch agents for all parallel-ready tasks
4. When task completes, check if new tasks become ready
5. Repeat until all implementation tasks complete

## Build Phase (Phase 5)

**Builder agent workflow:**

1. Detect project type (package.json, Cargo.toml, etc.)
2. Run appropriate build command
3. Monitor for errors
4. On failure:
   - Check error type against config/build.yaml
   - Apply auto-fix if pattern matches
   - Retry (max 3 attempts by default)
5. On success:
   - Capture build artifacts
   - Update state with build results

**Build hooks:**
- `PreBuild`: Clean artifacts, verify dependencies
- `PostBuild`: Verify artifacts, trigger validation

## Test Phase (Phase 7)

**Tester agent workflow:**

1. **Unit Tests (Tester-1):**
   - Run in main repository
   - Run tests, linter, type checker
   - Report results

2. **E2E Tests (Tester-2):**
   - Create worktree: `${CLAUDE_PLUGIN_ROOT}/scripts/worktree-manager.sh create test-playwright`
   - Start dev server: `${CLAUDE_PLUGIN_ROOT}/scripts/server-control.sh start`
   - Run Playwright tests
   - Capture screenshots on failure
   - Stop server and clean worktree

**Test hooks:**
- `PreTest`: Create worktree, start dev server
- `PostTest`: Stop server, clean/archive worktree

## Requirements Phase (Phase 8)

**Requirements validator workflow:**

1. Parse original requirements from goal
2. Generate acceptance criteria (Given/When/Then)
3. Validate implementation against criteria
4. Document gaps with severity
5. Create test cases for gaps

## Code Quality Enforcement (Validator-3)

**Code Quality Enforcer workflow:**

1. **Mock/Placeholder Detection:**
   - Search for mock, stub, placeholder, fake, dummy patterns
   - Search for TODO/FIXME in production code
   - Flag any "not implemented" errors
   - All mocks/placeholders = CRITICAL BLOCKER

2. **Web Search for Latest Standards:**
   - Search for "[technology] best practices [current year]"
   - Verify against top coding standards
   - Check for deprecated APIs
   - Document outdated patterns

3. **Naming Consistency:**
   - Verify file naming matches language conventions
   - Check function/variable naming consistency
   - Validate API names match framework standards

4. **API Consistency:**
   - Framework-specific pattern validation
   - Standard library usage verification
   - Error handling convention checks

**Technology-specific naming standards:**
- TypeScript/JavaScript: kebab-case files, camelCase functions, PascalCase types
- Python: snake_case files/functions, PascalCase classes
- Go: snake_case files, PascalCase exports, lowercase packages
- Rust: snake_case files/functions, PascalCase types

## Blocker Handling

When an agent detects a blocker:

1. Save state with blocker info
2. Update workflow_state.status = "blocked"
3. Update phase status = "blocked"
4. Mark affected task(s) as blocked
5. Present blocker to user
6. Wait for /bot-resume with resolution

## State Persistence

Save state after:
- Each phase completion
- Each agent completion
- Each task completion
- Blocker detection
- Build completion (success or failure)
- Test completion
- Progress updates

Load state when:
- /bot-resume is called
- Session starts (via SessionStart hook)

## Agent History Format

```yaml
agent_history:
  - agent: "planner"
    phase: "plan"
    task_id: "task-1"
    started_at: "ISO timestamp"
    completed_at: "ISO timestamp"
    status: "completed"
    summary: "Brief result summary"
```

## Agent Pool Management

**Agent capabilities:**
- planner: planning, decomposition, dependency_analysis
- explorer: code_analysis, pattern_detection, file_search
- architect: design, architecture, trade_off_analysis
- implementer: coding, file_creation, modification
- builder: build, compilation, dependency_management
- validator: code_review, security, quality, code_quality_enforcement
- code_quality_enforcer: mock_detection, web_search, naming_consistency, api_consistency
- tester: testing, playwright, unit_tests
- requirements_validator: requirements, acceptance_criteria
- documenter: documentation, examples, guides

**Workload balancing:**
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/agent-registry.sh workload  # Show utilization
${CLAUDE_PLUGIN_ROOT}/scripts/agent-registry.sh balance    # Redistribute tasks
```

## Task Hierarchy

**Task ID format:**
- Milestone tasks: `task-1`, `task-2`, etc.
- Subtasks: `task-1-1`, `task-1-2`, etc.
- Atomic tasks: `task-1-1-1`, `task-1-1-2`, etc.

**Task operations:**
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh create "description" "parent_id" "complexity" "agent"
${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh complete "task_id"
${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh progress "task_id" "percentage"
${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh assign "task_id" "agent"
```

## Dependency Resolution

**Build DAG:**
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/dependency-resolver.sh build-graph
${CLAUDE_PLUGIN_ROOT}/scripts/dependency-resolver.sh find-ready
${CLAUDE_PLUGIN_ROOT}/scripts/dependency-resolver.sh critical-path
```

## Progress Calculation

**Progress metrics:**
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh calculate
${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh milestones
${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh estimate
```

## Completion

Workflow is complete when:
- All 9 phases are completed
- All milestone tasks are completed
- No blockers remain
- No mocks or placeholders in production code
- Build succeeded
- Tests passed (or failures acknowledged)
- Requirements validated (or gaps documented)
- Code follows naming conventions
- Latest standards verified via web search
- Documentation is generated

Set:
- workflow_state.status = "completed"
- current_phase = "complete"
- progress.overall_percentage = 100

Present summary to user with:
- Final task hierarchy
- Test results
- Requirements validation status
- Build artifacts location
- Documentation location
