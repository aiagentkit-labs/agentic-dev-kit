# Reviewer: review someone else's PR

The PR is someone else's. You review it, the user decides what is said, and the comments land on the PR with the user's vote.

## 1. Find the PR

- ID or URL given: use it.
- Otherwise list PRs awaiting the user's review (Azure Repos: MCP `repo_pull_request` action `list` with the user as reviewer, or `az repos pr list --reviewer <me> --status active`; GitHub: `gh pr list --search "review-requested:@me"`).

**Gate**: the user picks.

## 2. Read the context

Gather the title, description, author, target branch, build or check status, and every existing thread. Then the **spec**: the acceptance criteria of each linked work item (`wit_work_item` action `get`). With no item linked, the description is the spec, and the missing link becomes a finding (see [PRACTICES.md](../ado-implement/PRACTICES.md#pull-requests)).

On a re-review, also note the commit you last reviewed and your own open threads.

## 3. Check out the head

Apply the working-tree rule from [SKILL.md](SKILL.md), then:

- **Azure Repos**: `git fetch origin <target>`, `git fetch origin <sourceRefName>`, then `git switch --detach FETCH_HEAD`.
- **GitHub**: `git fetch origin <target>`, `git fetch origin pull/<n>/head`, then `git switch --detach FETCH_HEAD`.

Done when `HEAD` is the PR's latest commit, so the line numbers you read match the PR.

## 4. Review

Dispatch the **PR Reviewer** agent as a subagent with: the spec, the base `origin/<target>`, the full `git diff origin/<target>...HEAD`, and the existing threads, so it skips points already raised. On a re-review, send the diff since your last reviewed commit and your open threads, and ask it to say whether each thread is now addressed. In clients without that agent, use the fallback in [ado-implement step 8](../ado-implement/SKILL.md#8-review).

When the diff breaks the small-PR budget, split the changed files into groups and dispatch one reviewer per group in parallel. Merge their tables, and add a finding that recommends splitting the PR.

Then open every cited line yourself and drop any finding you can't confirm. Done when each remaining finding points at a real line on `HEAD`.

## 5. Decide what to say

**Gate**: one question per finding: post as drafted, reword, or drop. Recommend dropping nitpicks that a linter or formatter should catch. Draft each comment in the style from [SKILL.md](SKILL.md). Add a `praise:` comment when something genuinely earns it.

Then, in the same round:

- **The vote**, recommended from the findings:

  | Findings | Azure Repos | GitHub |
  |---|---|---|
  | Any blocker | Wait for author | Request changes |
  | Only should-fix or nitpick | Approve with suggestions | Comment |
  | None | Approve | Approve |

- **The summary comment**: the verdict in a sentence and the top blockers.

On a re-review, also recommend resolving each of your threads that the new commits address.

## 6. Post

**Gate**: the exact comments (file, line, body), the summary, the vote, and the threads to resolve. On the user's yes:

- **Azure Repos**: MCP `repo_pull_request_thread_write` action `create` per comment, with the file path (leading `/`) and the line on the right side; the summary goes in a thread with no file. Then `repo_pull_request_write` action `vote`. CLI fallback: post each thread with `az devops invoke --area git --resource pullRequestThreads --route-parameters project=<p> repositoryId=<repo> pullRequestId=<id> --http-method POST --api-version 7.1 --in-file thread.json`, where `thread.json` is `{"comments":[{"content":"<body>","commentType":1}],"status":1,"threadContext":{"filePath":"/<path>","rightFileStart":{"line":<n>,"offset":1},"rightFileEnd":{"line":<n>,"offset":1}}}`. Vote with `az repos pr set-vote --id <id> --vote <approve|approve-with-suggestions|wait-for-author|reject>`.
- **GitHub**: one review carrying every comment, posted with `gh api repos/<owner>/<repo>/pulls/<n>/reviews --method POST --input review.json`, where `review.json` is `{"commit_id":"<HEAD sha>","event":"APPROVE|REQUEST_CHANGES|COMMENT","body":"<summary>","comments":[{"path":"<path>","line":<n>,"side":"RIGHT","body":"<body>"}]}`. Inline comments must target lines inside the diff; move any others into the summary.

## 7. Hand back

Restore the user's branch and stash. Report the links to what was posted and the vote cast. When the author pushes again, run this again for a re-review.
