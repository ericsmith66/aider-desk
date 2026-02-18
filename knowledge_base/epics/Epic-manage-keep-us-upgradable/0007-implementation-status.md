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

### Process note (plan revision)

- We observed a workflow drift where PRD branches (PRD-0040 → PRD-0070) were initially created off fork `main`.
  - This violates the non-optional rule in `0006-atomic-execution-plan.md` that upstream-worthy fixes must be based on `upstream/main` (or a validated `sync/*` snapshot).
- Corrective action:
  - Adopt a two-worktree workflow (single source of truth):
    - **Docs worktree**: fork `main` (this file + all `knowledge_base/**`)
    - **Code worktree**: `upstream/main`, `sync/*`, PRD branches, and `proof/*` stacking
  - Archive the existing `main`-based PRD-0040..0070 branches, then recreate clean canonical PRD branches from `upstream/main`.
  - Build and validate `proof/stack-2026-02-18` by merging PRD branches (including PRD-0010) on top of `upstream/main`.

This note is here so future cycles can audit what happened and why we changed the workflow.

### Proof stack status

- Proof branch: `proof/stack-2026-02-18`
  - Base: `upstream/main`
  - Contains PRDs: `0010–0070`
  - Validation:
    - Lint: ✅
    - Typecheck: ✅
    - Tests: ✅ (`27/27` files, `212/212` tests)
  - Notes:
    - Merge conflict in `src/renderer/src/__tests__/setup.ts` resolved by keeping PRD-0070 full storage mocks.
    - `run_aider_desk_capture.sh` was copied from fork `main` into the proof branch for convenience.

---

## PRD execution status (one row per PRD)

Update this table as work progresses.

| PRD | Status | PR Branch (fork) | Based on | Code/Test Files Changed (high-level) | Upstream Issue | Upstream PR | Notes |
|---:|---|---|---|---|---|---|---|
| 0010 | In Progress | `perf/token-count-debouncing` | `upstream/main` | `src/main/task/task.ts`, `src/main/task/__tests__/task.context-info-debounce.test.ts` | TBD | TBD | Hooked `Task.updateContextInfo()` behind a 500ms debounce to reduce burst updates. Validation blocked because upstream web tests fail (`localStorage.clear is not a function`). Node engine mismatch noted (repo requires `<25`; local is `v25.2.1`). |
| 0020 | Planned | `fix/agent-profile-lookup-fallback` |  |  | TBD | TBD | |
| 0030 | Planned | `fix/profile-aware-task-init` |  |  | TBD | TBD | |
| 0040 | Planned | `feat/task-tooling-clarity` |  |  | TBD | TBD | |
| 0050 | Planned | `fix/ollama-aider-prefix` |  |  | TBD | TBD | |
| 0060 | Planned | `fix/ipc-max-listeners` |  |  | TBD | TBD | |
| 0070 | Planned | `test/jsdom-storage-mocks` |  |  | TBD | TBD | |

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
