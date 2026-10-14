# Getting started

## Install

In VS Code with GitHub Copilot, run **Chat: Install Plugin From Source** from the Command Palette and enter:

```text
https://github.com/aiagentkit-labs/agentic-dev-kit
```

VS Code clones the repo and keeps it updated: it checks every 24 hours, or when you run **Extensions: Check for Extension Updates**.

### Recommend it to everyone in a repo

Add `.github/copilot/settings.json` to the repo:

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

VS Code then offers to install it the first time someone sends a chat message in that repo. To pin a version instead of following `main`, append a tag to the repo, for example `aiagentkit-labs/agentic-dev-kit#v0.5.0`.

## Turn on the guardrails

The [guardrails](guardrails.md) run as a `PreToolUse` hook. Hooks are in preview in VS Code:

1. Set `chat.useHooks` to `true`.
2. Trust the workspace.

In Claude Code, register `scripts/guardrails.sh` as a `PreToolUse` hook in your settings.

## Check your tools

Each skill checks its own prerequisites before it runs. You can run the same check yourself from your repo:

```bash
<plugin>/scripts/check.sh pre ado-implement
<plugin>/scripts/check.sh pre ado-implement --skip gh
```

It checks git, the `az` CLI with its `azure-devops` extension, `gh` and its sign-in for GitHub repos, `node` for web projects, the .NET SDK for .NET projects, and your working tree. On Windows, use `check.ps1`.

To install anything missing, run `scripts/install.sh` (macOS through Homebrew; Linux prints the commands) or `scripts/install.ps1` (Windows through winget). Both show what they'll run and ask first.

If a tool works in your terminal but the check says it won't run, VS Code is still using the PATH it read at launch. Quit and reopen VS Code.

## Sign in

The plugin contains no credentials; everyone signs in with their own account.

- **Azure DevOps MCP server**: VS Code prompts for a Microsoft Entra sign-in the first time a tool is used. Your Azure DevOps organization must be backed by Microsoft Entra ID.
- **Fallback**: if the MCP server can't sign in, `ado-implement` switches to the `az` CLI, using `az login` or a personal access token you export as `AZURE_DEVOPS_EXT_PAT`.
- **GitHub-hosted code**: pull requests are opened with the `gh` CLI, signed in with `gh auth login`.

## Your first run

Start with a work item and an interview mode, and let the skill drive:

```text
/ado-implement https://dev.azure.com/<org>/<project>/_workitems/edit/<id> teach
```

**Grill** mode asks the decisions; **teach** mode also explains why and checks your recall. See [Workflows](workflows.md) for every step.
