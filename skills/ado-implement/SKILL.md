---
name: ado-implement
description: Take Azure DevOps (ADO) work items from backlog to pull request through an interview at every gate. Use when the user mentions ADO, Azure Boards, a work item / bug / user story ID or "AB#123", or asks to pick up their assigned items.
---

Turn an ADO work item into a pull request ready for review: find the item, branch, implement test-first, commit, have it reviewed, and open the PR. The item's **acceptance criteria** is the completion criterion: it is done only when every criterion maps to evidence (a passing test or an observed behaviour).

The user steers through **gates**. Each step below ends at one: present what you found and the decisions it needs as one interview **round** (see [Rounds](#rounds)), then wait. Facts you can look up (code, config, git, linked items) are yours to find; decisions are the user's. These steps are your plan: track progress by them, and open every gate with `Step N/10 · <step name> · Round k`.

**Writes to shared systems** (ADO field, state, comment, or link edits; `git push`; creating or updating a PR) each need the user's yes at the moment of the write. Credentials never pass through chat. Write every temporary file (PR body, JSON payloads) under `.git/agentic-dev-kit/tmp/`.

**Controls** are the rules this run applies: plugin defaults that the repo can tailor ([CONTROLS.md](../../CONTROLS.md)). After preflight, `git fetch origin` and read the merged `practices`, `testing`, and `lint` controls with [controls.sh](../../scripts/controls.sh) `<topic> --ref origin/<default branch>`; read them again from `origin/<base>` if step 5 picks a different base. List every control the repo turned off, with its reason, in the first round. At every gate, check the work against the practices controls ([PRACTICES.md](PRACTICES.md) has the why and how). When one is missed, name its ID and recommend the fix in that gate's round.

## Preflight

From the user's repo root, run [check.sh](../../scripts/check.sh) by its absolute path: `check.sh pre ado-implement` (Windows: `check.ps1 -Phase pre -Skill ado-implement`). Show its table to the user. A `WARN` is mentioned and the run continues.

A `FAIL` pauses the run. Ask one round with a question per failing check, offering two answers:

- **Fix it**: show the fix and rerun the check. For missing tools, point the user at [install.sh](../../scripts/install.sh) or [install.ps1](../../scripts/install.ps1) to run in their own terminal, since installs and sign-ins can prompt for admin rights or credentials.
- **Skip it**: rerun with `--skip <ids>` (Windows: `-SkipChecks <ids>`), where the ids are `git`, `az`, `gh`, `node`, or `dotnet`, comma-separated. The check then reads `SKIP`. Say what the skip costs before the user picks it: for example, without `gh` the run can't open a GitHub PR at step 9.

Recommend the fix when it's quick, else the skip when the check isn't needed until a later step. Before the step that needs a skipped tool, rerun its check without the skip, and pause there if it still fails.

Done when the table is on screen with no `FAIL`. The matching postflight runs at the end of step 10.

## Rounds

Every gate is a round in this format, the `grilling` skill's, written out here so it holds whether or not that skill loads:

- Ask the whole **frontier**: every open decision whose prerequisites are settled, numbered. A question that depends on another open one waits for the next round.
- Each question carries your recommended answer, worded so "yes" accepts it.
- If the user asks for a different pace, such as one question at a time, follow it. The steps and gates stay.

**Ask in the same turn.** A round written as a chat message ends your turn, so the user has to send a new message to answer it, and the run stalls between gates. When the client has a question tool (VS Code: `askQuestions`; Claude Code: `AskUserQuestion`), ask every round through it instead. The answers come back to you as the tool's result, and you carry on to the next round or step in the same turn.

- Write what the gate needs the user to read (the preflight table, the scorecard, the draft, the diff summary) as chat text first, then call the tool.
- Each ❓ becomes one question: header `Q<n> - <title>`, the lettered options as options with your recommended one marked recommended (for a yes/no decision, the options are the recommended answer and its alternative), and the 📘 line in the question's message.
- Leave free-form input on, so the user can answer "no, because …".
- If the tool caps how many questions one call holds, ask the frontier over consecutive calls.

Use the chat layout below only when there is no question tool, or the user asks for it.

```markdown
**Step 4/10 · Settle scope · Round 1**

❓ **Q1 - <title>**: <question, with lettered options when there are any>

➡️ <recommended answer>

📘 **Why:** <two lines> · **Source:** <link> · **Check:** <recall question>

---

❓ **Q2 - <title>**: …

Reply per question, for example: `1 yes · 2 b · 3 no, because …`
```

The 📘 line is **teach** mode only, and every teach-mode question carries all three parts: Why, Source, and Check. Its source is about *that* decision: the docs for the technology or practice in question, not a general process page. Mark the recall answers at the start of the next round, and correct any misses in a line each.

In chat, use this layout verbatim, emoji included: the user scans for ❓ and ➡️ and replies by number. When the user's own message sets a pace (for example "one question at a time"), say once in the first round that you're following it and how many open questions remain, so they can switch back to the full frontier.

## 0. Pick the interview mode

Ask once, through the question tool when there is one, unless the user's message already names it:

- **Grill**: rounds as above.
- **Teach**: rounds with the 📘 line on every question. When a topic deserves more than a round can hold, suggest the user run `/teach <topic>` afterwards.

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

Score it against the work-item controls (`WI-*`). Then draft the item as it should read: title, description, and acceptance criteria as numbered Given / When / Then. Fill each gap with your recommended default, and mark every default as an **assumption**.

**Gate**: this gate always runs, even when the user asks to go straight to scope questions, because the draft is what those questions refine. Show a scorecard (field, ready or not, gap), the full draft, and a round whose frontier is the draft's assumptions. Done when the user has accepted or amended every assumption. Then offer to write the agreed draft back to the item.

## 4. Settle scope

Turn the agreed criteria into a numbered checklist. Pair each entry with the check that proves it and its test layer under the testing controls ([TESTING.md](TESTING.md) shows how). Run further rounds on anything still open, or anything that contradicts the code.

Estimate the diff size. If it breaks the size control (`PR-01`), propose a split and the child tasks it creates.

**Gate**: the user confirms the checklist and any split. Done when every entry has a concrete, verifiable check.

## 5. Branch

1. Read the repo's conventions: `AGENTS.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, branch policies, and existing branch and commit history.
2. Find candidate base branches: the remote default (`git symbolic-ref refs/remotes/origin/HEAD`), plus any long-lived branches the conventions name (`develop`, `release/*`).
3. **Gate**: the base branch, and the new branch name: the repo's convention, else the one in `BR-02`.
4. With uncommitted changes present, ask whether to stash, commit, or stop; keep the user's work intact.
5. `git fetch origin <base>`, then `git switch -c <branch> origin/<base>`.

Done when the new branch is checked out at the tip of the freshly fetched base.

## 6. Implement test-first

Detect the project's stack and existing test tooling.

**Gate**: the test plan: for each checklist entry, the layer(s), the seam, and the test name, meeting every testing control that applies. Any new framework or package (Playwright, axe) is listed for the user to approve.

Then work **red → green** in vertical slices, one checklist entry at a time: a failing test, the least code that passes it, rerun. Follow [TESTING.md](TESTING.md) for each layer. Keep the build, linter, and tests green for everything you touched, using the commands the repo defines (package scripts, solution files, Makefile, CI workflows). For .NET and TypeScript/JavaScript, run the `lint` skill (call the Skill tool with "lint") on the touched files before the commit gate.

Done when every checklist entry is ticked with its evidence: the test name and a passing run.

## 7. Commit

Stage only files that belong to this item.

Draft the message from the item, following the repo's convention; absent one, follow the commit controls (`CM-*`):

```text
feat(<scope>): <imperative summary of the item title>

<why, from the item's description>
<what changed, one line per notable change>

AB#<id>    (GitHub-hosted)   or   #<id>    (Azure Repos)
```

**Gate**: the staged file list and message. Prefer one commit per vertical slice when slices are independently meaningful.

## 8. Review

Dispatch three read-only reviewers as parallel subagents: **PR Reviewer**, **Security Reviewer**, and **Privacy Reviewer**. Each starts with an empty context, so every prompt carries: the item's ID and title, the acceptance checklist with each entry's evidence, the base ref and branch, and the full output of `git diff origin/<base>...HEAD`.

Each prompt also carries its reviewer's controls and any scanner output:

- **Controls**: the output of `controls.sh <topic> --ref origin/<base>`, all three layers: `security` for the Security Reviewer, `privacy` for the Privacy Reviewer, and `testing`, `practices`, and `lint` for the PR Reviewer. The script reads the repo's overrides from the base, never from the branch under review, so a change can't rewrite its own controls.
- **Scanners**: the commands under Scanners in the merged `security` and `privacy` layers. Show the user the exact commands and run only the ones they approve, then pass each output along.

In clients without these agents, dispatch general subagents whose prompts are the bodies of [pr-reviewer](../../com.github.copilot/agents/pr-reviewer.agent.md), [security-reviewer](../../com.github.copilot/agents/security-reviewer.agent.md), and [privacy-reviewer](../../com.github.copilot/agents/privacy-reviewer.agent.md), each followed by the same inputs.

Merge the three tables. Fix every blocker and should-fix, rerunning the tests each fix touches. Fold each fix into the commit it belongs to (`git commit --fixup <sha>`, then `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash origin/<base>`). Re-dispatch the reviewers that reported blockers while any remain.

**Gate**: the merged findings, what you fixed, the nits for the user to accept or skip, and each `escalate` finding with the sign-off team its controls name. Done when every verdict is **ready**, or **needs sign-off** with the user's agreement to carry the escalations into the PR.

## 9. Open the pull request

Re-measure the diff: `git diff --shortstat origin/<base>...HEAD`. Recommend a split again if it outgrew `PR-01`.

Write the body with the `pr` skill (call the Skill tool with "pr"). Put the screenshots and passing test runs from step 6 in its Evidence section, and append the work item link and the acceptance checklist with each entry's evidence.

**Gate**: title (the item title plus its ID), target branch (the base from step 5), draft or published, reviewers (including each sign-off team from step 8's `escalate` findings, as required reviewers), merge strategy (squash recommended where allowed), auto-complete when policies pass, and the full body. List open escalations in the body's Merge Danger section, along with every security or privacy control the repo turned off and its reason. Recommend a draft until the pipeline is green.

**Solo**: when nobody else can approve, check the branch's approval policy. If it would leave the PR impossible to complete, say so and offer the `branch-policies` skill's solo profile rather than any bypass. In solo, post the merged step 8 findings on the PR as its review record. Have the user acknowledge each `escalate` finding in a PR comment. Then, on the user's yes, approve and set auto-complete: `az repos pr set-vote --vote approve` and `az repos pr update --auto-complete true`, or `gh pr merge --auto --squash`.

On the user's yes, push with `git push -u origin <branch>`, then create the PR:

- **Azure Repos**: MCP `repo_pull_request_write` action `create`, then `wit_work_item_link_write` action `link_to_pull_request`. CLI: `az repos pr create --source-branch <branch> --target-branch <base> --title <title> --description <body> --work-items <id> [--draft true] [--auto-complete true --squash true --delete-source-branch true]`.
- **GitHub**: `gh pr create --base <base> --head <branch> --title <title> --body-file .git/agentic-dev-kit/tmp/pr-body.md [--draft]`; `AB#<id>` in the body links the item through the Azure Boards app.

Done when the PR URL is returned and the item is linked to it.

## 10. Hand back

Report the branch, commits, PR URL, each acceptance criterion with its evidence, and anything deferred or split off. Then offer the remaining ADO writes (state change, a comment with the PR link and evidence summary) and run only those the user approves. When reviewers comment, the `pr-review` skill works the threads from the author's side. In teach mode, close with a recap of the practices applied and the recall questions the user missed.

Then run the postflight: `check.sh post ado-implement`, and show its table. Alongside it, confirm the remote state with a fresh read: the PR exists, targets the base, links the item, and lists any sign-off teams as reviewers. Done when the postflight passes and the remote state matches.
