# Lint controls

The defaults the kit applies to linting and formatting: in the `lint` skill and its **Lint Runner**, and in the **PR Reviewer**'s Standards axis. The repo's own linter and formatter config sets the rules those tools enforce; these controls set how the kit runs them, and what it sets up where a repo has none ([SETUP.md](../skills/lint/SETUP.md) shows how). A repo tailors them with `.github/lint-controls/lint.md`; see [CONTROLS.md](../CONTROLS.md).

## Controls

| ID | Control | Severity |
|---|---|---|
| LINT-01 | Lint and format only the touched files; a whole-repo reformat lands as its own PR | should-fix |
| LINT-02 | Every check command exits 0 on the touched files before a commit | blocker |
| LINT-03 | TypeScript projects pass `tsc --noEmit` | blocker |
| LINT-04 | A suppression sits at the narrowest scope and carries its reason in the code | blocker |
| LINT-10 | TS/JS baseline: ESLint with the `@eslint/js` and `typescript-eslint` recommended configs, Prettier with its defaults, and `eslint-config-prettier` last | setup |
| LINT-11 | .NET baseline: `.editorconfig` from `dotnet new editorconfig`, `AnalysisLevel` `latest-recommended`, and `EnforceCodeStyleInBuild` on | setup |
| LINT-12 | Warnings fail the build in CI only | setup |
