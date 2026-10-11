---
name: ado-implement
description: Implement Azure DevOps (ADO) work items end to end. Use when the user mentions ADO, Azure Boards, a work item / bug / user story ID or "AB#123", or asks to pick up their assigned items.
---

Turn ADO work items into implemented, tested branches. Each item's **acceptance criteria** is its completion criterion: an item is done only when every criterion maps to evidence (a passing test or an observed behaviour).

Reading from ADO is free. **Writing to ADO** (state changes, comments, field edits, links) touches a shared system, so confirm with the user before each write.

## 1. Connect

Use the first channel that works:

1. **Azure DevOps MCP tools** (`core_list_orgs`, `wit_work_item`, …) from this plugin's hosted server. Its endpoint carries no organization, so pass the org on every call. Resolve the org from, in order: the user's message, a `dev.azure.com/<org>` or `<org>.visualstudio.com` git remote, then `core_list_orgs` with the user picking. The client handles the Microsoft Entra sign-in prompt.
2. **`az boards` CLI**, when the MCP tools are absent or can't authenticate (orgs not backed by Entra, or clients that can't complete the Entra flow). Add the extension with `az extension add --name azure-devops` if missing, then `az devops configure --defaults organization=<url> project=<name>`. Auth comes from `az login`, or a PAT the user exports as `AZURE_DEVOPS_EXT_PAT` in their own terminal.

Credentials never pass through chat. Done when one channel returns the org's projects.

## 2. Select items

- IDs given (`123`, `AB#123`): use those.
- Otherwise list the user's open items (MCP: `wit_work_item` action `my`; CLI: WIQL on `[System.AssignedTo] = @Me`, excluding closed states, ordered by priority), show them, and let the user pick. Apply any filter they give: iteration, area path, tag, type.

## 3. Read each item

Fetch the item with its relations and pull: title, type, state, description, acceptance criteria (`Microsoft.VSTS.Common.AcceptanceCriteria`), repro steps for bugs (`Microsoft.VSTS.TCM.ReproSteps`), the parent for context, and children as sub-scope. Fields are HTML; read them as plain text.

## 4. Settle scope

Write the acceptance criteria as a numbered checklist, each entry paired with the check that will prove it. When criteria are missing, vague, or contradict the code, run the `grilling` skill on that item. Facts you can look up (code, config, linked items) are yours to find; decisions are the user's.

Done when every entry has a concrete, verifiable check and the user has confirmed the list.

## 5. Implement

One item per branch, in priority order:

1. Follow the repo's own conventions first: `AGENTS.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, and existing branch and commit history. Absent a convention, branch from an up-to-date default branch as `feat/<id>-<slug>` (story, task, feature) or `fix/<id>-<slug>` (bug).
2. Work test-first where the change is testable, using the repo's existing test framework.
3. Keep the build and tests green for everything you touched; find the commands in the repo (package scripts, solution files, Makefile, CI workflows).
4. Link every commit to the item: `AB#<id>` on GitHub-hosted repos (requires the Azure Boards app), `#<id>` on Azure Repos.

Done when every checklist entry is ticked with its evidence.

## 6. Report and hand back

Per item, report the branch, commits, each acceptance criterion with its evidence, and anything deferred. Then offer the ADO writes (state change, a comment summarising branch and evidence) and run only those the user approves. Pushing and opening a PR also wait for the user's go-ahead.
