### Epic: Manage & Keep Us Upgradable — Atomic Execution Plan

**Epic ID**: `Epic-manage-keep-us-upgradable`
**Created**: 2026-02-18
**Purpose**: A step-by-step, **non-optional** procedure for executing this epic with clean diffs, clean PRs, and minimal long-lived divergence.

---

## ✅ Definition of Done (end state)

When this plan is followed for a given upstream update cycle:

1. We have a validated upstream baseline branch: `sync/upstream-YYYY-MM-DD`.
2. Each upstream-worthy fix is implemented and reviewed as **one PR branch per PRD**.
3. Those PR branches are submitted as PRs to upstream (from our fork).
4. Our fork `main` ends up equal to:
   - the validated `sync/upstream-YYYY-MM-DD` baseline
   - **plus** any fork-only divergence we intentionally keep
   - **plus** any fixes that are still pending upstream acceptance (temporarily), tracked by PRD status.

---

## 🚨 Non-Optional Rules (reinforced)

These rules are duplicated here on purpose:

1. **Never implement upstream-worthy fixes directly on our fork `main`.**
2. **PR branches must be based on `upstream/main` (preferred) or a validated `sync/*` snapshot.**
3. **One PR branch = one PRD / one upstream-worthy change.**
4. **Do not include `knowledge_base/**` changes in upstream PRs.**

Authoritative policy text:
- `knowledge_base/epics/Epic-manage-keep-us-upgradable/0000-epic-overview.md`
- `knowledge_base/epics/Epic-manage-keep-us-upgradable/0005-branching-strategy.md`
- `knowledge_base/epics/Epic-manage-keep-us-upgradable/0007-implementation-status.md`

---

## 0) Pre-flight (do this every time)

### 0.1 Confirm you have remotes

```bash
git remote -v
git fetch origin
git fetch upstream
```

### 0.2 Confirm your working tree is clean

This epic intentionally avoids “carry local WIP forward.”

```bash
git status
```

If you have uncommitted changes and you want to **test the process (Option B)**, discard them:

```bash
# WARNING: this discards local modifications
git restore .
git clean -fd
```

---

## 1) Create / refresh the upstream tracking branch (local only)

```bash
git fetch upstream
git checkout -B upstream-main upstream/main
```

Notes:
- `upstream-main` is a local convenience branch.
- Do not PR from `upstream-main`.

---

## 2) Create a validated snapshot baseline (`sync/*`)

Create the snapshot branch:

```bash
git fetch upstream
git checkout -B sync/upstream-YYYY-MM-DD upstream/main
git push -u origin sync/upstream-YYYY-MM-DD
```

Validate the snapshot (record results in the epic notes if anything fails):

```bash
npm ci
npm run lint:check
npm run typecheck
npm run test
```

---

## 3) Ensure the epic docs exist on the snapshot (internal-only)

If you will do PRD work starting from the `sync/*` branch, bring the epic docs onto it so the process travels with the baseline.

On `sync/upstream-YYYY-MM-DD`:

```bash
git checkout origin/main -- knowledge_base/epics/Epic-manage-keep-us-upgradable
git add knowledge_base/epics/Epic-manage-keep-us-upgradable
git commit -m "docs(epic): sync upgradability process docs onto snapshot"
git push
```

Important:
- This commit is **fork-only**. It is not intended for upstream.

---

## 4) Create one PR branch per PRD (atomic)

For each PRD (example: PRD-0010 token debouncing):

```bash
git checkout -b perf/token-count-debouncing origin/sync/upstream-YYYY-MM-DD
```

### 4.1 Reimplement from the PRD (preferred)

- Follow the PRD’s reproduction steps.
- Implement the minimal change.
- Add/update tests if appropriate.

### 4.2 Keep upstream PRs free of `knowledge_base/**`

Before committing, verify the diff contains only code/tests needed for the PR:

```bash
git status
git diff
```

If you accidentally modified `knowledge_base/**`, restore it:

```bash
git restore --source=HEAD --staged --worktree -- knowledge_base
```

### 4.3 Validate and commit

```bash
npm run lint:check
npm run typecheck
npm run test

git add -A
git commit -m "perf(task): debounce token estimation"
git push -u origin perf/token-count-debouncing
```

Open a PR:
- Base: `upstream/main`
- Head: `origin/perf/token-count-debouncing`

---

## 5) Keep `sync/*` as the integration staging branch

While upstream review is pending, you can use `sync/upstream-YYYY-MM-DD` as your integration branch for **our fork**.

### 5.1 (Optional) Merge PR branches into `sync/*` for fork testing

If you want a single branch that contains the snapshot plus all our fixes (to validate the combined state):

```bash
git checkout sync/upstream-YYYY-MM-DD
git merge --no-ff perf/token-count-debouncing
git push
```

Notes:
- This is for our fork validation. Upstream PRs remain atomic.
- If you prefer linear history, use `git rebase` locally, but do not rewrite published branch history unless the team agrees.

---

## 6) Update fork `main` to “sync + PRs”

After the snapshot is validated and you have merged the desired PR branches into `sync/*` (for fork usage), update fork `main`.

Recommended:

```bash
git checkout main
git pull origin main

git merge --ff-only origin/sync/upstream-YYYY-MM-DD
git push
```

If `--ff-only` fails, stop and investigate. A non-fast-forward merge into `main` usually indicates the process was bypassed or there is untracked divergence.

---

## 7) Update PRD statuses and record decisions

After each PR branch is created (and especially after upstream review):

- Update the PRD’s `Upstream Tracking` (Issue/PR links)
- Update PRD lifecycle status (`Active`, `Merged Upstream`, `Superseded`, etc.)
- Record any upstream feedback and changes needed

Also update our execution log so we can track what changed branch → branch:

- `knowledge_base/epics/Epic-manage-keep-us-upgradable/0007-implementation-status.md`

---

## Appendix: Suggested PRD → branch mapping (current inventory)

- PRD-0010 → `perf/token-count-debouncing`
- PRD-0020 → `fix/agent-profile-lookup-fallback`
- PRD-0030 → `fix/profile-aware-task-init`
- PRD-0040 → `feat/task-tooling-clarity`
- PRD-0050 → `fix/ollama-aider-prefix`
- PRD-0060 → `fix/ipc-max-listeners`
- PRD-0070 → `test/jsdom-storage-mocks`
