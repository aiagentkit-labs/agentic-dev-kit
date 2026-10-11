# Author: address review comments

The PR is the user's. The loop runs until every thread is **settled**: resolved, or holding an author reply the reviewer has yet to answer.

## 1. Find the PR

- ID or URL given: use it.
- Otherwise the PR whose source branch is the current branch (Azure Repos: MCP `repo_pull_request` action `list` filtered by source branch, or `az repos pr list --source-branch <branch>`; GitHub: `gh pr view --json number,url`).
- Otherwise list the user's open PRs and let them pick.

Then switch to its source branch and `git pull --ff-only`.

## 2. Collect the open threads

For each thread that is still open, gather: the reviewer, the file and line, the full comment chain, and the code the line points at **now** (the thread may be outdated).

- **Azure Repos**: MCP `repo_pull_request_thread` action `list`, keeping threads with status `active` or `pending`; action `list_comments` for each chain.
- **GitHub**: review threads with their resolution state:

  ```bash
  gh api graphql -F o=<owner> -F r=<repo> -F n=<number> -f query='
    query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){
      reviewThreads(first:100){nodes{id isResolved isOutdated path line
        comments(first:50){nodes{databaseId author{login} body}}}}}}}'
  ```

  plus top-level comments and review bodies: `gh pr view <n> --json comments,reviews`.

Done when every open thread is listed with its current code.

## 3. Triage

**Gate**: one question per thread. Classify it (change request, question, suggestion, nitpick, outdated) and recommend one response:

- **Fix**: the reviewer is right; say what you'll change.
- **Answer**: a question, answered from the code or the work item.
- **Push back**: the change would break an acceptance criterion, widen scope, or rests on a misreading. Give the reason with the line or criterion that backs it.
- **Defer**: valid but outside this item; becomes a follow-up work item linked to this one.

Recommend fix unless the evidence says otherwise. Facts in the code are yours to find; the call on each thread is the user's.

## 4. Fix

Work each accepted fix test-first, using the layers in [TESTING.md](../ado-implement/TESTING.md), and keep the build and tests green. Commit per thread or per group of related threads, with the work item linked as in [PRACTICES.md](../ado-implement/PRACTICES.md#commits).

Add the round's fixes as new commits on top. If the user prefers, squash this round's local commits into one first. Leave alone the commits reviewers have already seen, so they can review only what changed.

## 5. Reply and resolve

**Gate**: the new commits, a drafted reply per thread, the threads to resolve, and any follow-up work items to create.

- Fixed: what changed and the commit link. Resolve the thread.
- Answered: the answer. Resolve it if the question is closed; otherwise leave it open for the reviewer.
- Pushed back: the reason. Leave it open; the reviewer resolves it.
- Deferred: the follow-up item's link. Resolve the thread.

On the user's yes, push, then post:

- **Azure Repos**: MCP `repo_pull_request_thread_write` action `reply`, then action `update_status` with `fixed`, `wontFix`, or `closed`. Follow-ups: `wit_work_item_write` action `create`, then link it to the PR's work item.
- **GitHub**: reply with `gh api repos/<owner>/<repo>/pulls/<n>/comments/<databaseId>/replies -f body=<reply>`; resolve with the GraphQL mutation `resolveReviewThread(input:{threadId:"<id>"})`.

## 6. Loop

Re-collect the threads (step 2). New comments or reviewer replies start another round at step 3.

Done when every thread is settled. Report each thread's outcome, the commits pushed, and which threads now wait on a reviewer. Tell the user to run this again when new comments arrive.
