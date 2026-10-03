# agent-skills

A small catalog of reusable agent skills, written to work with **Claude Code**
and **OpenCode** from a single copy.

Every skill is one folder with a `SKILL.md` — the format both tools read.

```
agent-skills/
├── README.md
├── install.sh          # symlink the skills into a tool's skills directory
├── gh-issue/           # file a GitHub issue via its template, reviewed by the user
│   └── SKILL.md
├── create-pr/          # open a PR from the current work, template-aware
│   └── SKILL.md
└── review-pr/          # drive a PR to green: CI + SonarCloud, commit by commit
    └── SKILL.md
```

## Skills

| Skill       | What it does                                                                                                                                                                                                                                        |
|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `gh-issue`  | Reads the repo's issue template/form, interviews you until required fields are filled, shows the full issue for review, submits only on approval.                                                                                                   |
| `create-pr` | Preflight + conventional commits, fills the repo's PR template if it has one (otherwise a concise Problem/Changes/Verification body), previews title + body and waits for approval, then pushes and opens the PR. Local checks run only on request. |
| `review-pr` | Waits for CI, diagnoses GitHub Actions / CircleCI failures, reads SonarCloud findings when the project uses Sonar, fixes them in separate commits with a progress update after each push, until everything is green.                                |

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
