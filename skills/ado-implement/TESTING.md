# Test layers

Reference for step 6 of [`ado-implement`](SKILL.md). Every acceptance criterion maps to at least one layer below; the test plan names the layer and the seam for each.

Use the repo's existing runners and helpers first. Find them in the environment: package scripts, `*.csproj` test references, `pyproject.toml`, `playwright.config.*`, CI workflows. Adding a new framework or package is a decision for the user, raised at the test-plan gate.

## Choosing layers

| Change | Layers |
|---|---|
| Logic, domain rules, API handlers | Unit, plus an integration test at the API seam when the criterion is about the contract |
| Web UI | Unit for the logic behind it, a Playwright UI test per user flow in the criteria, and an accessibility test for every changed view |
| Bug | A regression test that goes **red** on the repro steps before the fix, at the lowest layer that reproduces it |
| Config, docs, build only | None; state why in the PR's Evidence |

## Unit

- Test behaviour through public interfaces; a test reads like the criterion it proves.
- Expected values come from the work item (a literal, a worked example), never recomputed the way the code computes them.
- If the `tdd` skill is installed, follow it for the red → green loop.

## Accessibility

Run on every changed view, and scope the scan to the region you changed so pre-existing violations elsewhere get reported, not silently fixed in this PR.

JavaScript / TypeScript with Playwright ([docs](https://playwright.dev/docs/accessibility-testing)):

```ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('profile form has no detectable a11y violations', async ({ page }) => {
  await page.goto('/settings');
  const results = await new AxeBuilder({ page })
    .include('#profile-form')
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

- Other stacks: `Deque.AxeCore.Playwright` (.NET), `axe-playwright-python` (Python), `jest-axe` / `vitest-axe` for component tests.
- Keyboard: a Playwright test that reaches every new control with `Tab`, activates it with `Enter`/`Space`, and closes overlays with `Escape`, asserting focus lands where expected.
- Locate by role and accessible name (`getByRole('button', { name: 'Save' })`); the locator itself proves the control has a name.
- Automated scans catch only part of WCAG. List the manual checks still owed (screen reader pass, 200% zoom, contrast in hover/focus/error states) in the PR's Evidence.

## UI tests (Playwright)

For websites. Best practices: [playwright.dev/docs/best-practices](https://playwright.dev/docs/best-practices).

- No Playwright yet: propose `npm init playwright@latest` (or the stack's equivalent: `Microsoft.Playwright`, `pytest-playwright`) at the gate, with `webServer` and `baseURL` set in the config so tests start the app themselves.
- One test per user flow in the acceptance criteria, named after the criterion.
- Locators: `getByRole`, `getByLabel`, `getByText`, then `getByTestId`; CSS and XPath only as a last resort.
- Web-first assertions (`await expect(locator).toBeVisible()`) that auto-wait; a fixed `waitForTimeout` makes the test flaky.
- Each test isolated: its own data and state, runnable alone and in any order.
- Failure: rerun with `--trace on` and read the trace before changing code.
- Evidence: capture a screenshot of the finished flow (`page.screenshot({ path })`) for the PR's before/after.
