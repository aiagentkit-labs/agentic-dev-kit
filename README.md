# agentic-dev-kit

An [Agent Plugin](https://agent-plugins.org/) that bundles skills for planning and shipping work with AI coding agents.

**Documentation, with animated workflows: [aiagentkit-labs.github.io/agentic-dev-kit](https://aiagentkit-labs.github.io/agentic-dev-kit/)**

| Skill | What it does | Invocation |
|---|---|---|
| `implement` | Takes a task from ADO, Jira, pasted text, or a local file to a tested pull request; tracker writes are optional | Automatic for implementation requests, or `/implement` |
| `ado-implement` | Compatibility entry point for existing Azure DevOps workflows; forwards to `implement` | Automatic when you mention ADO / Azure Boards, or `/ado-implement` |
| `pr` | Writes a PR body: summary visual, before/after evidence, merge danger | Automatic when writing a PR body, or `/pr` |
| `pr-review` | Interview-driven PR review, from either side: address the comments on your PR until every thread is settled, or review someone else's PR and post comments and a vote | Automatic when you mention PR comments or reviewing a PR, or `/pr-review` |
| `branch-policies` | Reads and sets branch policies on Azure Repos or GitHub with a **team** or **solo** profile; solo relaxes only who approves, for developers with no one to approve their PRs | Automatic when you mention branch policies or working alone, or `/branch-policies` |
| `lint` | Runs and fixes the repo's linters and formatters on the files you touched, for .NET (`dotnet format`, analyzers, `.editorconfig`) and TypeScript/JavaScript (ESLint, Prettier, Biome), and sets up a baseline where a repo has none | Automatic when you mention linting or formatting, before commits in `implement` and `pr-review`, or `/lint` |
| `spec-kit` | Helps set up GitHub Spec Kit for Spec-Driven Development and hands selected feature artifacts to `implement` | Automatic when you mention Spec Kit, SDD, or `/speckit-*`, or `/spec-kit` |
| `grilling` | Stress-tests a plan or decision, one round of questions at a time | Automatic on "grill" phrases, or `/grilling` |
| `grill-me` | A relentless interview to sharpen a plan or design | `/grill-me` |
| `teach` | Teaches a new concept using your project as context; `setup <topic>` initializes a learning workspace after approval | `/teach`, `/teach setup <topic>` |

| Agent | What it does | Invocation |
|---|---|---|
| `PR Reviewer` | Read-only review of a branch or PR against its spec, test layers, and repo standards; returns a findings table | Subagent of `implement` and `pr-review` |
| `Security Reviewer` | Read-only review against [security controls](review-controls/security.md) plus your organization's | Subagent, in parallel with `PR Reviewer` |
| `Privacy Reviewer` | Read-only data-flow review against [privacy controls](review-controls/privacy.md) plus your organization's | Subagent, in parallel with `PR Reviewer` |
| `Lint Runner` | Runs the repo's linters, formatters, and type checks in check mode and returns findings grouped as auto-fix, code change, or rule question, keeping long lint output out of your chat | Subagent of `lint` |

It connects the [hosted Azure DevOps MCP server](https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server) for work items, iterations, and repositories, and Atlassian's hosted Rovo MCP server for Jira and other Atlassian apps. Users authenticate with their own accounts. `implement` can also start from pasted text or a local task file; other trackers need an available MCP/CLI adapter, otherwise paste or export their task text.

## The `implement` flow

```text
pick interview mode   grill (decisions) or teach (decisions + why + recall)
  select source       tracker URL/ID, pasted text, or local file
  load task           connected adapter, or read supplied text/file
  assess task         quality check, normalize acceptance criteria
  settle scope        acceptance checklist, small-PR split
  branch              off the base branch you choose, freshly fetched
  implement           red -> green: unit, accessibility (axe), UI (Playwright); lint touched files
  commit              drafted from the task; include source key when supported
  review              PR Reviewer subagent (read-only) -> findings -> fixes
  pull request        body via `pr`, pushed and linked on your yes
  hand back           evidence per criterion, optional task-file/tracker update
```

After the PR opens, `pr-review` takes over:

```text
author     collect open threads -> triage (fix / answer / push back / defer)
           -> fix test-first -> reply + resolve -> repeat until all settled
reviewer   pick PR -> check out head -> PR Reviewer subagent -> verify findings
           -> choose what to post + vote -> post on your yes -> re-review later
```

Each step ends at a gate where you decide; nothing is pushed or written to a tracker or shared host without your yes. Jira access requires Atlassian sign-in and permission to the issue.

Start with a task source and the interview mode, and let the skill drive:

```text
/implement https://dev.azure.com/<org>/<project>/_workitems/edit/<id> teach
```

You can also start with pasted task text, a local Markdown/text file path, or a Jira URL/key after Atlassian sign-in. `/ado-implement` remains available as an Azure Boards compatibility alias. Accepted tasks can optionally be saved in `work-items/<slug>.md` using [TASK-RECORD.md](skills/implement/TASK-RECORD.md).

Anything else you add (for example "one question at a time") overrides the skill's defaults for pace. The steps and gates still apply. Best practices (clear task criteria, small PRs, branch and commit hygiene) are checked along the way: see [PRACTICES.md](skills/ado-implement/PRACTICES.md) and [TESTING.md](skills/ado-implement/TESTING.md). Accepted tasks can optionally be saved as Markdown in `work-items/<slug>.md`; see [TASK-RECORD.md](skills/implement/TASK-RECORD.md).

## Install

**VS Code (GitHub Copilot)**: run **Chat: Install Plugin From Source** and enter `https://github.com/aiagentkit-labs/agentic-dev-kit`.

**Recommend it to everyone working in a repo**: add `.github/copilot/settings.json` to that repo:

```json
{
  "extraKnownMarketplaces": {
    "agentic-dev-kit": {
      "source": { "source": "github", "repo": "aiagentkit-labs/agentic-dev-kit" }
    }
  },
  "enabledPlugins": {
    "agentic-dev-kit@agentic-dev-kit": true
  }
}
```

VS Code then offers to install it the first time someone sends a chat message in that repo.

## Tailoring the controls

Every rule the kit applies is a **control** with an ID: security (`SEC-03`), privacy (`PRV-03`), testing and accessibility (`TST-01`, `A11Y-02`, `UI-05`), practices (`WI-03`, `PR-01`, `CM-04`), and lint (`LINT-04`, and the baselines it sets up). Each topic has a plugin default that a repo tailors with a file at the same path under `.github/`:

| Topic | Default | Repo override |
|---|---|---|
| Security, privacy | [review-controls/](review-controls/) | `.github/review-controls/security.md`, `privacy.md` |
| Testing, accessibility, UI tests | [testing-controls/testing.md](testing-controls/testing.md) | `.github/testing-controls/testing.md` |
| Task traceability, branches, commits, PRs | [practice-controls/practices.md](practice-controls/practices.md) | `.github/practice-controls/practices.md` |
| Lint and format | [lint-controls/lint.md](lint-controls/lint.md) | `.github/lint-controls/lint.md` |

- **Add, replace, or turn off** a control by ID; turning one off takes a reason. Or set `mode: replace` to swap the whole default for your own.
- **Share across repos**: `extends: <git URL>#<ref>:<path>` pulls an organization's version first, fetched with your own git credentials.
- **Add guidance**: an `## Instructions` section the agents follow for that topic.
- **Can't be loosened by the change under review**: overrides are read from the base branch. Turned-off controls are listed at every gate and review, and security or privacy ones in every PR.

The full format is in [CONTROLS.md](CONTROLS.md). Security and privacy files also take `## Scanners` (read-only commands that run after you approve each one) and `## Escalation` (teams added as required PR reviewers). For internal read-only tools, such as a data-classification MCP server, add them to the `tools` list in [security-reviewer.agent.md](com.github.copilot/agents/security-reviewer.agent.md) or [privacy-reviewer.agent.md](com.github.copilot/agents/privacy-reviewer.agent.md).

## Setup

The skills check their own prerequisites: a **preflight** before each run (git version, `gh` and its sign-in for GitHub PRs, `node` for web projects, the .NET SDK for .NET projects, working-tree state; `az` is checked by the ADO compatibility path) and a **postflight** after (working tree, stash, branch/push state, temp files cleaned). Run them yourself from a repo:

```bash
<plugin>/scripts/check.sh pre implement         # or: pr-review
<plugin>/scripts/check.sh pre implement --skip gh   # skip checks you'll fix later: git, az, gh, node, dotnet
<plugin>/scripts/check.sh post implement
```

Install anything missing with [`scripts/install.sh`](scripts/install.sh) (macOS via Homebrew; Linux prints the commands) or [`scripts/install.ps1`](scripts/install.ps1) (Windows via winget). Both show what they'll run and ask first; sign-ins (`az login`, `gh auth login`) stay with you.

If a tool works in your terminal but the check says it won't run, VS Code is still using the PATH it read at launch. Quit and reopen VS Code after changing your shell profile.

## Guardrails

The skills' instructions and the check scripts guide the agent; they don't stop it. Three layers do:

1. **Read-only reviewer agents**: the PR, Security, and Privacy reviewers are given only read and search tools.
2. **A PreToolUse hook** ([`com.github.copilot/hooks/hooks.json`](com.github.copilot/hooks/hooks.json) running [`scripts/guardrails.sh`](scripts/guardrails.sh), or [`guardrails.ps1`](scripts/guardrails.ps1) on Windows), checked by the client before every tool call while the plugin is enabled:
   - **Denies**: `git push --force` / `-f` / `+refspec`, direct pushes to `main`, `master`, `develop`, `release/*`, `git reset --hard`, `git clean -f`, `git branch -D`, `git checkout .` / `git restore .`, `git stash drop|clear`, `--no-verify`, and bypassing branch policies.
   - **Asks**: any other `git push` (including `--force-with-lease`), `gh pr` writes, `gh api` writes and GraphQL mutations, `az repos pr` / `az boards` writes, `az devops invoke` writes, every Azure DevOps MCP write tool, and recursive deletes outside `.git/agentic-dev-kit/`.
   - Hooks are in preview in VS Code: enable `chat.useHooks` and trust the workspace. In Claude Code, register `scripts/guardrails.sh` as a `PreToolUse` hook in your settings.
   - The hook finds the script through the client's plugin-root variable, else the default install folders under `~/.vscode`, `~/.vscode-insiders`, and `~/.copilot`. If it finds none, it lets tool calls through and prints a warning, because Copilot denies every tool call when a `PreToolUse` hook errors.
   - To add your own rules without editing the plugin, use `.github/guardrails/guardrails.yaml` in your repo; see the [guardrails docs](docs/guardrails.md). Your rules can only tighten the built-in ones. To change the built-in rules, edit the script and run [`scripts/guardrails.test.sh`](scripts/guardrails.test.sh).
3. **Your repository's own policies**, the only layer that holds when everything else fails. Recommended:
  - **Azure Repos** branch policies on the default branch: require a PR with at least one reviewer, block authors approving their own changes, require a linked work item if that policy is enabled (a local task record alone won't satisfy it), require comment resolution, require build validation, and add automatic reviewers for security- and privacy-sensitive paths.
   - **GitHub**: a ruleset with the same rules, `CODEOWNERS`, and secret scanning with push protection.
   - **Least privilege**: personal access tokens or Entra app scopes limited to Work Items and Code; set `X-MCP-Readonly: true` in `mcp.json` for anyone who only reads.
  - **Working solo**: keep every rule above except the approver: on Azure Repos, 1 approver with the author's own vote counting; on GitHub, 0 required approvals. The `branch-policies` skill applies this, and `implement` then posts the AI reviewers' findings on each PR as its review record.

## Authentication

The plugin contains no credentials. Each user signs in with their own account:

- **Azure DevOps MCP server**: your client prompts for a Microsoft Entra sign-in the first time a tool is used. Your Azure DevOps organization must be backed by Microsoft Entra ID.
- **Azure DevOps**: if its MCP server can't authenticate, `implement` switches to the `az` CLI (`az boards`, `az repos`), using `az login` or a personal access token you export as `AZURE_DEVOPS_EXT_PAT` in your own terminal.
- **Jira / Atlassian**: the plugin configures Atlassian's hosted Rovo MCP server. VS Code prompts you to authorize Atlassian on first use; access is limited by your account's site and project permissions. Some enriched Rovo operations may consume Rovo credits.
- **Other trackers**: use a connected MCP/CLI adapter, or paste/export the task text and optionally save a local task record.
- **GitHub-hosted code**: pull requests are opened with the `gh` CLI, signed in with `gh auth login`.

## Client support

Skills work in any client that supports [Agent Skills](https://agentskills.io/). The hosted Azure DevOps server signs in natively in VS Code, GitHub Copilot CLI, and the GitHub Copilot app. Claude Code and Cursor need a custom Microsoft Entra app registration ([setup guide](https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server#supported-environments)); for ADO, `implement` can fall back to the `az` CLI. Other trackers need a connected MCP/CLI adapter or pasted/exported task text.

## Contributing

Issues and pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). Report bugs and feature ideas through the [issue forms](https://github.com/aiagentkit-labs/agentic-dev-kit/issues/new/choose), and security problems privately through **Security → Report a vulnerability**.

Each skill lives in `skills/<name>/SKILL.md`; the folder name must match the skill's `name`. Custom agents are Copilot-specific, so they live in `com.github.copilot/agents/<name>.agent.md`; other clients ignore that folder, and `implement` falls back to a general subagent that reads the same file. `ado-implement` remains as a legacy ADO entry point. Bump `version` in `plugin.json` with every release so installed copies update.

## License

[MIT](LICENSE). The `pr`, `grilling`, `grill-me`, and `teach` skills come from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT).
