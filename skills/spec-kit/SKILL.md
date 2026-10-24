---
name: spec-kit
description: Help adopt GitHub Spec Kit for Spec-Driven Development (SDD), initialize it for an AI agent, and hand its feature artifacts to implement. Use when users mention GitHub Spec Kit, specify CLI, /speckit-* skills, or setting up SDD in a repository.
argument-hint: "Set up GitHub Spec Kit or explain an existing Spec Kit workflow"
---

Help the user adopt GitHub's Spec Kit in their project. This skill is an onboarding and handoff layer; it does not bundle, install, or replace the Spec Kit CLI, generated skills, templates, or workflows.

## Ownership and sources

- Spec Kit is maintained at [github/spec-kit](https://github.com/github/spec-kit) and its authoritative documentation is [github.github.io/spec-kit](https://github.github.io/spec-kit/).
- `specify` generates and manages the project's Spec Kit files and `/speckit-*` skills. Do not copy, recreate, hand-edit, or claim ownership of those generated files.
- Use the current official docs and the installed CLI's `--help` output for command syntax. Spec Kit evolves; do not assume an older command, artifact layout, or integration name is still current.
- Keep all initialization and generated artifacts in the user's target project, not in this plugin.

## Set up Spec Kit

1. Confirm the target repository/workspace and whether the user wants to initialize Spec Kit there or only learn how an existing setup works. Do not assume the plugin repository is the target project.
2. Inspect prerequisites using available read-only commands and the official installation guide. Spec Kit documents Python 3.11+ and `uv` as prerequisites. Check `python3 --version`, `uv --version`, and `specify --help`/`specify version` if available; report missing tools explicitly.
3. If `specify` is missing, explain that the official CLI is separately installed, for example with `uv tool install specify-cli`. Show the install command and ask before running it.
4. Ask which supported agent integration to initialize. Recommend `copilot` only when the user is using GitHub Copilot; verify current integration keys and init options with `specify init --help` or official docs.
5. Before initialization, show the exact command and target directory. `specify init` writes project files, so ask for approval before running it. Never run it against a non-empty project without checking what it would create or overwrite.
6. After initialization, inspect the CLI output and generated file list. Report the generated skill names and how to invoke them, without modifying those files. If verification fails, report the error and stop rather than claiming setup succeeded.

Official starting points:

- [Spec Kit installation](https://github.github.io/spec-kit/installation.html)
- [Spec Kit quickstart](https://github.github.io/spec-kit/quickstart.html)
- [GitHub Copilot integration](https://github.github.io/spec-kit/integrations/copilot.html)
- [Spec Kit workflow reference](https://github.github.io/spec-kit/reference/overview.html)

## Explain the workflow

Describe the current workflow from the official reference instead of presenting a stale command list as authoritative. The core flow is generally to establish project principles, specify a feature, plan it, break it into tasks, implement, and converge; optional clarification, checklist, and analysis steps provide quality gates. Link the relevant official reference and let the CLI's installed version determine the actual skill names and syntax.

Spec Kit also has optional processes/extensions beyond feature development. Do not enable them unless the user asks and confirms the choice.

## Hand off to `implement`

When the user wants the feature delivered as a tested pull request, offer to hand the active Spec Kit feature to [`implement`](../implement/SKILL.md):

1. Ask for the active feature directory or the specific Spec Kit artifacts to use. Do not guess which feature is active or scan unrelated feature folders.
2. Read the selected feature's specification, plan, task list, and any relevant project constitution, using the paths and artifact names present in that repository.
3. Summarize the requested outcome and derive testable acceptance criteria. Treat the selected specification as task context, not as permission to change files or skip `implement`'s interview, controls, branch, test, review, and PR gates.
4. Start or continue `implement` with the selected artifacts as its local-file/task source. Preserve the source paths for traceability. Keep Spec Kit artifacts read-only unless the user explicitly requests their update.
5. Do not mark Spec Kit tasks complete based only on checkboxes; `implement` must verify every agreed criterion with evidence.

If the user only asks a question about SDD or Spec Kit, answer conversationally with official links. Do not initialize a project or create learning files unless asked.
