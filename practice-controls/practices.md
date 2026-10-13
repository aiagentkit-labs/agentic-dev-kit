# Practice controls

The defaults the kit applies to work items, branches, commits, and pull requests: at the gates of `ado-implement` and `pr-review`, and in the **PR Reviewer**'s Standards axis. Why each matters, and how to meet it, is in [PRACTICES.md](../skills/ado-implement/PRACTICES.md). A repo tailors them with `.github/practice-controls/practices.md`; see [CONTROLS.md](../CONTROLS.md).

## Controls

| ID | Control | Severity |
|---|---|---|
| WI-01 | The title states the outcome, not the activity: "Users can reset their password from the login page", not "Password fix" | should-fix |
| WI-02 | The description says who is affected, the problem, and why it matters now | should-fix |
| WI-03 | Acceptance criteria are numbered, each independently testable, and written as Given / When / Then | blocker |
| WI-04 | A UI item has an accessibility criterion | should-fix |
| WI-05 | A bug has repro steps: steps, expected vs actual, environment, and frequency | blocker |
| WI-06 | The item links its parent feature or epic, and related or blocking items | nit |
| PR-01 | A PR changes under 400 lines of hand-written code, excluding lockfiles, snapshots, and generated code | should-fix |
| PR-02 | A PR does one thing; each split is a child task on the work item | should-fix |
| PR-03 | The author self-reviews the full diff before asking anyone else | should-fix |
| PR-04 | A PR stays a draft until its build is green | should-fix |
| PR-05 | A PR links its work item | blocker |
| PR-06 | A PR merges with squash where the repo allows it | nit |
| BR-01 | A branch starts from the freshly fetched base, and its PR opens within days | should-fix |
| BR-02 | A branch is named `feat/<id>-<slug>` or `fix/<id>-<slug>`, unless the repo's convention says otherwise | nit |
| BR-03 | A branch carries one work item | should-fix |
| CM-01 | A commit holds one logical change, and the build and tests pass at every commit | should-fix |
| CM-02 | A commit subject is imperative and at most 72 characters; the body explains why | nit |
| CM-03 | Commit types follow Conventional Commits (`feat`, `fix`, `test`, `refactor`, `docs`, `chore`), absent a repo convention | nit |
| CM-04 | Every commit links the item: `AB#<id>` on GitHub, `#<id>` on Azure Repos | should-fix |
| SOLO-01 | With no second approver, every change still goes through a PR with its build; only the approval rule relaxes | blocker |
