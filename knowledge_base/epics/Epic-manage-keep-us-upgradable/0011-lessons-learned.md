---
title: Lessons learned (Epic: manage/keep-us-upgradable)
date: 2026-02-18
---

## Context

This epic follows the atomic execution strategy in `0006-atomic-execution-plan.md`: one PRD per branch, upstream-first, and a consolidated proof stack branch that verifies all PRDs compose cleanly.

During this cycle we experienced workflow drift and had to correct course.

## What went wrong (root causes)

### 1) PRD branches were created off fork `main` instead of `upstream/main`

PRDs `0040–0070` were initially implemented on branches created from fork `main`. That violates the atomic plan’s requirement that upstream-worthy changes be based on `upstream/main` (or a validated `sync/*` snapshot).

**Why it happened:** it’s easy to end a session on a topic branch and then start the next PRD without re-basing the work context back to the required base.

### 2) Epic status tracking (`0007-implementation-status.md`) lagged behind reality

We had implemented several PRDs, but the epic status doc on `main` didn’t reflect it promptly. This reduced confidence in “what’s done” and made it harder to coordinate.

### 3) Confusion between goals: “proof stack” vs “upstream-submittable PRD branch”

Cherry-picking is fine for a proof/stack branch, but each PRD branch still needs to be upstream-based to be considered upstream-submittable.

## What we changed (corrective actions)

### 1) Adopted a two-worktree workflow

We now use `git worktree`:

- **Docs worktree** (single source of truth): fork `main` for all `knowledge_base/**` updates.
- **Code worktree**: used for `upstream/main`, `sync/*`, PRD branches, and `proof/*` stacking.

This prevents losing access to epic documents while working on upstream branches and reduces the temptation to copy docs into temporary folders.

### 2) Archived and recreated PRD branches with canonical names on `upstream/main`

We archived the incorrect-base branches under `archive/*` and recreated canonical PRD branch names from `upstream/main`.

### 3) Proof stack built and validated

We built `proof/stack-2026-02-18` from `upstream/main` and merged PRDs `0010–0070`, resolving one conflict (`setup.ts`) by keeping PRD-0070’s full storage mocks.

## Document/process improvements to make (suggested edits)

### A) Add a “Start each PRD” checklist in `0006-atomic-execution-plan.md`

Add a small pre-flight checklist:

- Confirm current branch is `upstream/main` (or validated `sync/*`).
- Confirm working tree clean.
- Create PRD branch from the correct base.
- Record base commit SHA in `0007-implementation-status.md` entry.

### B) Strengthen `0007-implementation-status.md` as the authoritative scoreboard

Add (or enforce) fields per PRD row:

- Base branch (`upstream/main` vs `sync/*`) and base commit SHA
- Last validation result (lint/typecheck/test) + timestamp
- Proof-stack inclusion status
- PR link(s) (fork PR and upstream PR)

### C) Add explicit guidance on branch naming and archiving

Add a rule:

- If a branch was created off the wrong base, do not reuse the name silently.
- Archive it under `archive/<name>-<reason>-<date>` and recreate correctly.

### D) Add a “proof stack success criteria” note

Clarify that baseline failures are recorded for comparison, but the proof stack target is:

- **All tests passing** unless the plan explicitly allows a failure that is not expected to be fixed by any PRD in the stack.

## Concrete next-step recommendations

1. Add the pre-flight checklist to `0006-atomic-execution-plan.md`.
2. Add the extra columns/fields to `0007-implementation-status.md`.
3. Keep a standing rule: every PRD completion includes a same-day `0007` update PR on `main`.
