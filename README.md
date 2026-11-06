# agent-skills

A small catalog of reusable agent skills, written to work with **Claude Code**
and **OpenCode** from a single copy.

Every skill is one folder with a `SKILL.md` — the format both tools read.

```
agent-skills/
├── README.md
├── install.sh          # symlink the skills into a tool's skills directory
├── THIRD_PARTY_NOTICES.md  # attribution + MIT notice for adapted skills
├── gh-issue/           # file a GitHub issue via its template, reviewed by the user
│   └── SKILL.md
├── create-pr/          # open a PR from the current work, template-aware
│   └── SKILL.md
├── show-me/            # explain the current topic with diffs, trees and diagrams
│   └── SKILL.md
├── review-pr/          # drive a PR to green: CI + SonarCloud, commit by commit
│   └── SKILL.md
├── grilling/           # relentless design-tree interview of a plan or idea
│   └── SKILL.md
├── handoff/            # compact the conversation into a handoff doc for another agent
│   └── SKILL.md
├── code-review/        # two-axis review (standards + spec) of changes since a ref
│   └── SKILL.md
└── writing-for-agents/ # reference for writing skills, AGENTS.md and CLAUDE.md
    ├── SKILL.md
    └── SKILL-MECHANICS.md
```

## Skills

| Skill       | What it does                                                                                                                                                                                                                                        |
|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `gh-issue`  | Reads the repo's issue template/form, interviews you until required fields are filled, shows the full issue for review, submits only on approval.                                                                                                   |
| `create-pr` | Preflight + conventional commits, fills the repo's PR template if it has one (otherwise a short visual description: one-sentence why, special things to note, a compact change outline of diffs and trees), previews title + body and waits for approval, then pushes and opens the PR. Local checks run only on request. *(default body adapted from humanlayer/skills)* |
| `show-me`   | Explains the current topic visually: pseudocode, call and component trees, file trees, Mermaid, `diff` views, or one focused HTML page. User-invoked only. *(adapted from humanlayer/skills)* |
| `review-pr` | Waits for CI, diagnoses GitHub Actions / CircleCI failures, reads SonarCloud findings when the project uses Sonar, fixes them in separate commits with a progress update after each push, until everything is green.                                |
| `grilling`  | Interviews you in rounds over a design tree of decisions, with a recommended answer per question, until nothing is left assumed. *(adapted from mattpocock/skills)* |
| `handoff`   | Writes a handoff document summarising the conversation for a fresh agent, saved to the OS temp dir with secrets redacted. User-invoked only. *(adapted from mattpocock/skills)* |
| `code-review` | Reviews the diff since a fixed point on two axes in parallel sub-agents: Standards (repo docs + code-smell baseline) and Spec (the issue/spec you point to). *(adapted from mattpocock/skills)* |
| `writing-for-agents` | Reference for writing agent-facing documents (skills, `AGENTS.md`, `CLAUDE.md`): context pointers, information hierarchy, completion criteria. *(adapted from mattpocock/skills)* |

## Attribution

`grilling`, `handoff`, `code-review` and `writing-for-agents` are adapted from
[mattpocock/skills](https://github.com/mattpocock/skills) by Matt Pocock (MIT).
`code-review` was changed to work without that repo's setup skill and issue
tracker configuration; the other three are unmodified.

`show-me` and the default PR body of `create-pr` (used when a repository has no
PR template) are adapted from [humanlayer/skills](https://github.com/humanlayer/skills)
by HumanLayer (MIT). `show-me` only had its HTML-artifact step generalised. See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the license notice.

## Compatibility

Both tools need the same thing: `<skills-dir>/<name>/SKILL.md` with YAML
frontmatter containing `name` and `description`.

|               | Claude Code                                       | OpenCode                               |
|---------------|---------------------------------------------------|----------------------------------------|
| `name`        | required                                          | required, must match the folder name   |
| `description` | required                                          | required, 1–1024 chars                 |
| other fields  | `allowed-tools`, `model`, … (ignored by OpenCode) | `license`, `compatibility`, `metadata` |

Name rules (both tools): lowercase alphanumeric with single hyphens,
`^[a-z0-9]+(-[a-z0-9]+)*$`, 1–64 chars, identical to the directory name.

OpenCode also discovers skills at `~/.claude/skills/`, so one install location
can serve both tools.

## Install

```bash
./install.sh                 # default: ~/.claude/skills  (Claude Code + OpenCode)
./install.sh --opencode      # ~/.config/opencode/skills  (OpenCode only)
./install.sh --target DIR    # any directory you pick
```

The script creates relative-safe symlinks, so the catalog stays the single
source of truth — edit a `SKILL.md` here and both tools pick it up (restart
the session to rediscover skills).

Per-project install (only inside one repository):

```bash
mkdir -p .claude/skills
ln -s ../../../agent-skills/gh-issue .claude/skills/gh-issue
```

## Uninstall

```bash
./install.sh --uninstall           # removes the links it created
rm -rf ~/.claude/skills/<name>     # or by hand
```

## Adding a skill

1. `mkdir <name>` — name follows the rules above.
2. Create `<name>/SKILL.md` with `name` + `description` frontmatter. The
   `description` decides when the agent loads it, so make it specific:
   "Use when the user wants to …".
3. Keep the body operational: steps, exact commands, explicit stop conditions
   and guardrails — not background prose.
4. Run `./install.sh` again (it only adds new links).
5. Keep the folder self-contained; extra files are fine
   (`<name>/references/…`), they travel with the symlink.
