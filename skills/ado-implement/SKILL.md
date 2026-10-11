---
name: ado-implement
description: Take Azure DevOps (ADO) work items from backlog to pull request through an interview at every gate. Use when the user mentions ADO, Azure Boards, a work item / bug / user story ID or "AB#123", or asks to pick up their assigned items.
---

Turn an ADO work item into a pull request ready for review: find the item, branch, implement test-first, commit, have it reviewed, and open the PR. The item's **acceptance criteria** is the completion criterion: it is done only when every criterion maps to evidence (a passing test or an observed behaviour).

The user steers through **gates**. Each step below ends at one: present what you found and the decisions it needs as a single interview round, then wait. Facts you can look up (code, config, git, linked items) are yours to find; decisions are the user's.

**Writes to shared systems** (ADO field, state, comment, or link edits; `git push`; creating or updating a PR) each need the user's yes at the moment of the write. Credentials never pass through chat.

At every gate, check the work against [PRACTICES.md](PRACTICES.md) (descriptive work items, small PRs, branches, commits, PRs). When a practice is missed, name it and recommend the fix in that gate's round.

## 0. Pick the interview mode

Ask once, before step 1:

- **Grill**: run every gate as a `grilling` round (call the Skill tool with "grilling"): numbered questions, each with your recommended answer, worded so "yes" accepts it.
- **Teach**: the same rounds, plus for each practice in play a two-line *why*, its primary-source link from [PRACTICES.md](PRACTICES.md) or [TESTING.md](TESTING.md), and one recall question the user answers before the round closes. When a topic deserves more than a gate can hold, suggest the user run `/teach <topic>` afterwards.

The user can switch modes at any gate.

## 1. Connect

Use the first channel that works:

1. **Azure DevOps MCP tools** (`core_list_orgs`, `wit_work_item`, `repo_pull_request_write`, …) from this plugin's hosted server. Its endpoint carries no organization, so pass the org on every call. Resolve the org from, in order: the user's message, a `dev.azure.com/<org>` or `<org>.visualstudio.com` git remote, then `core_list_orgs` with the user picking. The client handles the Microsoft Entra sign-in prompt.
2. **`az` CLI**, when the MCP tools are absent or can't authenticate. Add the extension with `az extension add --name azure-devops` if missing, then `az devops configure --defaults organization=<url> project=<name>`. Auth comes from `az login`, or a PAT the user exports as `AZURE_DEVOPS_EXT_PAT` in their own terminal.

Also note where the code is hosted (Azure Repos or GitHub) from `git remote -v`; it decides commit links and PR creation later.

Done when one channel returns the org's projects.

## 2. Select the item

- IDs given (`123`, `AB#123`): use those.
- Otherwise list the user's open items (MCP: `wit_work_item` action `my`; CLI: WIQL on `[System.AssignedTo] = @Me`, excluding closed states, ordered by priority) and apply any filter they give: iteration, area path, tag, type.

**Gate**: the user picks. One item per branch and PR; several picks run through steps 3–10 one at a time, in priority order.

## 3. Read and assess the item

Fetch the item with its relations: title, type, state, description, acceptance criteria (`Microsoft.VSTS.Common.AcceptanceCriteria`), repro steps for bugs (`Microsoft.VSTS.TCM.ReproSteps`), the parent for context, and children as sub-scope. Fields are HTML; read them as plain text.

Score it against **Descriptive work items** in [PRACTICES.md](PRACTICES.md).

**Gate**: show the score. For each gap, show your drafted replacement text and offer to write it back to the item.

## 4. Settle scope

Write the acceptance criteria as a numbered checklist. Pair each entry with the check that proves it and its test layer from [TESTING.md](TESTING.md). Where criteria are missing, vague, or contradict the code, grill the user on that item until each entry is concrete.

Estimate the diff size. If it breaks the **Small PRs** budget in [PRACTICES.md](PRACTICES.md), propose a split and the child tasks it creates.

**Gate**: the user confirms the checklist and any split. Done when every entry has a concrete, verifiable check.

## 5. Branch

