# agentic-dev-kit

An [Agent Plugin](https://agent-plugins.org/) that bundles skills for planning and shipping work with AI coding agents.

| Skill | What it does | Invocation |
|---|---|---|
| `ado-implement` | Takes an Azure DevOps work item to a pull request, interviewing you at every gate | Automatic when you mention ADO / work items, or `/ado-implement` |
| `pr` | Writes a PR body: summary visual, before/after evidence, merge danger | Automatic when writing a PR body, or `/pr` |
| `pr-review` | Interview-driven PR review, from either side: address the comments on your PR until every thread is settled, or review someone else's PR and post comments and a vote | Automatic when you mention PR comments or reviewing a PR, or `/pr-review` |
| `grilling` | Stress-tests a plan or decision, one round of questions at a time | Automatic on "grill" phrases, or `/grilling` |
| `grill-me` | A relentless interview to sharpen a plan or design | `/grill-me` |
| `teach` | Teaches a new concept inside your workspace | `/teach` |

| Agent | What it does | Invocation |
|---|---|---|
| `PR Reviewer` | Read-only review of a branch or PR against its spec, test layers, and repo standards; returns a findings table | Subagent of `ado-implement` and `pr-review` |

It also connects the [hosted Azure DevOps MCP server](https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server), limited to work-item, iteration, and repository tools.

## The `ado-implement` flow

```text
pick interview mode   grill (decisions) or teach (decisions + why + recall)
  connect             MCP server, else az CLI
  select item         yours, or by ID
  assess item         descriptive work item check, offer rewrite
  settle scope        acceptance checklist, small-PR split
  branch              off the base branch you choose, freshly fetched
  implement           red -> green: unit, accessibility (axe), UI (Playwright)
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

Each step ends at a gate where you decide; nothing is pushed or written to Azure DevOps without your yes. Best practices (descriptive work items, small PRs, branch and commit hygiene) are checked along the way: see [PRACTICES.md](skills/ado-implement/PRACTICES.md) and [TESTING.md](skills/ado-implement/TESTING.md).

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
- **Fallback**: if the MCP server can't authenticate, `ado-implement` switches to the `az` CLI (`az boards`, `az repos`), using `az login` or a personal access token you export as `AZURE_DEVOPS_EXT_PAT` in your own terminal.
- **GitHub-hosted code**: pull requests are opened with the `gh` CLI, signed in with `gh auth login`.

## Client support

Skills work in any client that supports [Agent Skills](https://agentskills.io/). The hosted Azure DevOps server signs in natively in VS Code, GitHub Copilot CLI, and the GitHub Copilot app. Claude Code and Cursor need a custom Microsoft Entra app registration ([setup guide](https://learn.microsoft.com/azure/devops/mcp-server/remote-mcp-server#supported-environments)); in other clients, `ado-implement` falls back to the `az` CLI.

## Contributing

Each skill lives in `skills/<name>/SKILL.md`; the folder name must match the skill's `name`. Custom agents are Copilot-specific, so they live in `com.github.copilot/agents/<name>.agent.md`; other clients ignore that folder, and `ado-implement` falls back to a general subagent that reads the same file. Bump `version` in `plugin.json` with every release so installed copies update.

## License

[MIT](LICENSE). The `pr`, `grilling`, `grill-me`, and `teach` skills come from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT).
