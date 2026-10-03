---
name: create-pr
description: Create a pull request that a maintainer can review quickly - inspect the diff, run the project's checks, commit with the repo's convention, fill the repository's PR template when one exists (otherwise use a concise Problem/Changes/Verification structure), preview the result, push a dedicated branch and open the PR. Use when the user wants to open, raise, or submit a PR.
---

## What this skill does

Turns the current work into a reviewable pull request:

1. Checks what is actually being shipped (diff, branch, stray files)
2. Builds the PR body from the repository's template, or a concise default
3. Previews title + body and waits for a yes
4. Pushes a dedicated branch, opens the PR, confirms checks started

Local checks are **not** run by default — the user asks for them explicitly.

## Step 1 — Preflight

```bash
git fetch origin
git status -sb                 # staged/unstaged/untracked
git diff --stat                # tracked changes
git diff --stat origin/main    # vs the default branch (adjust base)
git log --oneline -10          # recent history + branch context
git remote -v
```

Then decide:

- **Branch**: never PR from the default branch, never push to it. If work sits
  on a stale or shared branch, cut a dedicated one from the up-to-date base:
  `git switch -c <type>/<short-slug> origin/<base>` (changes follow if the
  files are identical between branches).
- **Scope**: if the diff mixes unrelated concerns, split into separate PRs or
  at least separate commits — say what you chose and why.
- **Existing PR**: `gh pr list --head <branch>` — if one exists, update it
  (`gh pr edit`) instead of opening a second one.
- **Repo instructions**: read `AGENTS.md`, `CONTRIBUTING.md`, and the PR
  template before writing anything.

## Step 2 — Know what CI will run (don't run it yourself)

By default do **not** run the project's checks locally: the user has chosen
speed and CI is the safety net. Just find out what will run, so the preview
can say what to expect:

```bash
ls .github/workflows 2>/dev/null; ls .circleci 2>/dev/null
cat package.json | jq '.scripts'   # or Makefile / AGENTS.md
```

Mention the checks by name in the preview, e.g.
`CI: CircleCI unit-test, SonarCloud Code Analysis`.

**Only when the user asks** ("verify", "make sure it's green", "run the
tests") run the fast relevant checks and fix failures before committing:

```bash
npm run typecheck   # or tsc --noEmit / cargo check / ...
npm test            # or make test / pytest / ...
npm run lint        # if it exists
```

If you ran checks, re-run them after any later edit to the touched files.

## Step 3 — Commit

- Conventional style unless the repo says otherwise:
  `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.
- One logical change per commit; separate cleanup/refactors from the fix.
- Keep the message body short: what changed and why, not a code walkthrough.
- Add the `Co-Authored-By:` trailer when the repo or the global agent
  instructions require it.
- Stage explicit paths (`git add <files>`), never a blind `git add -A`
  outside a clean, understood working tree.

## Step 4 — Build the title and body

**Title**: conventional prefix + what the change does, under ~70 chars.

**Body — template first.** Look for, in order:

1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/PULL_REQUEST_TEMPLATE/*.md`
3. `docs/pull_request_template.md`, `PULL_REQUEST_TEMPLATE.md` (repo root)

```bash
gh api repos/<owner>/<repo>/contents/.github/PULL_REQUEST_TEMPLATE.md --jq '.content' | base64 -d
```

If a template exists: keep its headings exactly, honor its HTML comments and
any `_(REQUIRED)_` markers, delete sections the template allows you to delete,
and follow title instructions it gives (e.g. Conventional Commits prefixes).
Anything you cannot answer goes to the user as a question — never leave a
required section as a placeholder.

**Body — no template: use the concise default** (verified working structure):

```markdown
Closes #<n>            <!-- only when the PR actually resolves an issue -->

## Problem / Feature

What is broken or missing, and why the change is needed. One short paragraph;
include the reproduction or the failing condition if there is one.

Or if its a feature what was added.

## Changes

- `path/file.ts:12` — what changed there and why
- ...

## Verification

- What was proven, with commands and numbers: `npm test` — 112 passed (8 new)
- Or state plainly "not run locally — CI covers this" when no checks were run
- Anything deliberately not covered

## Notes                <!-- optional: trade-offs, follow-ups, upstream links -->
```

Keep it factual: numbers and commands over adjectives. Mention upstream
tickets/links instead of re-explaining them.

## Step 5 — Preview and confirm

Show exactly what will be created:

```text
Repository:  owner/repo
Base:        main  ←  Head: fix/<slug> (<n> commits, <n> files)
Title:       fix: ...
CI:          CircleCI unit-test, SonarCloud Code Analysis
Local checks: not run

----------------------------------------------------------------------
<body, verbatim>
----------------------------------------------------------------------

Push branch and create PR? [y] / [e] edit / [n] cancel
```

Wait for confirmation when the user has not already said "just do it".
Apply edits, re-show the preview if anything changed.

## Step 6 — Push and create

```bash
git push -u origin <branch>
gh pr create --repo <owner>/<repo> --base <base> --head <branch> \
  --title "<title>" --body-file /tmp/pr-body.md
```

- Body in a file, never shell-quoted inline.
- If the push is rejected (base moved), rebase or merge the base per repo
  convention, run local checks if the user asked for them, then push — never
  force-push a shared branch.

## Step 7 — Confirm and report

```bash
gh pr checks <n> --repo <owner>/<repo>    # checks actually started
gh pr view <n> --json url,state
```

Report: PR URL, commits included, which checks are running. If checks fail,
offer to take them on with the `review-pr` skill rather than silently starting
to fix them.
