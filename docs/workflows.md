# Workflows

Every skill works the same way: it gathers facts itself, then stops at a **gate** where you decide. Nothing is pushed, posted, or written to Azure DevOps or GitHub without your yes.

## ado-implement: work item to pull request

```mermaid
flowchart TD
  M[0. Pick the interview mode<br/>grill or teach] --> C[1. Connect<br/>MCP server, else az CLI]
  C --> S[2. Select the work item]
  S --> A[3. Assess the item<br/>scorecard and a rewrite]
  A --> SC[4. Settle scope<br/>acceptance checklist, small-PR split]
  SC --> B[5. Branch<br/>off a freshly fetched base]
  B --> I[6. Implement test-first<br/>red then green, lint touched files]
  I --> CM[7. Commit<br/>linked to the work item]
  CM --> R[8. Review<br/>three read-only reviewers]
  R --> P[9. Open the pull request<br/>pushed on your yes]
  P --> H[10. Hand back<br/>evidence per criterion]
```

| Step | Gate: what you decide |
|---|---|
| 2. Select | Which item to work on. Several items run one at a time, one branch and PR each. |
| 3. Assess | The rewritten item: every gap filled with a default marked as an assumption, which you accept or amend |
| 4. Settle scope | The acceptance checklist, each entry with the check that proves it, and any split into smaller PRs |
| 5. Branch | The base branch and the new branch's name |
| 6. Implement | The test plan: the layer, seam, and test name for each checklist entry, and any new packages |
| 7. Commit | The staged files and the commit message |
| 8. Review | The merged findings, the fixes made, which nits to take, and any `escalate` findings |
| 9. Pull request | Title, target, draft or not, reviewers, merge strategy, and the full body |
| 10. Hand back | Which Azure DevOps updates to make: state change, comment with the PR link |

### Step 8: the review

```mermaid
flowchart TD
  D[Your branch<br/>diff against the base] --> PR[PR Reviewer<br/>spec, tests, standards]
  D --> SEC[Security Reviewer<br/>security controls]
  D --> PRV[Privacy Reviewer<br/>privacy controls]
  PR --> F[Merged findings]
  SEC --> F
  PRV --> F
  F --> FX[Fix blockers and should-fixes<br/>rerun tests]
  FX --> G{Gate:<br/>you review}
```

The three reviewers run in parallel, each starting with an empty context. Each gets the work item, the acceptance checklist with its evidence, the full diff, and its [controls](controls.md), read from the base branch, so the change under review can't rewrite them. Reviewers that reported blockers run again until none remain.

When nobody else can approve your PRs, the **solo** profile from `branch-policies` applies, and `ado-implement` posts the reviewers' findings on the PR as its review record.

## pr-review: address the comments on your PR

```mermaid
flowchart TD
  T[Collect open threads<br/>with the code they point at now] --> TR{Triage each thread}
  TR -->|fix| F[Fix test-first<br/>new commits on top]
  TR -->|answer, push back,<br/>or defer| D[Draft a reply]
  F --> D
  D --> Y{Gate: replies,<br/>commits, resolutions}
  Y -->|your yes| P[Push and post]
  P --> L{Every thread settled?}
  L -->|no| T
  L -->|yes| Done([Done])
```

A thread is **settled** when it's resolved, or holds your reply and waits on the reviewer. A pushed-back thread stays open for the reviewer to resolve; a deferred one becomes a follow-up work item.

## pr-review: review someone else's PR

```mermaid
flowchart TD
  F[Find the PR<br/>you pick] --> C[Read the context<br/>spec from the work item]
  C --> H[Check out the PR's head]
  H --> R[Three reviewers in parallel<br/>controls from the target branch]
  R --> V[Verify every cited line<br/>drop what can't be confirmed]
  V --> S{Gate: per finding<br/>post, reword, or drop}
  S --> P[Post comments and vote<br/>on your yes]
  P --> B[Hand back<br/>restore your branch]
```

The recommended vote follows from the findings: any blocker means *request changes* (*wait for author* on Azure Repos), and an `escalate` finding adds its sign-off team as a reviewer.

## lint: the files you touched

```mermaid
flowchart TD
  D[1. Detect and check<br/>Lint Runner subagent] --> S{2. Missing tools?}
  S -->|yes| SU[Set up the baseline<br/>on your yes]
  SU --> D
  S -->|no| F[3. Fix<br/>auto-fixes, code changes,<br/>rule questions]
  F --> RE[Run the checks again]
  RE --> C{Clean?}
  C -->|no| F
  C -->|yes| R[4. Report]
```

The scope is the files changed against the base branch plus your uncommitted ones. The Lint Runner keeps long lint output in its own context, so your chat only sees the grouped findings.

## branch-policies: team or solo

```mermaid
flowchart TD
  R[1. Read the current policies] --> P{2. Who can approve?}
  P -->|others can| T[Team profile<br/>1+ approvers, author's vote doesn't count]
  P -->|only you| S[Solo profile<br/>approval rule relaxed, everything else kept]
  T --> A[3. Apply on your yes]
  S --> A
  A --> V[4. Verify and report]
```

**Solo** relaxes only who approves. Pull requests, builds, resolved comments, and blocked force pushes stay required. In return, the reviewers' findings become the PR's review record, and you acknowledge each `escalate` finding in a PR comment.
