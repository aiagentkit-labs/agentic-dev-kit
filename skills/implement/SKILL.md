---
name: implement
description: Turn a task from Azure DevOps, Jira, another connected tracker, pasted text, or a local file into a tested and reviewed pull request. Use when the user asks to implement, build, or fix a task, feature, or bug.
---

Turn a task request into a pull request ready for review. The source can be a tracker issue, text in chat, or a local text/Markdown file. The task's agreed acceptance criteria are the completion contract: every criterion must map to evidence (a passing test or observed behavior).

The implementation, test-first, review, and PR workflow is shared across all input sources. Tracker-specific operations are optional capabilities, not prerequisites. Do not claim a provider is connected unless its MCP server, CLI, or other available integration can actually read or write it.

## Source and task record

Resolve the source in this order:

1. **URL or provider-qualified ID:** identify the provider from the URL/key, then use its available MCP tools first, otherwise its installed CLI/API integration. If the provider is unclear, ask. Never ask the user to paste credentials. If ADO is selected and the MCP path is unavailable, run `check.sh pre ado-implement` before using the `az` fallback so its sign-in/tool requirements are checked.
2. **Pasted request:** use the supplied text as the initial task; do not search a tracker for a matching item unless the user asks.
3. **Local file:** read the path the user supplied. Do not edit the original task file as part of loading it.
4. **No request supplied:** ask for a tracker URL/ID, pasted text, or file path. Do not assume Azure DevOps.

If a tracker is named but no usable integration is available, say so and offer pasted or exported text as a fallback. A generic MCP connection counts only when its exposed tools can perform the needed operation. Jira is not bundled as a connector; Jira end-to-end access requires a Jira MCP/CLI adapter in the user's client. Do not imply a Jira URL alone grants access.

Normalize every source into the task record described in [TASK-RECORD.md](TASK-RECORD.md): title, description, acceptance criteria, optional repro/context, source metadata, and available source capabilities. Preserve the source URL, key, or input file path when available. Do not invent missing acceptance criteria or provider records.

After the user accepts the task draft, offer an optional, durable Markdown task record at `work-items/<slug>.md` in the target repository. Show the exact path and content and get the user's yes before writing it. Never overwrite an existing file; choose another slug or ask. For tracker-backed tasks, saving a local copy is optional. For pasted/file tasks, offer it as the traceable task artifact. Avoid copying secrets or sensitive personal data into the repository.

## External writes

Each write to a shared tracker, `git push`, or PR create/update needs the user's yes at the moment of the write. A tracker update is offered only if the selected source adapter exposes that operation. A local task-record write is also shown at its gate before writing. Credentials never pass through chat. Write temporary payloads and PR bodies under `.git/agentic-dev-kit/tmp/`.

## Controls

The defaults and repo overrides are the rules for this run ([CONTROLS.md](../../CONTROLS.md)). After preflight, fetch `origin` and read the merged `practices`, `testing`, and `lint` controls with [controls.sh](../../scripts/controls.sh) `<topic> --ref origin/<default branch>`; read them again from `origin/<base>` if step 5 picks another base. List turned-off controls, with reasons, in the first round. At every gate, check the task against the practices controls ([PRACTICES.md](../ado-implement/PRACTICES.md)). A `WI-*` control governs task quality regardless of whether the task came from a tracker, text, or file. When one is missed, name its ID, explain briefly, and recommend a fix in that round.

## Preflight

From the target repo root, run [check.sh](../../scripts/check.sh) `pre implement` (Windows: [check.ps1](../../scripts/check.ps1) `-Phase pre -Skill implement`). Show its table. A `WARN` is mentioned and the run continues.

A `FAIL` pauses the run. Ask one round with a question per failing check:

- **Fix it:** show the fix and rerun. For missing tools, point to [install.sh](../../scripts/install.sh) or [install.ps1](../../scripts/install.ps1) for the user to run in their terminal; installs and sign-ins may need approval or credentials.
- **Skip it:** rerun with `--skip <ids>` (Windows: `-SkipChecks <ids>`), where IDs are `git`, `az`, `gh`, `node`, or `dotnet`. Explain the cost: for example, without `gh` a GitHub PR cannot be created. Before a skipped tool is needed, check it again and pause if it still fails.

Done when the table has no `FAIL`.

## Rounds

Every gate is an interview round:

- Ask the whole frontier of decisions whose prerequisites are settled, numbered. A dependent question waits for the next round.
- Recommend a clear answer; phrase it so "yes" accepts it.
- Use the question tool when the client provides one; otherwise use the format below. Use the 📘 line in teach mode only, and include Why, Source, and Check on every teach-mode question.
- Grill mode asks for decisions. Teach mode also explains why, cites a relevant source, and asks a recall question. The user can switch modes at any gate.

```markdown
**Step N/10 · <step name> · Round k**

❓ **Q1 - <title>**: <question and options>

➡️ <recommended answer>

📘 **Why:** <why> · **Source:** <link> · **Check:** <recall question>
```

## 0. Pick the interview mode

Unless the user's request already names it, ask once whether they want **Grill** (decisions only) or **Teach** (decisions plus why, sources, and recall). Do this before resolving the task source. The user can switch modes at any later gate.

## 1. Choose the source and connection

Identify source mode: tracker, pasted text, or local file. For a tracker, discover available tools and authenticate through the host's normal sign-in. The provider adapter should report its capabilities, for example:

