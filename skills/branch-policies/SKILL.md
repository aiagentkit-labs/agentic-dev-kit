---
name: branch-policies
description: Review and set branch policies on Azure Repos or GitHub through an interview, including relaxing approval rules for a solo developer with no one to approve their PRs. Use when the user mentions branch policies, branch protection, required reviewers, or working alone on a repo.
---

Branch policies are shared infrastructure. Show every change as before and after, apply it only on the user's yes, and leave the user able to revert it. Changing policies needs admin rights: **Edit policies** on the Azure Repos repository, or admin on the GitHub repository.

Run the [preflight and postflight](../../scripts/check.sh) as the other skills do (`check.sh pre|post branch-policies`), and show each table. Use the interview mode from [ado-implement step 0](../ado-implement/SKILL.md#0-pick-the-interview-mode), with each gate a round in the format of [ado-implement's Rounds](../ado-implement/SKILL.md#rounds).

## Profiles

| Policy on the default branch | Team | Solo |
|---|---|---|
| Changes arrive through a pull request | required | required |
| Minimum approvers | 1+, the author's vote doesn't count | Azure Repos: 1, the author's own vote counts. GitHub: 0 (GitHub never lets authors approve) |
| Reset approvals on new pushes | on | on |
| Build validation / required status checks | required | required |
| Linked work item (Azure Repos) | required | required |
| Comments resolved before merge | required | required |
| Force pushes and branch deletion | blocked | blocked |

**Solo** relaxes only *who approves*. Everything that catches mistakes stays. In return, the kit adds controls:

- The PR, Security, and Privacy reviewers act as the second reviewer. Their merged findings are posted on the PR as its review record.
- An `escalate` finding has no sign-off team, so the user acknowledges each one in a PR comment before completing.
- When a second person joins, switch back to **team**.

## 1. Read the current state

- **Azure Repos**: get the repository ID with `az repos show --repository <name> --query id -o tsv`, then `az repos policy list --repository-id <id> --branch <branch>`.
- **GitHub**: `gh api repos/<owner>/<repo>/branches/<branch>/protection` (a 404 means unprotected) and `gh api repos/<owner>/<repo>/rulesets`. Count who else could approve with `gh api repos/<owner>/<repo>/collaborators --jq length`.

Done when every policy on the branch is listed with its current values.

## 2. Choose the profile

**Gate**: recommend **solo** when the user is the only one who can approve, otherwise **team**. Show a table of each policy (current value, target value) and the exact commands from step 3. Write down the revert commands (the current values) to include in the report.

## 3. Apply

On the user's yes:

- **Azure Repos, solo**: update the minimum-reviewers policy with `az repos policy approver-count update --id <policy-id> --minimum-approver-count 1 --creator-vote-counts true --reset-on-source-push true`. If none exists, create one with `az repos policy approver-count create --repository-id <id> --branch <branch> --blocking true --enabled true --minimum-approver-count 1 --creator-vote-counts true --allow-downvotes false --reset-on-source-push true`.
- **Azure Repos, team**: the same command with `--creator-vote-counts false` and the team's approver count.
- **Azure Repos, both profiles**: create any missing policy the profile requires, for example `az repos policy work-item-linking create` and `az repos policy comment-required create`, each with `--repository-id <id> --branch <branch> --blocking true --enabled true`. Build validation needs a pipeline ID (`az repos policy build create --build-definition-id <id> ...`); offer it only when a pipeline exists.
- **GitHub, branch protection**: `gh api -X PATCH repos/<owner>/<repo>/branches/<branch>/protection/required_pull_request_reviews -F required_approving_review_count=<0 for solo, 1+ for team>`.
- **GitHub, rulesets**: fetch the ruleset, change `required_approving_review_count` in its `pull_request` rule, and `gh api -X PUT repos/<owner>/<repo>/rulesets/<id> --input .git/agentic-dev-kit/tmp/ruleset.json`.

Branch policies are never bypassed and never disabled wholesale. The guardrail hook asks before every policy change.

## 4. Verify and report

Re-read the policies (step 1). Done when they match the target. Report before and after, the revert commands, and what the profile means day to day: in solo, [ado-implement](../ado-implement/SKILL.md) posts the reviewers' findings on each PR and asks before the user approves their own.
