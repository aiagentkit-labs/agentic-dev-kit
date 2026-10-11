# Practices

Reference for [`ado-implement`](SKILL.md). Each practice is a check the skill applies at a gate; when one fails, name it, say why it matters in one line, and recommend the fix. In teach mode, cite the practice's source.

## Descriptive work items

An item is ready when a reviewer who never spoke to its author could tell what "done" looks like.

| Field | Ready when |
|---|---|
| Title | States the outcome, not the activity: "Users can reset their password from the login page", not "Password fix" |
| Description | Says who is affected, the problem, and why it matters now |
| Acceptance criteria | Numbered, each independently testable, written as Given / When / Then; UI items include an accessibility criterion |
| Repro steps (bugs) | Steps, expected vs actual, environment, and frequency |
| Size | Fits one small PR (below); otherwise split into child tasks |
| Links | Parent feature or epic, plus related or blocking items |

When an item falls short, draft the improved fields and offer to write them back. Source: [Azure Boards: best practices, team backlog](https://learn.microsoft.com/azure/devops/boards/best-practices-agile-project-management#team-backlog).

## Small PRs

One PR does one thing. Aim for under ~400 changed lines of hand-written code (exclude lockfiles, snapshots, and generated code); past that, reviewers skim instead of review. Source: [Google Engineering Practices: Small CLs](https://google.github.io/eng-practices/review/developer/small-cls.html).

Ways to split, in order of preference:

1. **Vertical slices**: one acceptance criterion (or a few) end to end per PR, each shippable.
2. **Refactor first**: a no-behaviour-change PR that makes the feature PR small.
3. **Feature flag**: merge incomplete work dark, behind a flag.
4. **Stacked PRs**: each targets the previous branch; merge bottom-up.

Record each split as a child task on the work item, so the backlog reflects the plan.

## Branches

- Short-lived: branch from the freshly fetched base and open the PR within days, not weeks.
- Name carries the item: `feat/<id>-<slug>` or `fix/<id>-<slug>`, unless the repo's convention says otherwise.
- One item per branch.

## Commits

- One logical change per commit; the build and tests pass at every commit.
- Subject in the imperative mood, at most 72 characters; body explains *why*. Source: [How to Write a Git Commit Message](https://cbea.ms/git-commit/).
- Absent a repo convention, use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `feat`, `fix`, `test`, `refactor`, `docs`, `chore`.
- Link the item in every commit: `AB#<id>` on GitHub-hosted repos (needs the Azure Boards app), `#<id>` on Azure Repos.

## Pull requests

- Self-review the full diff before asking anyone else to.
- Open as a draft until the build is green; publish when ready for review.
- Link the work item, so branch policies and traceability work. Source: [Azure Repos: create a PR](https://learn.microsoft.com/azure/devops/repos/git/pull-requests).
- Squash merge keeps the base branch one commit per item, when the repo allows it.