| Capability | Meaning |
|---|---|
| Read | Fetch the issue and related context |
| Update | Write an accepted description, criteria, state, or comment |
| Link PR | Add the resulting PR to the issue |
| Create child | Persist split tasks in the tracker |

Only use capabilities actually exposed by the integration. A provider may be read-only. Do not block implementation because optional update/link capabilities are absent.

### Detecting a tracker connection

At run time, inspect the tools exposed to the current chat/session. Use tool names and descriptions to identify provider operations; do not assume a connection from the issue URL, ID shape, or a server name alone. Map only operations that are actually exposed to the capability table above. Before treating a tracker as connected, use its read-only get/fetch operation on the user-supplied issue and confirm it returns that issue. If the client does not expose a relevant tool, or the read fails because the server is disabled, unauthenticated, or lacks permission, treat the tracker as unavailable and offer pasted/exported task text. Never probe with a write.

VS Code can expose MCP servers configured by the user, workspace, or installed plugins to the active chat when their tools are enabled. This plugin currently bundles the Azure DevOps MCP server in `mcp.json`; it does not bundle a Jira server. Installing the plugin alone therefore does not connect Jira. A user's existing Jira MCP server can be used when it exposes the needed tools to the session.

**Gate:** selected source and connection, or confirmation that the pasted/file text is the source. Tell the user which tracker operations are unavailable and what fallback applies.

## 2. Select or load the task

For a tracker, use the supplied URL/ID. If the user asks to select a task, list the matching open items and let them choose. For a file, read the supplied file. For pasted text, use it directly.

**Gate:** the exact task to implement. Several tasks run one at a time, one branch and PR each.

## 3. Assess and normalize

For tracker issues, fetch relations and relevant fields the provider supports. For text/file input, extract the stated problem, expected result, constraints, and repro steps without adding facts. Score the request against `WI-*` controls. Draft a normalized task record with numbered, independently testable Given/When/Then acceptance criteria. Mark any recommended defaults as assumptions.

**Gate:** show the source summary, scorecard, normalized draft, assumptions, and whether to save `work-items/<slug>.md`. If saving, show the full content and get approval before writing. After that, ask separately whether to write accepted changes back to a tracker, only when `Update` is available.

## 4. Settle scope

Turn the accepted criteria into a numbered implementation checklist. Pair every criterion with the check that proves it and the test layer under the testing controls ([TESTING.md](../ado-implement/TESTING.md)). Run further rounds for open decisions or contradictions. Estimate diff size; if it breaks `PR-01`, propose smaller slices.

If tasks are split, create child records only through an available `Create child` capability with approval. Otherwise offer separate Markdown task records. Do not silently create tracker items.

**Gate:** the checklist, test evidence per criterion, and any split. Each criterion must have a concrete check.

## 5. Branch

1. Read `AGENTS.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, branch policies, and recent branch/commit conventions.
2. Identify the remote default and any long-lived base branches.
3. **Gate:** base branch and new branch name.
4. With uncommitted work, ask whether to stash, commit, or stop; preserve it.
5. Fetch the base and branch from its latest remote commit.

Done when the new branch is checked out at the fetched base.

## 6. Implement test-first

Detect the stack and current test tooling. **Gate:** propose the test plan, with the test layer, seam, and test name for each criterion; list any new framework/package for approval. Then work red → green in small vertical slices. Run tests, build, and lint for the touched files. For .NET and TypeScript/JavaScript, use the `lint` skill before the commit gate.

Done when every criterion has passing evidence.

## 7. Commit

Stage only files for this task. Draft an imperative commit subject and a body explaining why. If a source key exists and the host supports a native commit link syntax, include it. Otherwise include the stable task slug or no fabricated tracker key.

**Gate:** staged files and commit message.

## 8. Review

Run PR Reviewer, Security Reviewer, and Privacy Reviewer in parallel with the task spec, acceptance checklist/evidence, base ref, full diff, relevant controls, and scanner output. Read scanners only after the user approves their exact commands. Reviewers are read-only.

Merge findings, verify every cited line, fix blockers and should-fixes, rerun tests, and rerun reviewers that found blockers.

**Gate:** findings, fixes, nits to accept/skip, and any `escalate` findings. Done when ready or when the user agrees to carry an escalation.

## 9. Open the pull request

Detect the PR host from the target repo's remote. Draft the PR with the task summary, accepted criteria, test evidence, reviewer findings, and traceability:

- Tracker task: link the issue using the provider/host's supported syntax, if available. If the target repo has a branch policy that requires a specific tracker item (for example, Azure Repos linked-work-item policy), explain that the PR cannot satisfy that policy with a local record alone; offer to create/link the required tracker item only if the adapter supports it.
- Saved task record: link its path in the PR and include the criteria/evidence.
- Pasted request not saved: include a concise accepted task summary and criteria in the PR body. Do not claim it links an external issue.

**Gate:** title, target, draft status, reviewers, merge strategy, and complete body. On the user's yes, push and create the PR using the host's supported tools. If the host or write integration is unavailable, provide the exact manual steps instead of claiming success.

## 10. Hand back

Report source type and reference (or "pasted request" / file path), branch, commits, PR URL, each criterion with evidence, and deferred work. If the source has `Update` or `Link PR`, offer those writes and perform them only on the user's yes. If a task record was saved, offer to update its status, criterion evidence, and PR link; show the diff and get approval before writing. Report its path. Run [check.sh](../../scripts/check.sh) `post implement` (Windows: `check.ps1 -Phase post -Skill implement`) and confirm the remote PR state.
