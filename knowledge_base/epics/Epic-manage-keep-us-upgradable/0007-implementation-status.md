### Epic: Manage & Keep Us Upgradable — Implementation Status (Execution Log)

**Epic ID**: `Epic-manage-keep-us-upgradable`
**Created**: 2026-02-18
**Purpose**: Track execution of the epic **as we actually perform it**, one PRD at a time, and record what changed **branch → branch**.

---

## 🚨 Non-Optional

This document is part of the workflow. **Following the process and updating this log is not optional.**

If we skip tracking, we lose the ability to answer:
- “What is on `sync/*` right now?”
- “Which PRD branches exist and what do they contain?”
- “What did we merge into `main`, and why?”

Policy sources:
- `knowledge_base/epics/Epic-manage-keep-us-upgradable/0000-epic-overview.md`
- `knowledge_base/epics/Epic-manage-keep-us-upgradable/0005-branching-strategy.md`
- `knowledge_base/epics/Epic-manage-keep-us-upgradable/0006-atomic-execution-plan.md`

---

## How to use this document

### What to update (minimum)

For each PRD you execute:
1. Add/refresh its row in **PRD execution status**
2. Add a short entry in **Branch-to-branch change log**
3. Record upstream links (Issue/PR) once created

### What not to do

- Do **not** paste full diffs.
- Do **not** include `knowledge_base/**` changes in upstream PR branches.
- Do **not** treat this as optional “nice documentation” — it’s the coordination artifact.

---

## Current upstream update cycle

**Cycle ID**: `2026-02-18`

### Baseline / snapshot

- Baseline branch: `sync/upstream-2026-02-18`
- Snapshot validated:
  - Lint: ❌ (4 warnings in `npm run lint:check`)
  - Typecheck: ✅
  - Tests: ❌ (web: `TaskSidebarSubtasks.test.tsx` fails; `localStorage.clear is not a function`)
- Snapshot contains epic docs commit: ❌
  - Commit: N/A
  - Message: N/A

Notes:
- `npm ci` succeeds but reports an engine mismatch warning (`node v25.2.1`; package requires `<25`).

---

## PRD execution status (one row per PRD)

Update this table as work progresses.

| PRD | Status | PR Branch (fork) | Based on | Code/Test Files Changed (high-level) | Upstream Issue | Upstream PR | Notes |
|---:|---|---|---|---|---|---|---|
| 0010 | In Progress | `perf/token-count-debouncing` | `upstream/main` | `src/main/task/task.ts`, `src/main/task/__tests__/task.context-info-debounce.test.ts` | TBD | TBD | Hooked `Task.updateContextInfo()` behind a 500ms debounce to reduce burst updates. Validation blocked because upstream web tests fail (`localStorage.clear is not a function`). Node engine mismatch noted (repo requires `<25`; local is `v25.2.1`). |
| 0020 | Done (PR branch ready) | `fix/agent-profile-lookup-fallback` | `upstream/main` | `src/main/agent/agent-profile-manager.ts`, `src/main/agent/__tests__/agent-profile-manager.test.ts`, `src/renderer/src/__tests__/setup.ts` | TBD | TBD | `AgentProfileManager.getProfile()` now falls back to case-insensitive lookup by `AgentProfile.name` when ID lookup fails (warns on ambiguity; deterministic first match). Added web test `localStorage` polyfill so pre-commit can run web tests cleanly. |
| 0030 | Done (PR branch ready) | `fix/profile-aware-task-init` | `upstream/main` | `src/common/types.ts`, `src/main/project/project.ts`, `src/main/project/__tests__/project.task-creation.test.ts` | TBD | TBD | `Project.createNewTask()` now honors `CreateTaskParams.agentProfileId` to override inherited `provider/model` by resolving the requested agent profile. |
| 0040 | Done (PR branch ready) | `feat/task-tooling-clarity` | `main` | `src/main/agent/tools/tasks.ts`, `src/main/agent/tools/__tests__/tasks.test.ts` | TBD | TBD | `tasks---create_task` tool description now documents `agentProfileId` semantics, lists available profiles, and provides examples; also passes `agentProfileId` to `createNewTask()` (ties into PRD-0030). |
| 0050 | Done (PR branch ready) | `fix/ollama-aider-prefix` | `main` | `src/main/models/providers/__tests__/ollama.aider-prefix.test.ts` | TBD | TBD | Code already used `ollama/<model>` mapping; added unit test to lock prefix behavior and prevent regressions. |
| 0060 | Done (PR branch ready) | `fix/ipc-max-listeners` | `main` | `src/preload/index.ts`, `src/preload/event-emitter-config.ts`, `src/preload/__tests__/event-emitter-limits.test.ts` | TBD | TBD | Sets `EventEmitter.defaultMaxListeners = 100` early in preload to reduce noisy IPC-related `MaxListenersExceededWarning` false positives. |
| 0070 | Done (PR branch ready) | `test/jsdom-storage-mocks` | `main` | `src/renderer/src/__tests__/setup.ts`, `src/renderer/src/__tests__/storage-mock.test.ts` | TBD | TBD | Adds full `localStorage` + `sessionStorage` mocks in web test setup (and clears between tests) to unblock storage-dependent renderer tests. |

