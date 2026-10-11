# agentic-dev-kit

An [Agent Plugin](https://agent-plugins.org/) that bundles skills for planning and shipping work with AI coding agents.

| Skill | What it does | Invocation |
|---|---|---|
| `ado-implement` | Takes Azure DevOps work items from acceptance criteria to tested branches | Automatic when you mention ADO / work items, or `/ado-implement` |
| `grilling` | Stress-tests a plan or decision, one round of questions at a time | Automatic on "grill" phrases, or `/grilling` |
| `grill-me` | A relentless interview to sharpen a plan or design | `/grill-me` |
| `teach` | Teaches a new concept inside your workspace | `/teach` |

It also connects the [hosted Azure DevOps MCP server](https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server), limited to work-item and iteration tools.

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

## Authentication

The plugin contains no credentials. Each user signs in with their own account:

- **Azure DevOps MCP server**: your client prompts for a Microsoft Entra sign-in the first time a tool is used. Your Azure DevOps organization must be backed by Microsoft Entra ID.
- **Fallback**: if the MCP server can't authenticate, `ado-implement` switches to the `az boards` CLI, using `az login` or a personal access token you export as `AZURE_DEVOPS_EXT_PAT` in your own terminal.

## Client support

Skills work in any client that supports [Agent Skills](https://agentskills.io/). The hosted Azure DevOps server signs in natively in VS Code, GitHub Copilot CLI, and the GitHub Copilot app. Claude Code and Cursor need a custom Microsoft Entra app registration ([setup guide](https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server#supported-environments)); in other clients, `ado-implement` falls back to the `az` CLI.

## Contributing

Each skill lives in `skills/<name>/SKILL.md`; the folder name must match the skill's `name`. Bump `version` in `plugin.json` with every release so installed copies update.

## License

[MIT](LICENSE)
