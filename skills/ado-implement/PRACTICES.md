# Practices

Why the [practice controls](../../practice-controls/practices.md) matter and how to meet them, for [`ado-implement`](SKILL.md) and [`pr-review`](../pr-review/SKILL.md); each section names the control IDs it serves. Read the merged controls first ([CONTROLS.md](../../CONTROLS.md)): where the repo overrides a control, the override wins over this file. When a control is missed, name its ID, say why it matters in one line, and recommend the fix. In teach mode, cite the section's source.

## Descriptive work items (WI-01 to WI-06)

An item is ready when a reviewer who never spoke to its author could tell what "done" looks like. When an item falls short, draft the improved fields and offer to write them back. Source: [Azure Boards: best practices, team backlog](https://learn.microsoft.com/azure/devops/boards/best-practices-agile-project-management#team-backlog).

## Small PRs (PR-01, PR-02)

Past a few hundred lines, reviewers skim instead of review. Source: [Google Engineering Practices: Small CLs](https://google.github.io/eng-practices/review/developer/small-cls.html).

Ways to split, in order of preference:

1. **Vertical slices**: one acceptance criterion (or a few) end to end per PR, each shippable.
2. **Refactor first**: a no-behaviour-change PR that makes the feature PR small.
3. **Feature flag**: merge incomplete work dark, behind a flag.
4. **Stacked PRs**: each targets the previous branch; merge bottom-up.

Record each split as a child task on the work item, so the backlog reflects the plan.

## Branches (BR-01 to BR-03)

Short-lived branches stay close to the base and merge without conflict.

## Commits (CM-01 to CM-04)

A commit that builds and does one thing can be reviewed, reverted, and bisected on its own. Sources: [How to Write a Git Commit Message](https://cbea.ms/git-commit/), [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). `AB#<id>` links a GitHub commit to Azure Boards only when the Azure Boards app is installed on the repo.

## Pull requests (PR-03 to PR-06)

A linked work item lets branch policies and traceability work. Source: [Azure Repos: create a PR](https://learn.microsoft.com/azure/devops/repos/git/pull-requests).

## Working solo (SOLO-01)

With no second person to approve, a PR still runs the pipeline, records the review, and links the work item. Relax only the approval rule (the `branch-policies` skill's solo profile). Let the PR, Security, and Privacy reviewers stand in as the second reader. Before approving your own PR, re-read its diff after a break.
