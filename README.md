# agentic-dev-kit

An [Agent Plugin](https://agent-plugins.org/) that bundles skills for planning and shipping work with AI coding agents.

| Skill | What it does | Invocation |
|---|---|---|
| `ado-implement` | Takes an Azure DevOps work item to a pull request, interviewing you at every gate | Automatic when you mention ADO / work items, or `/ado-implement` |
| `pr` | Writes a PR body: summary visual, before/after evidence, merge danger | Automatic when writing a PR body, or `/pr` |
| `pr-review` | Interview-driven PR review, from either side: address the comments on your PR until every thread is settled, or review someone else's PR and post comments and a vote | Automatic when you mention PR comments or reviewing a PR, or `/pr-review` |
| `branch-policies` | Reads and sets branch policies on Azure Repos or GitHub with a **team** or **solo** profile; solo relaxes only who approves, for developers with no one to approve their PRs | Automatic when you mention branch policies or working alone, or `/branch-policies` |
| `lint` | Runs and fixes the repo's linters and formatters on the files you touched, for .NET (`dotnet format`, analyzers, `.editorconfig`) and TypeScript/JavaScript (ESLint, Prettier, Biome), and sets up a baseline where a repo has none | Automatic when you mention linting or formatting, before commits in `ado-implement` and `pr-review`, or `/lint` |
| `grilling` | Stress-tests a plan or decision, one round of questions at a time | Automatic on "grill" phrases, or `/grilling` |
| `grill-me` | A relentless interview to sharpen a plan or design | `/grill-me` |
| `teach` | Teaches a new concept inside your workspace | `/teach` |

| Agent | What it does | Invocation |
|---|---|---|
| `PR Reviewer` | Read-only review of a branch or PR against its spec, test layers, and repo standards; returns a findings table | Subagent of `ado-implement` and `pr-review` |
| `Security Reviewer` | Read-only review against [security controls](review-controls/security.md) plus your organization's | Subagent, in parallel with `PR Reviewer` |
| `Privacy Reviewer` | Read-only data-flow review against [privacy controls](review-controls/privacy.md) plus your organization's | Subagent, in parallel with `PR Reviewer` |
| `Lint Runner` | Runs the repo's linters, formatters, and type checks in check mode and returns findings grouped as auto-fix, code change, or rule question, keeping long lint output out of your chat | Subagent of `lint` |

It also connects the [hosted Azure DevOps MCP server](https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server), limited to work-item, iteration, and repository tools.

## The `ado-implement` flow

```text
pick interview mode   grill (decisions) or teach (decisions + why + recall)
  connect             MCP server, else az CLI
  select item         yours, or by ID
  assess item         descriptive work item check, offer rewrite
  settle scope        acceptance checklist, small-PR split
  branch              off the base branch you choose, freshly fetched
  implement           red -> green: unit, accessibility (axe), UI (Playwright); lint touched files
  commit              message drafted from the work item, linked to it
  review              PR Reviewer subagent (read-only) -> findings -> fixes
  pull request        body via `pr`, pushed and linked on your yes
  hand back           evidence per criterion, optional ADO state/comment
```

After the PR opens, `pr-review` takes over:

```text
author     collect open threads -> triage (fix / answer / push back / defer)
           -> fix test-first -> reply + resolve -> repeat until all settled
reviewer   pick PR -> check out head -> PR Reviewer subagent -> verify findings
           -> choose what to post + vote -> post on your yes -> re-review later
```

Each step ends at a gate where you decide; nothing is pushed or written to Azure DevOps without your yes.

Start with just the item and the mode, and let the skill drive:

```text
/ado-implement https://dev.azure.com/<org>/<project>/_workitems/edit/<id> teach
```

Anything else you add (for example "one question at a time") overrides the skill's defaults for pace. The steps and gates still apply. Best practices (descriptive work items, small PRs, branch and commit hygiene) are checked along the way: see [PRACTICES.md](skills/ado-implement/PRACTICES.md) and [TESTING.md](skills/ado-implement/TESTING.md).

## Install

**VS Code (GitHub Copilot)**: run **Chat: Install Plugin From Source** and enter `https://github.com/puttagunta/agentic-dev-kit`.

**Recommend it to everyone working in a repo**: add `.github/copilot/settings.json` to that repo:

```json
{
  "extraKnownMarketplaces": {
    "agentic-dev-kit": {
      "source": { "source": "github", "repo": "puttagunta/agentic-dev-kit" }
    }
  },
  "enabledPlugins": {
    "agentic-dev-kit@agentic-dev-kit": true
  }
}
```

VS Code then offers to install it the first time someone sends a chat message in that repo.

## Your organization's security and privacy controls

The Security and Privacy reviewers apply a baseline ([security](review-controls/security.md), [privacy](review-controls/privacy.md)) that every company will want to tailor. Three extension points, from lightest to heaviest:

1. **Per repo**: add `.github/review-controls/security.md` or `privacy.md` in the same format as the baseline. Your controls add to the baseline; reusing a baseline ID (`SEC-03`) replaces it. These files are always read from the target branch, so a PR can't rewrite the controls it's checked against.
2. **Scanners and sign-off**: list read-only scanner commands under `## Scanners` (they run only after you approve each command) and the teams that sign off on `escalate` findings under `## Escalation` (added as required PR reviewers).
3. **Org-wide**: fork this plugin and edit the baseline, or add your internal read-only tools (for example a data-classification MCP server) to the `tools` list in [security-reviewer.agent.md](com.github.copilot/agents/security-reviewer.agent.md) or [privacy-reviewer.agent.md](com.github.copilot/agents/privacy-reviewer.agent.md).

## Setup

The skills check their own prerequisites: a **preflight** before each run (git version, `az` + `azure-devops` extension, `gh` and its sign-in for GitHub repos, `node` for web projects, the .NET SDK for .NET projects, working-tree state) and a **postflight** after (working tree, stash, starting branch restored, branch pushed, temp files cleaned). Run them yourself from a repo:

```bash
<plugin>/scripts/check.sh pre ado-implement     # or: pr-review
<plugin>/scripts/check.sh pre ado-implement --skip gh   # skip checks you'll fix later: git, az, gh, node, dotnet
<plugin>/scripts/check.sh post ado-implement
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
   - To change the rules, edit the script and run [`scripts/guardrails.test.sh`](scripts/guardrails.test.sh).
3. **Your repository's own policies**, the only layer that holds when everything else fails. Recommended:
   - **Azure Repos** branch policies on the default branch: require a PR with at least one reviewer, block authors approving their own changes, require linked work items, require comment resolution, require build validation, and add automatic reviewers for security- and privacy-sensitive paths.
   - **GitHub**: a ruleset with the same rules, `CODEOWNERS`, and secret scanning with push protection.
   - **Least privilege**: personal access tokens or Entra app scopes limited to Work Items and Code; set `X-MCP-Readonly: true` in `mcp.json` for anyone who only reads.
   - **Working solo**: keep every rule above except the approver: on Azure Repos, 1 approver with the author's own vote counting; on GitHub, 0 required approvals. The `branch-policies` skill applies this, and `ado-implement` then posts the AI reviewers' findings on each PR as its review record.

## Authentication

The plugin contains no credentials. Each user signs in with their own account:

- **Azure DevOps MCP server**: your client prompts for a Microsoft Entra sign-in the first time a tool is used. Your Azure DevOps organization must be backed by Microsoft Entra ID.
- **Fallback**: if the MCP server can't authenticate, `ado-implement` switches to the `az` CLI (`az boards`, `az repos`), using `az login` or a personal access token you export as `AZURE_DEVOPS_EXT_PAT` in your own terminal.
- **GitHub-hosted code**: pull requests are opened with the `gh` CLI, signed in with `gh auth login`.

## Client support

Skills work in any client that supports [Agent Skills](https://agentskills.io/). The hosted Azure DevOps server signs in natively in VS Code, GitHub Copilot CLI, and the GitHub Copilot app. Claude Code and Cursor need a custom Microsoft Entra app registration ([setup guide](https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server#supported-environments)); in other clients, `ado-implement` falls back to the `az` CLI.

## Contributing

Each skill lives in `skills/<name>/SKILL.md`; the folder name must match the skill's `name`. Custom agents are Copilot-specific, so they live in `com.github.copilot/agents/<name>.agent.md`; other clients ignore that folder, and `ado-implement` falls back to a general subagent that reads the same file. Bump `version` in `plugin.json` with every release so installed copies update.

## License

[MIT](LICENSE). The `pr`, `grilling`, `grill-me`, and `teach` skills come from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT).
