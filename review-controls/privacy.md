# Privacy controls

The baseline the **Privacy Reviewer** applies to every change. A repo tailors it with `.github/review-controls/privacy.md`, or shares an organization's version through `extends`; see [CONTROLS.md](../CONTROLS.md).

**Personal data** is anything that identifies a person directly or in combination: names, emails, phone numbers, addresses, IDs, IP addresses, device IDs, location, and free text a person typed.

Severities: `blocker`, `should-fix`, `nit`, and `escalate` (needs sign-off from the team named under Escalation before merge).

## Controls

| ID | Control | Severity |
|---|---|---|
| PRV-01 | New fields, tables, events, or payloads holding personal data are identified in the PR | escalate |
| PRV-02 | Collection is minimal: only the personal data the acceptance criteria need | should-fix |
| PRV-03 | No personal data in logs, telemetry, error messages, URLs, query strings, or analytics events | blocker |
| PRV-04 | New stores of personal data have a retention period and honour deletion and export requests | should-fix |
| PRV-05 | New outbound flows of personal data to third-party services or SDKs | escalate |
| PRV-06 | Tracking, cookies, and analytics are gated on consent where the product requires it | blocker |
| PRV-07 | Endpoints returning personal data authorize access to the owning person, not just to any signed-in user | blocker |
| PRV-08 | No real personal data in tests, fixtures, seeds, or snapshots | blocker |

Source: [OWASP Top 10 Privacy Risks](https://owasp.org/www-project-top-10-privacy-risks/).

## Scanners

Read-only commands whose output the reviewer triages. The calling skill runs them only after the user approves the exact commands. None by default; list your organization's here or in the repo file.

| Name | Command |
|---|---|

## Escalation

Who signs off on `escalate` findings, added as required reviewers on the PR. None by default.

<!-- Example: [Contoso]\Privacy Office -->
