# Security controls

The baseline the **Security Reviewer** applies to every change. An organization extends it per repo with `.github/review-controls/security.md` in the same format: its controls add to these, and a control with a baseline ID replaces that baseline control.

Severities: `blocker`, `should-fix`, `nit`, and `escalate` (needs sign-off from the team named under Escalation before merge).

## Controls

| ID | Control | Severity |
|---|---|---|
| SEC-01 | No secrets, keys, tokens, or connection strings in code, config, tests, fixtures, or logs | blocker |
| SEC-02 | Queries, commands, and templates built from input are parameterized; no string-built SQL, shell, or LDAP | blocker |
| SEC-03 | Every new endpoint, handler, or action enforces authorization server-side for the resource it touches | blocker |
| SEC-04 | Input is validated at each trust boundary, and output is encoded for its context (HTML, URL, JS) | should-fix |
| SEC-05 | User-controlled URLs and file paths are validated against an allow-list (SSRF, path traversal) | blocker |
| SEC-06 | Untrusted data is never deserialized into arbitrary types | blocker |
| SEC-07 | Cryptography comes from the platform library; no MD5/SHA-1 for security, no ECB, no custom schemes | blocker |
| SEC-08 | New or updated dependencies are maintained, pinned by the lockfile, and free of known vulnerabilities | should-fix |
| SEC-09 | Security-relevant events are logged, and logs carry no secrets or session tokens | should-fix |
| SEC-10 | Changes that widen permissions in pipelines, infrastructure code, or identity config | escalate |

Sources: [OWASP Top 10](https://owasp.org/Top10/), [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/).

## Scanners

Read-only commands whose output the reviewer triages. The calling skill runs them only after the user approves the exact commands. None by default; list your organization's here or in the repo file.

| Name | Command |
|---|---|

<!-- Examples:
| gitleaks | gitleaks detect --source . --no-git --report-format json --report-path - |
| npm audit | npm audit --omit=dev --json |
| dotnet | dotnet list package --vulnerable |
| pip-audit | pip-audit -f json |
-->

## Escalation

Who signs off on `escalate` findings, added as required reviewers on the PR. None by default.

<!-- Example: [Contoso]\Security Champions -->
