---
name: ado-implement
description: Legacy Azure DevOps entry point for implementing a work item through the provider-neutral implementation workflow. Use when the user mentions ADO, Azure Boards, AB# IDs, or an Azure DevOps work-item URL.
---

# Azure DevOps compatibility entry point

This skill remains installed so existing `/ado-implement` commands and ADO-specific discovery keep working. The canonical workflow is [`implement`](../implement/SKILL.md); follow it for every gate, test, review, PR, and hand-back. Do not use a separate ADO-only process.

When the user provides an ADO URL or `AB#<id>`, use the Azure DevOps connection rules below to load the task, then pass its source metadata and available capabilities into the generic task record. If ADO tools are unavailable, ask the user to paste or export the item text and continue through `implement`'s text/file path. Never claim tracker updates or PR linking unless the connected ADO integration supports them.

## Connect to Azure DevOps

Use the first channel that works:

1. **Azure DevOps MCP tools** (`core_list_orgs`, `wit_work_item`, `repo_pull_request_write`, …) from the hosted server. Pass the organization on every call. Resolve it from the user message, an ADO remote, or ask the user to select from `core_list_orgs`. The client handles Microsoft Entra sign-in.
2. **`az` CLI** if MCP is unavailable or can't authenticate. Configure `az devops configure --defaults organization=<url> project=<name>`. Sign in with `az login`, or a PAT the user exports as `AZURE_DEVOPS_EXT_PAT` in their own terminal.

The ADO integration may read and update work items, create child items, and link PRs only when those capabilities are exposed. Ask before every ADO write as required by [`implement`](../implement/SKILL.md#external-writes).
