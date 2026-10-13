---
name: unit-test
description: Write and run unit tests for .NET and TypeScript/JavaScript through an interview, test-first for new behaviour and as characterization tests for existing code. Use when the user asks to add, fix, or review unit tests or raise coverage, mentions xUnit, NUnit, MSTest, Vitest, or Jest, or when another skill reaches its unit-test layer.
---

Write unit tests that prove behaviour through public interfaces and go **red** when it breaks. The repo's test framework, layout, and helpers come first; the merged `testing` controls set the bar.

- **On its own** (`/unit-test`): use the interview mode from [ado-implement step 0](../ado-implement/SKILL.md#0-pick-the-interview-mode), with each gate a round in the format of [ado-implement's Rounds](../ado-implement/SKILL.md#rounds). Open each gate with `Unit test · Step N · Round k`.
- **Inside another skill** (`ado-implement` step 6, `pr-review` fixes): use that skill's mode and its checklist as the source of cases, and fold this skill's gates into its current round.

**Controls**: take the merged `testing` controls from the calling skill, or read them with [controls.sh](../../scripts/controls.sh) `testing --ref origin/<base>` ([CONTROLS.md](../../CONTROLS.md)). The unit ones are `TST-01` to `TST-08`. List any the repo turned off in the first round.

Each run takes one of three branches:

- **New behaviour**: red → green, one case at a time.
- **Bug**: a regression test that goes red on the repro steps first (`TST-04`), then the fix.
- **Existing code**: **characterization** tests that pin what the code does today, before anyone changes it.

## 1. Detect

| | .NET | TypeScript / JavaScript |
|---|---|---|
| Framework | `xunit`, `NUnit`, or `MSTest` package references in the test projects | `vitest` or `jest` in `package.json`, or `node:test` |
| Layout | `*.Tests` projects that mirror the project under test | Whatever the repo does: `*.test.ts` beside the code, or `__tests__/` |
| Doubles | `Moq`, `NSubstitute`, `FakeItEasy`, `TimeProvider` (.NET 8+) | `vi.fn` / `vi.useFakeTimers()`, `jest.fn` / `jest.useFakeTimers()` |
| Run one | `dotnet test <project> --filter "FullyQualifiedName~<Class>.<Method>"` | `npx vitest run <file> -t "<name>"`, `npx jest <file> -t "<name>"` |
| Run all | `dotnet test <solution>` | The repo's `test` script |
| Coverage | `dotnet test --collect "XPlat Code Coverage"` (needs `coverlet.collector`), which writes `coverage.cobertura.xml` | `npx vitest run --coverage` (needs `@vitest/coverage-v8`), `npx jest --coverage` |

With no test project or framework, propose one at the step 2 gate: `dotnet new xunit` (it includes `coverlet.collector`), or Vitest for TypeScript.

Run the whole suite once and record its result, so failures that were already there aren't blamed on this change.

Done when you can run a single test and the whole suite, and the suite's starting result is recorded.

## 2. Choose seams and cases

A **seam** is the public interface where behaviour is observable: a domain class's public method, an exported function, a module's entry point. Test there, never against private members. A handler tested through its web host is an integration test (`TST-03`); say so and keep it out of this skill's scope.

For each seam, list the cases:

- every acceptance criterion or checklist entry it serves (`TST-01`), with expected values from the work item (`TST-02`)
- the edges that matter for this code: empty, boundary, invalid input, and each error path
- for existing code, each behaviour a coming change could break

Inject a double only for a boundary the code doesn't own (`TST-06`); a collaborator the repo owns is used for real. When a seam can't take a double because the code creates its own clock, client, or connection, propose the smallest change that injects it, and ask before making it.

**Gate**: a table of seam, case, expected value, and the source of that value (criterion, worked example, or "current behaviour"), plus any new package or framework. Done when the user confirms the cases.

## 3. Write and run

One case at a time, at the seams agreed in step 2:

- **Shape**: arrange, act, assert, with one behaviour per test, named for it (`TST-08`): `Total_is_zero_for_an_empty_cart`, `it('returns zero for an empty cart')`. Cases that differ only in data share one test: `[Theory]` with `[InlineData]`, `[TestCase]`, `[DataRow]`, or `it.each`.
- **New behaviour and bugs**: run the test and watch it fail for the reason it exists, an assertion or the missing member it calls (`TST-07`). Then write the least code that passes it, and rerun.
- **Existing code**: write the assertion you expect, and run it. When it fails, the code does something else: show the user the actual result and ask whether it's intended (pin it) or a bug (record it, and leave the test asserting the correct behaviour, marked skipped with the bug's ID). Then break the code under test briefly, see the test go red (`TST-07`), and restore it.
- **Deterministic** (`TST-05`): inject the clock and randomness, fake timers instead of waiting, and give each test its own data.

Done when every confirmed case passes, every new test has been seen failing, and the whole suite is no worse than its starting result.

## 4. Coverage

When the user asks, or before changing existing code: run coverage for the touched files. Report the uncovered branches, ranked by the risk of a bug hiding there, and propose cases for those worth a test. A percentage is a symptom, not a goal; aim at one only when the repo's controls set it.

Done when every uncovered branch in the touched files is tested, or the user has decided to leave it.

## 5. Report

The tests added per seam, the run that shows them passing, the starting and final suite results, coverage before and after when measured, and every bug found while characterizing. In teach mode, cite the source for each practice used: [.NET unit testing best practices](https://learn.microsoft.com/dotnet/core/testing/unit-testing-best-practices), [Vitest](https://vitest.dev/guide/), [Jest](https://jestjs.io/docs/getting-started).

If the `tdd` skill is installed, its guidance on seams, mocking, and anti-patterns applies here too.
