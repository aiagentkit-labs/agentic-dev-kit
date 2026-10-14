# Recipes

Copy-paste overrides for common needs. Each file goes in your repo at the path shown. Control files take effect once they're on your base branch, because reviews read them from there. The rules behind them are in [Controls](controls.md).

## Tighten a control

Make the accessibility scans check WCAG 2.2 level AAA instead of AA.

`.github/testing-controls/testing.md`:

```markdown
## Controls

| ID | Control | Severity |
|---|---|---|
| A11Y-02 | Scans check WCAG 2.2 level AAA | blocker |
```

`A11Y-02` exists in the default, so this row replaces it. Every other testing control stays.

## Add a control

`.github/testing-controls/testing.md`:

```markdown
## Controls

| ID | Control | Severity |
|---|---|---|
| UI-10 | Every UI test runs in Chromium and WebKit | should-fix |
```

`UI-10` is a new ID, so it's added alongside the defaults.

## Turn a control off

`.github/testing-controls/testing.md`:

```markdown
## Controls

| ID | Control | Severity |
|---|---|---|
| UI-05 | off: this repo tests its UI with Cypress (ADR-012) | off |
```

The reason after `off:` is required, and the turned-off control is listed in every gate and review that would have applied it.

## Share one standard across many repos

Put the standard in an organization repo, for example `contoso/eng-standards` at `review-controls/security.md`, using the same format as the plugin default. Then each repo extends it.

`.github/review-controls/security.md`:

```markdown
---
extends: https://github.com/contoso/eng-standards.git#main:review-controls/security.md
---

## Controls

| ID | Control | Severity |
|---|---|---|
| SEC-08 | New or updated dependencies are maintained, pinned by the lockfile, and free of known vulnerabilities | blocker |
```

The order is: the plugin default, then the organization's file, then this repo's rows. Here the repo raises `SEC-08` from should-fix to blocker.

## Replace a whole topic

`.github/practice-controls/practices.md`:

```markdown
---
mode: replace
---

## Controls

| ID | Control | Severity |
|---|---|---|
| PR-01 | A PR changes under 200 lines of hand-written code | blocker |
| PR-05 | A PR links its work item | blocker |
| CM-02 | A commit subject is imperative and at most 72 characters | nit |
```

Only these three controls apply. The default's other practice controls, its instructions, and any shared layer are dropped.

## Add guidance for the agent

`.github/testing-controls/testing.md`:

```markdown
## Controls

| ID | Control | Severity |
|---|---|---|
| UI-05 | UI tests use Playwright, with a config that starts the app | should-fix |

## Instructions

Use the page objects in `tests/pages/` for every UI test, and keep fixtures under `tests/fixtures/`.
```

The validator requires at least one control row, so repeat a default row unchanged if instructions are all you need.

## Run your organization's scanners

`.github/review-controls/security.md`:

```markdown
## Controls

| ID | Control | Severity |
|---|---|---|
| SEC-01 | No secrets, keys, tokens, or connection strings in code, config, tests, fixtures, or logs | blocker |

## Scanners

| Name | Command |
|---|---|
| gitleaks | gitleaks detect --source . --no-git --report-format json --report-path - |
| npm audit | npm audit --omit=dev --json |

## Escalation

[Contoso]\Security Champions
```

Scanners are read-only commands. The agent shows you the exact commands and runs only the ones you approve, then the Security Reviewer triages their output. The Escalation team is added as a required reviewer on any PR with an `escalate` finding.

## Add your own guardrail rules

`.github/guardrails/guardrails.yaml`:

```yaml
deny:
  - terraform destroy
ask:
  - kubectl apply
  - npm publish
```

See [Guardrails](guardrails.md) for the format and what these rules can and can't change.

## Which pattern to use

| Goal | Use |
|---|---|
| Change one rule | A row with the same ID |
| Add a rule | A row with a new ID |
| Skip a rule on purpose | Severity `off`, with `off:` and the reason |
| Share rules across repos | `extends` to a standards repo |
| Use only your own rules for a topic | `mode: replace` |
| Explain how your repo meets a rule | `## Instructions` |
| Block or confirm a command | `.github/guardrails/guardrails.yaml` |
