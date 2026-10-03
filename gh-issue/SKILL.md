---
name: gh-issue
description: File a GitHub issue the careful way - read the repository's issue template or issue form first, interview the user until every required field is answered, show the complete issue for review, and only submit after explicit approval. Use when the user wants to create, file, or draft a GitHub issue or bug report.
---

## What this skill does

Creates a GitHub issue in the right shape for the target repository:

1. Reads the repo's issue template (or issue form) before drafting anything
2. Asks the user the questions the template expects
3. Shows the finished issue in full and waits for approval
4. Submits with `gh` and reports the URL

**Never submit before the user has seen and approved the full text.**

## Step 1 — Identify the target

- Confirm the repository (`gh repo view --json nameWithOwner -q .nameWithOwner`).
  If the user gave an issue URL or a repo slug, resolve it explicitly.
- For repositories the user does not own (upstream/third-party), repeat the
  repository name back to them in the review step — issues cannot be moved
  between repos afterwards.

## Step 2 — Find the template

Look for these, in order:

| Kind | Paths |
|---|---|
| Issue form (YAML) | `.github/ISSUE_TEMPLATE/*.yml`, `.github/ISSUE_TEMPLATE/*.yaml` |
| Issue template (Markdown) | `.github/ISSUE_TEMPLATE/*.md`, `ISSUE_TEMPLATE.md`, `.github/ISSUE_TEMPLATE.md` |
| Config | `.github/ISSUE_TEMPLATE/config.yml` (check `blank_issues_enabled`) |

Commands:

```bash
gh api repos/<owner>/<repo>/contents/.github/ISSUE_TEMPLATE --jq '.[].name'
gh api repos/<owner>/<repo>/contents/.github/ISSUE_TEMPLATE/<file> --jq '.content' | base64 -d
```

Use the API rather than a local clone when the repo is not checked out.

Multiple templates: list them with their `name:`/`description:` and let the
user pick one before doing anything else.

**No template** → skip to Step 3 with an empty structure and build a standard
issue (Description / Steps to reproduce / Expected vs actual / Environment),
then say in the review that no template was found.

## Step 3 — Extract what must be filled

For an **issue form** (YAML) read `body:` and collect, per entry:

- `type:` — `input`, `textarea`, `dropdown`, `checkboxes`, `markdown`
- `attributes.label` and `attributes.description` / `attributes.placeholder`
- `validations.required` — these are the blockers
- `attributes.options` — offer these as choices
- Top-level `title:` (title prefix/pattern) and `labels:` (initial suggestions)

For a **Markdown template** treat every HTML comment (`<!-- ... -->`) as the
instruction and the heading/placeholder under it as the field to fill.

`type: markdown` blocks are instructions for the reporter — honor them
(e.g. "search first"), they are not answer fields.

## Step 4 — Interview the user

- Ask for every **required** field first, in batches (several questions per
  message), not one at a time.
- Use the multiple-choice/question tool when it is available; otherwise ask in
  plain text and wait.
- Offer `skip` for optional fields instead of inventing answers.
- Do **not** fill required fields with guesses or placeholders. If the user
  does not know, say so explicitly in the issue rather than leaving the
  template section empty.
- Ask the one or two things that are not in the template but matter for
  triage: version, environment, and whether it reproduces on a clean install.

## Step 5 — Assemble

- **Title**: use the form's `title:` prefix if present (e.g. `[BUG] - `),
  otherwise follow repo conventions from open issues
  (`gh issue list --limit 20 --json title`). Keep it specific, under ~80 chars.
- **Labels**: start from the template's `labels:`. Verify the labels exist
  before submitting: `gh label list --repo <owner>/<repo> --limit 100`.
  Drop labels that do not exist and mention that in the review — do not create
  labels in someone else's repo.
- **Body**: keep the template's section order and headings. For an issue form
  render each field as:

  ```markdown
  ### <label>

  <answer>
  ```

  (`gh` cannot submit YAML issue forms through the API, so the body is plain
  Markdown with the form's structure — say so in the review step.)

## Step 6 — Show the full preview, then wait

Show the complete result — nothing paraphrased:

```text
Repository:  owner/repo
Title:       ...
Labels:      bug, triage   (dropped: xyz — not in repo)
Template:    .github/ISSUE_TEMPLATE/bug-report.yaml

----------------------------------------------------------------------
<body, verbatim>
----------------------------------------------------------------------

Submit this issue? [y] submit / [e] edit / [n] cancel
```

Then **stop and wait**. Accept edits, apply them, and show the preview again.
Only create the issue after an explicit yes.

## Step 7 — Submit and report

```bash
gh issue create --repo <owner>/<repo> --title "<title>" --body-file /tmp/issue-body.md --label bug
```

- Write the body to a file first so quoting never mangles it.
- If a label fails (missing or no permission), retry without `--label` and
  tell the user which label could not be applied — do not retry blindly.
- Report the created URL, and note anything skipped, dropped, or changed
  relative to the template.

## Guardrails

- No submission of any kind before the user approves the preview.
- Never guess required template fields.
- Never create labels, never add assignees/milestones unless asked.
- If the repo needs an issue-form web submission (fields that cannot be
  expressed as Markdown), give the prefilled URL instead of forcing `gh`.