---

## Branch-to-branch change log (the execution record)

Add entries in chronological order.

### Template (copy/paste)

```md
#### YYYY-MM-DD — PRD-00XX — <short title>

- Base:
  - PR branch: `<type/topic>`
  - Created from: `upstream/main` OR `origin/sync/upstream-YYYY-MM-DD`
- Changes made (summary):
  - `path/to/file.ts`: <what changed and why>
  - Tests: <what ran>
- Upstream tracking:
  - Issue: <url>
  - PR: <url>
- Merge / integration:
  - Merged into `sync/upstream-YYYY-MM-DD`: ✅/❌ (date, merge commit sha)
  - Landed in fork `main`: ✅/❌ (date, merge/ff sha)
```

### Entries

#### 2026-02-18 — PRD-0010 — Token-count debouncing

- Base:
  - PR branch: `perf/token-count-debouncing`
  - Created from: `upstream/main`
- Changes made (summary):
  - `src/main/task/task.ts`: debounce/batch `updateContextInfo()` calls (500ms), coalesce flags across burst calls, cancel pending work and resolve waiters on `close()`/`reset()`.
  - `src/main/task/__tests__/task.context-info-debounce.test.ts`: unit test verifying burst calls coalesce and flags OR together.
  - Tests: `npm run test` (fails on upstream baseline: web `TaskSidebarSubtasks.test.tsx` — `localStorage.clear is not a function`).
- Upstream tracking:
  - Issue: TBD
  - PR: TBD
- Merge / integration:
  - Merged into `sync/upstream-2026-02-18`: ❌
  - Landed in fork `main`: ❌

#### 2026-02-18 — PRD-0020 — Agent profile name lookup fallback

- Base:
  - PR branch: `fix/agent-profile-lookup-fallback`
  - Created from: `upstream/main`
- Changes made (summary):
  - `src/main/agent/agent-profile-manager.ts`: `getProfile()` now resolves by ID first, then falls back to case-insensitive `AgentProfile.name` matching; warns if multiple profiles match and returns a deterministic first match.
  - `src/main/agent/__tests__/agent-profile-manager.test.ts`: added unit tests for name-based lookup behavior.
  - `src/renderer/src/__tests__/setup.ts`: added/ensured in-memory `localStorage` polyfill so web tests can call `localStorage.clear()`.
  - Tests: pre-commit runs `npm run typecheck` + `npm run test` (node+web) and passed.
- Upstream tracking:
  - Issue: TBD
  - PR: TBD
- Merge / integration:
  - Merged into `sync/upstream-2026-02-18`: ❌
  - Landed in fork `main`: ❌