1. Read the repo's conventions: `AGENTS.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, branch policies, and existing branch and commit history.
2. Find candidate base branches: the remote default (`git symbolic-ref refs/remotes/origin/HEAD`), plus any long-lived branches the conventions name (`develop`, `release/*`).
3. **Gate**: the base branch, and the new branch name: the repo's convention, else `feat/<id>-<slug>` (story, task, feature) or `fix/<id>-<slug>` (bug).
4. With uncommitted changes present, ask whether to stash, commit, or stop; keep the user's work intact.
5. `git fetch origin <base>`, then `git switch -c <branch> origin/<base>`.

Done when the new branch is checked out at the tip of the freshly fetched base.

## 6. Implement test-first

Detect the project's stack and existing test tooling.

**Gate**: the test plan: for each checklist entry, the layer(s), the seam, and the test name. Any new framework or package (Playwright, axe) is listed for the user to approve.

Then work **red → green** in vertical slices, one checklist entry at a time: a failing test, the least code that passes it, rerun. Follow [TESTING.md](TESTING.md) for each layer. Keep the build, linter, and tests green for everything you touched, using the commands the repo defines (package scripts, solution files, Makefile, CI workflows).

Done when every checklist entry is ticked with its evidence: the test name and a passing run.

## 7. Commit

Stage only files that belong to this item.

Draft the message from the item, following the repo's convention; absent one, use the **Commits** format in [PRACTICES.md](PRACTICES.md):

```text
feat(<scope>): <imperative summary of the item title>

<why, from the item's description>
<what changed, one line per notable change>

AB#<id>    (GitHub-hosted)   or   #<id>    (Azure Repos)
```

**Gate**: the staged file list and message. Prefer one commit per vertical slice when slices are independently meaningful.

## 8. Review

Dispatch the **PR Reviewer** agent as a subagent. It starts with an empty context and read-only tools, so the prompt carries everything it needs: the item's ID and title, the acceptance checklist with each entry's evidence, the base ref and branch, and the full output of `git diff origin/<base>...HEAD`. In clients without that agent, dispatch a general subagent whose prompt is the body of [pr-reviewer.agent.md](../../com.github.copilot/agents/pr-reviewer.agent.md) followed by the same inputs.

Fix every blocker and should-fix, rerunning the tests each fix touches. Fold each fix into the commit it belongs to (`git commit --fixup <sha>`, then `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash origin/<base>`). Re-dispatch the reviewer while blockers remain.

**Gate**: the findings table, what you fixed, and the nits for the user to accept or skip. Done when the reviewer's verdict is **ready**.

## 9. Open the pull request

Re-measure the diff: `git diff --shortstat origin/<base>...HEAD`. Recommend a split again if it outgrew the budget.

Write the body with the `pr` skill (call the Skill tool with "pr"). Put the screenshots and passing test runs from step 6 in its Evidence section, and append the work item link and the acceptance checklist with each entry's evidence.

**Gate**: title (the item title plus its ID), target branch (the base from step 5), draft or published, reviewers, merge strategy (squash recommended where allowed), auto-complete when policies pass, and the full body. Recommend a draft until the pipeline is green.

On the user's yes, push with `git push -u origin <branch>`, then create the PR:

- **Azure Repos**: MCP `repo_pull_request_write` action `create`, then `wit_work_item_link_write` action `link_to_pull_request`. CLI: `az repos pr create --source-branch <branch> --target-branch <base> --title <title> --description <body> --work-items <id> [--draft true] [--auto-complete true --squash true --delete-source-branch true]`.
- **GitHub**: `gh pr create --base <base> --head <branch> --title <title> --body-file <file> [--draft]`; `AB#<id>` in the body links the item through the Azure Boards app.

Done when the PR URL is returned and the item is linked to it.

## 10. Hand back

Report the branch, commits, PR URL, each acceptance criterion with its evidence, and anything deferred or split off. Then offer the remaining ADO writes (state change, a comment with the PR link and evidence summary) and run only those the user approves. When reviewers comment, the `pr-review` skill works the threads from the author's side. In teach mode, close with a recap of the practices applied and the recall questions the user missed.
