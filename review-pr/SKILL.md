---
name: review-pr
description: Take a pull request to green - wait for CI, diagnose failing GitHub Actions or CircleCI jobs, read SonarCloud findings for the PR when Sonar analysis is active, fix them in separate commits with a progress update after each push, and repeat until every check passes. Use when the user wants a PR reviewed, its checks fixed, or its quality gate made green.
---

## What this skill does

Makes an existing PR pass its gates and reports progress while doing it:

1. Snapshot the PR and wait for checks to finish
2. Triage failures per provider (GitHub Actions, CircleCI, others)
3. Read SonarCloud issues/quality gate when Sonar is active for the project
4. Fix findings in **separate commits**, push, re-check, update the user — until green
5. Final report: what was fixed, what remains, and why

Work on the PR's **head branch**. Never merge, never force-push.

## Step 1 — Identify the PR

```bash
# given a URL/number
gh pr view <n> --repo <owner>/<repo> --json url,state,baseRefName,headRefName,headRefOid,title,mergeable

# or from the current branch
gh pr view --json url,state,baseRefName,headRefName,headRefOid,title
```

If there is no PR yet, confirm whether the user wants one created (use the
`create-pr` skill) before fixing anything.

Fetch the branch if the local copy is stale: `git fetch origin <head-branch>`.

## Step 2 — Wait for the checks

```bash
gh pr checks <n> --repo <owner>/<repo>            # snapshot
gh pr checks <n> --repo <owner>/<repo> --watch    # block until settled
```

If checks are still pending, watch them — do not start "fixing" a gate that
has not run yet. Split the results into:

- **blocking**: required checks, `SonarCloud Code Analysis`, the primary test job
- **informational**: codecov coverage deltas, Renovate, license scans

Only chase blocking failures unless the user says otherwise.

## Step 3 — Triage the failures

Get the machine-readable list with links:

```bash
gh api repos/<owner>/<repo>/commits/<head-sha>/check-runs \
  --jq '.check_runs[] | [.name, (.conclusion // "pending"), (.details_url // "")] | @tsv'
```

**GitHub Actions** (`<owner>/<repo>/actions/runs/...`):

```bash
gh run list --repo <owner>/<repo> --branch <head-branch> --limit 5
gh run view <run-id> --repo <owner>/<repo> --log-failed     # failing steps only
gh run view <run-id> --repo <owner>/<repo> --job <job-id> --log
```

Reproduce the failing command locally where possible (same version/flags) and
fix it there — local verification first, push second.

**CircleCI** (`circleci.com/gh/...`):

1. If the `circleci` CLI is installed and a token is available:
   `circleci step list <vcs>/<project> <build-number>` to find the failing step.
2. Else if `CIRCLE_TOKEN` is set, use the API:
   `curl -s -H "Circle-Token: $CIRCLE_TOKEN" "https://circleci.com/api/v2/project/gh/<org>/<repo>/<build-number>/job"`.
3. Otherwise open `details_url`, and ask the user for the failing step's log
   excerpt — do not guess at CircleCI failures from the check name alone.

**Other checks**: read the details URL first; only dig deeper if it is blocking.

## Step 4 — SonarCloud (only if active for this project)

Detect activity — if none of these exist, skip this step and say so:

- a check run named `SonarCloud*` / `SonarQube*`
- `.sonarcloud.properties` or `sonar-project.properties` in the repo
- a Sonar badge in the README (`sonarcloud.io/api/project_badge/...id=<key>`)
- a Sonar step in `.github/workflows/*` or `.circleci/config.yml`

Find the project key (`sonar.projectKey`, or the `id=` parameter of the badge
URL — key format is usually `<org>_<repo>`), then:

```bash
# open findings on this PR (rule, file, line, message)
curl -s "https://sonarcloud.io/api/issues/search?componentKeys=<key>&pullRequest=<n>&resolved=false&ps=100" \
  | jq -r '.issues[] | "\(.severity) \(.rule) \(.component|split(":")[-1]):\(.line // "?") — \(.message)"'

# quality gate + duplication on new code
curl -s "https://sonarcloud.io/api/measures/component?component=<key>&pullRequest=<n>&metricKeys=alert_status,new_duplicated_lines_density,new_lines"
```

- Private projects need `-u "$SONARCLOUD_TOKEN:"` on both calls.
- Focus on the PR's **leak period** (new code). Pre-existing findings on the
  base branch are not this PR's job unless the user asks.
- If exclusions seem to be ignored on SonarQube Cloud automatic analysis, the
  config file (`.sonarcloud.properties`) usually has to be on the **default**
  branch — say so instead of re-tuning patterns repeatedly.

## Step 5 — Fix loop

For each iteration:

1. **Group** the findings by concern (one rule across files, or one file) and
   order them cheapest-first. Skip nothing blocking without saying why.
2. **Fix** the code. Prefer the real fix over suppression: restructuring,
   using the API the rule wants, excluding test files from analysis via config
   where the rule is about test code. Only suppress with a comment (e.g.
   `// NOSONAR`) if the repository already uses that convention — and say so.
3. **Verify locally**: run the project's checks (typecheck, tests, lint) on
   the touched code before every push.
4. **Commit separately**: one commit per concern, conventional message
   (`chore: address sonar S7773 in config`, `fix: ...`), with the
   `Co-Authored-By:` trailer when repo/global instructions require it.
5. **Push** to the PR head branch (no force-push).
6. **Report progress** — after every push, short and factual:

   ```text
   [1/3] pushed <sha> chore: use Number.parseInt in config
         sonar issues on PR: 2 -> 1 (S7773 fixed)
         checks: CircleCI running, Sonar re-analyzing
   ```

7. **Re-check**: wait for CI and Sonar to re-run on the new head
   (`gh pr checks --watch`, and re-query the Sonar API until the head SHA or
   the numbers change), then re-triage.

Stop when: every blocking check passes **and** Sonar reports
`alert_status=OK` with no open PR issues (or no Sonar at all).

Stop early and report instead when: the failure is unrelated to the PR
(flaky/infrastructure), it needs a product decision, or it needs permissions
the user has (labels, secrets, repo settings).

## Step 6 — Final report

```text
PR #23 — all checks green
  commits added:  2 (sonar config, Number.parseInt)
  sonar: 2 -> 0 open issues, duplication 0.0% (gate OK)
  CI:    GitHub Actions pass, CircleCI pass, codecov pass
  not done: <anything skipped, with the reason>
```

## Guardrails

- Never merge, never rebase/force-push a shared branch, never push to the
  default branch.
- Never disable, delete, or edit a CI workflow or the quality gate to make a
  check pass — fix the code, or ask.
- Never fix findings outside the PR's changed code without being asked.
- Keep the user updated after each push; do not batch five commits and reveal
  the result at the end.