#### 2026-02-18 — PRD-0030 — Profile-aware task initialization

- Base:
  - PR branch: `fix/profile-aware-task-init`
  - Created from: `upstream/main`
- Changes made (summary):
  - `src/common/types.ts`: added `CreateTaskParams.agentProfileId?: string`.
  - `src/main/project/project.ts`: `Project.createNewTask()` now applies `agentProfileId` override by resolving the agent profile and overriding `provider/model` (warns + falls back if profile not found).
  - `src/main/project/__tests__/project.task-creation.test.ts`: tests for profile override and invalid-profile fallback.
  - Tests: pre-commit runs `npm run typecheck` + `npm run test` (node+web) and passed.
- Upstream tracking:
  - Issue: TBD
  - PR: TBD
- Merge / integration:
  - Merged into `sync/upstream-2026-02-18`: ❌
  - Landed in fork `main`: ❌

#### 2026-02-18 — PRD-0040 — Task tool clarity

- Base:
  - PR branch: `feat/task-tooling-clarity`
  - Created from: `main`
- Changes made (summary):
  - `src/main/agent/tools/tasks.ts`: improved `tasks---create_task` tool description and `agentProfileId` docs; lists available profiles and includes examples; passes `agentProfileId` to `createNewTask()`.
  - `src/main/agent/tools/__tests__/tasks.test.ts`: test asserts tool description includes profile list and examples.
  - Tests: pre-commit runs `npm run typecheck` + `npm run test` (node+web) and passed.
- Upstream tracking:
  - Issue: TBD
  - PR: TBD
- Merge / integration:
  - Merged into `sync/upstream-2026-02-18`: ❌
  - Landed in fork `main`: ❌

#### 2026-02-18 — PRD-0050 — Ollama Aider prefix fix

- Base:
  - PR branch: `fix/ollama-aider-prefix`
  - Created from: `main`
- Changes made (summary):
  - `src/main/models/providers/__tests__/ollama.aider-prefix.test.ts`: added test ensuring Ollama Aider mapping uses `ollama/<model>` and never `ollama_chat/<model>`.
  - Tests: pre-commit runs `npm run typecheck` + `npm run test` (node+web) and passed.
- Upstream tracking:
  - Issue: TBD
  - PR: TBD
- Merge / integration:
  - Merged into `sync/upstream-2026-02-18`: ❌
  - Landed in fork `main`: ❌

#### 2026-02-18 — PRD-0060 — IPC max listeners

- Base:
  - PR branch: `fix/ipc-max-listeners`
  - Created from: `main`
- Changes made (summary):
  - `src/preload/event-emitter-config.ts`: added `configureEventEmitterMaxListeners()`.
  - `src/preload/index.ts`: invokes `configureEventEmitterMaxListeners()` early.
  - `src/preload/__tests__/event-emitter-limits.test.ts`: verifies default max listeners is 100 and no warning at 50 listeners.
  - Tests: pre-commit runs `npm run typecheck` + `npm run test` (node+web) and passed.
- Upstream tracking:
  - Issue: TBD
  - PR: TBD
- Merge / integration:
  - Merged into `sync/upstream-2026-02-18`: ❌
  - Landed in fork `main`: ❌

#### 2026-02-18 — PRD-0070 — Test infrastructure: localStorage mock

- Base:
  - PR branch: `test/jsdom-storage-mocks`
  - Created from: `main`
- Changes made (summary):
  - `src/renderer/src/__tests__/setup.ts`: added full `Storage`-compliant `localStorage` + `sessionStorage` mocks and clears them in `beforeEach`.
  - `src/renderer/src/__tests__/storage-mock.test.ts`: validates storage mocks and independence.
  - Tests: pre-commit runs `npm run typecheck` + `npm run test` (node+web) and passed.
- Upstream tracking:
  - Issue: TBD
  - PR: TBD
- Merge / integration:
  - Merged into `sync/upstream-2026-02-18`: ❌
  - Landed in fork `main`: ❌
