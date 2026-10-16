# Test layers

How to meet the [testing controls](../../testing-controls/testing.md) for step 6 of [`ado-implement`](SKILL.md); each section names the control IDs it serves. Read the merged controls first ([CONTROLS.md](../../CONTROLS.md)): where the repo overrides a control, the override wins over the how-to here, and the repo's `## Instructions` apply on top.

Use the repo's existing runners and helpers first. Find them in the environment: package scripts, `*.csproj` test references, `pyproject.toml`, `playwright.config.*`, CI workflows. Adding a new framework or package is a decision for the user, raised at the test-plan gate.

## Choosing layers (TST-01 to TST-04)

| Change | Layers |
|---|---|
| Logic, domain rules, API handlers | Unit, plus an integration test at the API seam when the criterion is about the contract |
| Web UI | Unit for the logic behind it, a UI test per user flow in the criteria, and an accessibility test for every changed view |
| Bug | A regression test that goes **red** on the repro steps before the fix |
| Config, docs, build only | None; state why in the PR's Evidence |

## Unit (TST-02)

- A test reads like the criterion it proves.
- Expected values are literal or taken from the agreed task specification, never recomputed the way the code computes them.
- If the `tdd` skill is installed, follow it for the red → green loop.

## Accessibility (A11Y-01 to A11Y-05)

Scope each scan to the region you changed, so pre-existing violations elsewhere get reported, not silently fixed in this PR.

JavaScript / TypeScript with Playwright ([docs](https://playwright.dev/docs/accessibility-testing)):

```ts
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('profile form has no detectable a11y violations', async ({ page }) => {
  await page.goto('/settings');
  const results = await new AxeBuilder({ page })
    .include('#profile-form')
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa']) // A11Y-02's tags
    .analyze();
  expect(results.violations).toEqual([]);
});
```

- Other stacks: `Deque.AxeCore.Playwright` (.NET), `axe-playwright-python` (Python), `jest-axe` / `vitest-axe` for component tests.
- Keyboard (A11Y-03): a Playwright test that moves through the new controls with `page.keyboard.press('Tab')` and asserts focus with `expect(locator).toBeFocused()`.
- Role locators (A11Y-04): `getByRole('button', { name: 'Save' })`; the locator itself proves the control has a name.
- Manual checks (A11Y-05): automated scans catch only part of WCAG, so list what a person still has to check.

## UI tests (UI-01 to UI-06)

Best practices: [playwright.dev/docs/best-practices](https://playwright.dev/docs/best-practices).

- No Playwright yet: propose `npm init playwright@latest` (or the stack's equivalent: `Microsoft.Playwright`, `pytest-playwright`) at the gate, then set `webServer` and `baseURL` in the config so tests start the app themselves.
- Web-first assertions such as `await expect(locator).toBeVisible()` auto-wait; a fixed `waitForTimeout` makes the test flaky.
- Failure: rerun with `--trace on` and read the trace before changing code.
- Evidence: `page.screenshot({ path })` at the end of the flow, for the PR's before/after.
