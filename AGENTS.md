# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## What this repo is

`Starling/` is **not an application codebase** — it is a multi-agent configuration & skills hub. Four parallel agent configs live side-by-side, each with its own `settings.json` and a near-identical `skills/` library of ~37 superpowers-style skills:

- `.Codex/` — Codex config (uses `PreToolUse`/`PostToolUse` hooks, `enabledPlugins`, `mcpServers`)
- `.codex/`  — Codex CLI config (uses `BeforeTool`/`AfterTool` hooks)
- `.commandcode/` — Command Code config
- `.agents/` — generic agents config

There is no build, no test runner, no application source. Treat this directory as **configuration + portable skill library**, not code.

## The cross-project hook target

The hooks under `.Codex/hooks/` and `.codex/hooks/` are written for a *different* project at `D:/cpplearn/` (a Node/Express + client app backed by a SQLite `data/cultivation.db`). Two rules are enforced whenever Codex/Codex edits files via `Write`/`Edit`:

1. **Block `.env` writes** — direct AI edits to any `.env` file exit with `decision: deny` / exit code 2. If the user needs `.env` changed, tell them to edit manually.
2. **Auto-backup `cultivation.db`** — before editing `db.js` or `importCourses.js`, the hook copies `data/cultivation.db` → `data/cultivation.db.bak.<timestamp>`. Failure to back up does not block the edit.
3. **Post-edit ESLint** — after writing any `.js`/`.jsx` file (excluding `node_modules`), runs `npx eslint <file> --max-warnings=5` from the repo root, or from `client/` if the path includes `/client/`. Warnings go to stderr only — they don't fail the tool call.

The Codex hook absolute paths (`D:/cpplearn/.Codex/hooks/...`) and the Codex relative paths (`.codex/hooks/...`) mean these configs only behave correctly when **invoked from `D:/cpplearn/`**, not from `Starling/` itself.

All four agents now carry their own `hooks/` directory with the same `before-tool.js` / `after-tool.js` (or `pre-tool.js` / `post-edit-lint.js` for Codex — different schema, same behavior). If you add a new agent config, mirror the hook pair from `.codex/hooks/`.

## Skill library layout

Each agent's `skills/<skill-name>/SKILL.md` follows the superpowers convention:

```
---
name: <skill-name>
description: <one-line trigger description>
---
<skill body>
```

Most skills are single-file (`SKILL.md` only). A few carry data/scripts:
- `ui-ux-pro-max/` includes `data/*.csv` and `scripts/*.py` (this is the one skill where the four mirrored copies have **diverged content** — keep that in mind when syncing).
- `frontend-design/` carries a `LICENSE.txt`.

If the user asks to edit a skill, ask which agent's copy is canonical — by default, **propagate the change to all four mirrors** (`.agents`, `.Codex`, `.codex`, `.commandcode`) to keep them in sync.

## MCP servers (shared across all four configs)

All four `settings.json` files declare the same MCP server set:
- `sqlite` → `data/cultivation.db` (cpplearn's DB; path style differs per agent)
- `puppeteer`, `github`, `brave-search`, `figma`, `pencil`

The `BRAVE_API_KEY` and `FIGMA_ACCESS_TOKEN` are committed in plaintext in every `settings.json`. If you're asked to rotate or share these files, **warn the user** — they're real credentials.

## Codex-specific: enabled plugins

`.Codex/settings.json` enables ~25 official Codex plugins (`superpowers`, `frontend-design`, `context7`, `playwright`, `feature-dev`, `serena`, `supabase`, `firebase`, `github`, `commit-commands`, `pr-review-toolkit`, `code-review`, `Codex-md-management`, `hookify`, etc.). Many of the skills surfaced in your skill list come from these plugins, not from `skills/` — don't try to edit a plugin's skill by writing files in `Starling/`.

## When editing files here

- **Don't run a build/test** — there is none. Validation is reading the JSON / SKILL.md you just wrote.
- **Settings JSON**: each agent has its own schema for hooks (`PreToolUse`/`PostToolUse` vs `BeforeTool`/`AfterTool`). Don't cross-pollinate field names when editing.
- **Skill edits**: keep frontmatter (`name`, `description`) intact — the description is what the agent matches against to decide whether to invoke the skill.
- **No git here** — this directory is not a git repo (per environment). Don't try to commit or run `gh`.
