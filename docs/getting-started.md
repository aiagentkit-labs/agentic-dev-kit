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
<plugin>/scripts/check.sh pre implement
<plugin>/scripts/check.sh pre implement --skip gh
```

It checks git, the `az` CLI with its `azure-devops` extension, `gh` and its sign-in for GitHub repos, `node` for web projects, the .NET SDK for .NET projects, and your working tree. On Windows, use `check.ps1`.

To install anything missing, run `scripts/install.sh` (macOS through Homebrew; Linux prints the commands) or `scripts/install.ps1` (Windows through winget). Both show what they'll run and ask first.

If a tool works in your terminal but the check says it won't run, VS Code is still using the PATH it read at launch. Quit and reopen VS Code.

## Sign in

The plugin contains no credentials; everyone signs in with their own account.

- **Azure DevOps MCP server**: VS Code prompts for a Microsoft Entra sign-in the first time a tool is used. Your Azure DevOps organization must be backed by Microsoft Entra ID.
- **Fallback**: if the Azure DevOps MCP server can't sign in, `implement` switches to the `az` CLI, using `az login` or a personal access token you export as `AZURE_DEVOPS_EXT_PAT`. For Jira or another tracker, use an available adapter; without one, paste or export its task text.
- **GitHub-hosted code**: pull requests are opened with the `gh` CLI, signed in with `gh auth login`.

For tracker discovery, `implement` inspects MCP tools exposed to the current chat, maps only operations those tools actually provide, then verifies access with a read-only fetch of the supplied issue. An issue URL by itself is not a connection. This plugin bundles the Azure DevOps MCP server in `mcp.json`, not a Jira server. To use Jira, configure and enable a Jira MCP server in VS Code (or add an adapter to the plugin); it can then use those tools if they are exposed to the active chat. If no Jira tools are available, paste or export the issue text instead.

## Your first run

Start with any task source and an interview mode:

```text
/implement https://dev.azure.com/<org>/<project>/_workitems/edit/<id> teach
```

Other examples:

```text
/implement Jira issue PROJ-123 grill
/implement path/to/task.md grill
/implement "Add CSV export to the reports page. Users can choose the columns and date range."
```

The Jira example requires a Jira MCP/CLI adapter; a Jira URL alone does not provide access. If none is configured, export or paste the issue text instead. The skill can offer to save the agreed task as `work-items/<slug>.md`; see [task record format](../skills/implement/TASK-RECORD.md). A repository policy may still require a linked tracker issue before merge.

For a pasted request, use `/implement` followed by the task text. For a local file, use `/implement path/to/task.md`. `/ado-implement` remains available as the ADO-specific compatibility command.

**Grill** mode asks the decisions; **teach** mode also explains why and checks your recall. See [Workflows](workflows.md) for every step.
