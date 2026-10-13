# Testing controls

The defaults the kit applies to tests: in the test plan at `ado-implement` step 6, and in the **PR Reviewer**'s Tests axis. How to meet each one is in [TESTING.md](../skills/ado-implement/TESTING.md). A repo tailors them with `.github/testing-controls/testing.md`; see [CONTROLS.md](../CONTROLS.md).

## Controls

| ID | Control | Severity |
|---|---|---|
| TST-01 | Every acceptance criterion maps to at least one test, named in the test plan | blocker |
| TST-02 | Logic, domain rules, and API handlers have unit tests through public interfaces, with expected values taken from the work item | blocker |
| TST-03 | A criterion about an API contract has an integration test at the API seam | should-fix |
| TST-04 | A bug fix has a regression test that fails on the repro steps before the fix, at the lowest layer that reproduces it | blocker |
| TST-05 | Unit tests are deterministic: no real clock, randomness, network, or state shared between tests | should-fix |
| TST-06 | Test doubles replace only boundaries the code doesn't own: network, clock, file system, external services | should-fix |
| TST-07 | Every new test has been seen failing, for the reason it exists | should-fix |
| TST-08 | A test's name states the behaviour it proves | nit |
| A11Y-01 | Every changed view has an automated accessibility scan, scoped to the changed region | blocker |
| A11Y-02 | Scans check WCAG 2.2 level AA: axe tags `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa` | blocker |
| A11Y-03 | Every new control is reachable with Tab and activates with Enter or Space, overlays close with Escape, and focus lands where expected | blocker |
| A11Y-04 | Tests locate controls by role and accessible name | should-fix |
| A11Y-05 | The PR's Evidence lists the manual checks still owed: screen reader, 200% zoom, and contrast in hover, focus, and error states | should-fix |
| UI-01 | Each user flow in the acceptance criteria has one UI test, named after its criterion | blocker |
| UI-02 | Locators prefer `getByRole`, `getByLabel`, `getByText`, then `getByTestId`; CSS and XPath come last | should-fix |
| UI-03 | Assertions wait on the page (web-first); no fixed timeouts | should-fix |
| UI-04 | Each test owns its data and state, and passes alone and in any order | should-fix |
| UI-05 | UI tests use Playwright, with a config that starts the app (`webServer`, `baseURL`) | should-fix |
| UI-06 | A screenshot of each finished flow goes in the PR's Evidence | nit |

Sources: [WCAG 2.2](https://www.w3.org/TR/WCAG22/), [Playwright best practices](https://playwright.dev/docs/best-practices).
