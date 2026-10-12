---
name: lint
description: Run, fix, and set up linters and formatters for .NET (C#) and TypeScript/JavaScript through an interview. Use when the user mentions linting, formatting, ESLint, Prettier, Biome, dotnet format, analyzers, or .editorconfig, or before committing .NET or TS/JS changes.
---

Make the files the user touched pass the repo's linters and formatters, and set those tools up where the repo has none. The repo's config and scripts are the rules: this skill runs them and leaves their choices alone unless the user decides otherwise at a gate.

- **On its own** (`/lint`): use the interview mode from [ado-implement step 0](../ado-implement/SKILL.md#0-pick-the-interview-mode), with each gate a round in the format of [ado-implement's Rounds](../ado-implement/SKILL.md#rounds). Open each gate with `Lint · Step N · Round k`.
- **Inside another skill** (`ado-implement`, `pr-review`): use that skill's mode, and fold this skill's gates into its current round.

**Scope** is the touched files: changed against the base branch (`git diff --name-only --diff-filter=d origin/<base>...HEAD`) plus uncommitted ones (`git status --porcelain`). Lint the whole repo only when the user asks, and land a whole-repo reformat as its own PR, so it never buries a feature's diff.

## 1. Detect

For each stack in the repo, find its tools and the commands the repo already uses:

| | TypeScript / JavaScript | .NET |
|---|---|---|
| Stack | `package.json`, `tsconfig*.json` | `*.sln`, `*.slnx`, `*.csproj`, `Directory.Build.props` |
| Linter | `eslint.config.*`, `.eslintrc*`, `eslintConfig` in `package.json`, `biome.json(c)` | `AnalysisLevel` / `EnforceCodeStyleInBuild` in `Directory.Build.props` or project files, `dotnet_diagnostic.*` in `.editorconfig` or `.globalconfig`, analyzer packages (`StyleCop.Analyzers`, …) |
| Formatter | `.prettierrc*`, `prettier` in `package.json`, `biome.json(c)` | `.editorconfig` |
| Commands | `package.json` scripts (`lint`, `format`, `check`), lint-staged or husky hooks, CI workflows | CI workflows, build scripts |

Take the package manager from the lockfile (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`). Confirm the tools run: `node --version` and `npx --version`, or `dotnet --version` (`dotnet format` ships with the .NET 6+ SDK).

Done when each stack has a check command and a fix command for its linter and its formatter, taken from the repo, or is marked **none**.

## 2. Set up

Only for pieces marked **none**.

**Gate**: for each missing piece, the baseline from [SETUP.md](SETUP.md): files to add, packages to install, scripts to define, and the options it lists. The user can decline a piece; it stays **none** and goes in the report.

After installing, run the new check once over the whole repo and report the count. When existing code produces many findings, recommend landing the setup as its own PR before the feature work, or the gentler starting level that SETUP.md names.

Done when every **none** piece is set up or declined.

## 3. Check

Run each check command on the scope. Where the repo has config but no script, use:

- **ESLint**: `npx eslint <files>`. **Prettier**: `npx prettier --check <files>`. **Biome**: `npx biome check <files>`.
- **TypeScript**: `npx tsc --noEmit -p <tsconfig>` over the whole project, since types cross files, unless a script already covers it.
- **.NET**: `dotnet format <solution-or-project> --verify-no-changes --include <files>` (whitespace, code style, and analyzers; non-zero exit when anything would change). Then `dotnet build <solution-or-project>` and keep the warnings in touched files, since some analyzers report only during a build.

Sort every finding into one group:

- **Auto-fixable**: the fix command resolves it.
- **Code change**: needs an edit by hand.
- **Rule question**: the rule looks wrong for this code, so it's the user's call.

Done when every finding in scope is in a group.

## 4. Fix

**Gate**: the count in each group, the auto-fixes to apply, the code changes you propose, and one question per rule question.

- **Auto-fixes**: run the fix commands on the scope: `npx eslint --fix <files>`, `npx prettier --write <files>`, `npx biome check --write <files>`, `dotnet format <solution-or-project> --include <files>`.
- **Code changes**: edit by hand, then rerun the tests that cover the edit.
- **Rule questions**: on the user's yes, suppress at the narrowest scope with the reason in the code: `// eslint-disable-next-line <rule> -- <reason>`, `// biome-ignore <rule>: <reason>`, a `#pragma warning disable <ID> // <reason>` and `restore` pair, or `[SuppressMessage("<category>", "<ID>", Justification = "<reason>")]`. Changing a rule's severity in config affects the whole repo, so ask it as a separate question.

Rerun step 3 after each batch. Done when every check command exits 0 on the scope.

## 5. Report

A table per stack: each command, its result, and the counts fixed and suppressed, plus any piece left **none**. Offer to add missing check commands to CI, as a local edit on the user's yes.

In teach mode, link each rule you fixed or suppressed to its documentation: `https://eslint.org/docs/latest/rules/<rule>`, `https://typescript-eslint.io/rules/<rule>`, `https://biomejs.dev/linter/rules/<rule>`, `https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/<caXXXX>` for CA rules, and `…/code-analysis/style-rules/<ideXXXX>` for IDE rules.
