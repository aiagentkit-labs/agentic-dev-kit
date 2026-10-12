---
name: lint
description: Run, fix, and set up linters and formatters for .NET (C#) and TypeScript/JavaScript through an interview. Use when the user mentions linting, formatting, ESLint, Prettier, Biome, dotnet format, analyzers, or .editorconfig, or before committing .NET or TS/JS changes.
---

Make the files the user touched pass the repo's linters and formatters, and set those tools up where the repo has none. The repo's config and scripts are the rules: this skill runs them and leaves their choices alone unless the user decides otherwise at a gate.

- **On its own** (`/lint`): use the interview mode from [ado-implement step 0](../ado-implement/SKILL.md#0-pick-the-interview-mode), with each gate a round in the format of [ado-implement's Rounds](../ado-implement/SKILL.md#rounds). Open each gate with `Lint · Step N · Round k`.
- **Inside another skill** (`ado-implement`, `pr-review`): use that skill's mode, and fold this skill's gates into its current round.

**Scope** is the touched files: changed against the base branch (`git diff --name-only --diff-filter=d origin/<base>...HEAD`) plus uncommitted ones (`git status --porcelain`). Lint the whole repo only when the user asks, and land a whole-repo reformat as its own PR, so it never buries a feature's diff.

## 1. Detect and check

Dispatch the **Lint Runner** subagent with the repo root, the base ref, and the scope's file list. In clients without that agent, dispatch a general subagent whose prompt is the body of [lint-runner](../../com.github.copilot/agents/lint-runner.agent.md), followed by the same inputs. It runs in check mode and returns the repo's tools and commands, anything it couldn't run, and the findings sorted into **auto-fix**, **code change**, and **rule question**. Keeping that output in the subagent keeps long lint logs out of the conversation.

A **Not run** entry is a tool problem: show its error and fix it with the user, installing anything missing on their yes, then dispatch again.

Done when the runner returns with nothing under **Not run**.

## 2. Set up

Only for pieces the runner marked **none**.

**Gate**: for each missing piece, the baseline from [SETUP.md](SETUP.md): files to add, packages to install, scripts to define, and the options it lists. The user can decline a piece; it stays **none** and goes in the report.

After installing, dispatch the runner with the scope **whole repo** and report its counts. When existing code produces many findings, recommend landing the setup as its own PR before the feature work, or the gentler starting level that SETUP.md names.

Done when every **none** piece is set up or declined.

## 3. Fix

**Gate**: the runner's count in each group, the auto-fixes to apply, the code changes you propose, and one question per rule question.

- **Auto-fixes**: run the runner's fix commands on the scope.
- **Code changes**: edit by hand, then rerun the tests that cover the edit.
- **Rule questions**: on the user's yes, suppress at the narrowest scope with the reason in the code: `// eslint-disable-next-line <rule> -- <reason>`, `// biome-ignore <rule>: <reason>`, a `#pragma warning disable <ID> // <reason>` and `restore` pair, or `[SuppressMessage("<category>", "<ID>", Justification = "<reason>")]`. Changing a rule's severity in config affects the whole repo, so ask it as a separate question.

Dispatch the runner again after each batch. Done when it returns **clean**.

## 4. Report

A table per stack: each check command, its result, and the counts fixed and suppressed, plus any piece left **none**. Offer to add missing check commands to CI, as a local edit on the user's yes.

In teach mode, link each rule you fixed or suppressed to its documentation: `https://eslint.org/docs/latest/rules/<rule>`, `https://typescript-eslint.io/rules/<rule>`, `https://biomejs.dev/linter/rules/<rule>`, `https://learn.microsoft.com/dotnet/fundamentals/code-analysis/quality-rules/<caXXXX>` for CA rules, and `…/code-analysis/style-rules/<ideXXXX>` for IDE rules.
