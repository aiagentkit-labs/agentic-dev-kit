# Baselines

How to set up the default baselines (`LINT-10` to `LINT-12` in the [lint controls](../../lint-controls/lint.md)) for [`lint`](SKILL.md) step 2. Where the repo overrides one of them, set up what the override names instead. Add only the missing pieces, merge into files that already exist, and install with the repo's package manager.

## TypeScript / JavaScript

Keep Biome where the repo already uses it. For Expo or React Native, run `npx expo lint`, which installs and configures `eslint-config-expo`, then add Prettier below.

Install, dropping `typescript` and `typescript-eslint` for plain JavaScript:

```bash
npm install --save-dev eslint @eslint/js typescript typescript-eslint prettier eslint-config-prettier
```

`eslint.config.mjs`:

```js
// @ts-check
import js from '@eslint/js';
import { defineConfig, globalIgnores } from 'eslint/config';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier/flat';

export default defineConfig(
  globalIgnores(['dist/', 'build/', 'coverage/']),
  {
    files: ['**/*.{js,cjs,mjs,jsx,ts,cts,mts,tsx}'],
    extends: [js.configs.recommended, tseslint.configs.recommended],
  },
  prettier,
);
```

`eslint-config-prettier` goes last: it turns off the rules that fight the formatter, so ESLint finds bugs and Prettier owns layout.

`.prettierrc.json` holds `{}`: Prettier's defaults, so nobody debates style. Prettier 3 skips what `.gitignore` lists; add a `.prettierignore` only for anything else.

`package.json` scripts:

```json
{
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "format": "prettier --write .",
  "format:check": "prettier --check ."
}
```

Options to ask about:

- **Type-aware rules**: `tseslint.configs.recommendedTypeChecked` with `languageOptions.parserOptions.projectService: true` catches floating promises and unsafe `any`, at the cost of slower runs. Recommend for TypeScript apps. See [typed linting](https://typescript-eslint.io/getting-started/typed-linting).
- **React**: `eslint-plugin-react-hooks`, plus `eslint-plugin-jsx-a11y`, which catches at edit time some of what the axe tests in [TESTING.md](../ado-implement/TESTING.md) catch at run time. Use each plugin's flat-config snippet from its README.
- **Globals**: `languageOptions.globals` from the `globals` package for browser or Node code.

## .NET

`.editorconfig` at the repo root, from `dotnet new editorconfig` (the SDK's defaults, with `root = true`).

`Directory.Build.props` at the repo root, applied to every project:

```xml
<Project>
  <PropertyGroup>
    <AnalysisLevel>latest-recommended</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>
</Project>
```

- On a codebase with many existing findings, start at `latest-minimum` and raise the level in later PRs.
- Code-style rules (`IDExxxx`) at `suggestion` severity never fail a check. Set `dotnet_diagnostic.<ID>.severity = warning` in `.editorconfig` for each one the team wants enforced.
- `IDE0005` (unnecessary usings) reports in the build only with `<GenerateDocumentationFile>true</GenerateDocumentationFile>`. Pair it with `<NoWarn>$(NoWarn);CS1591</NoWarn>` so missing XML docs don't flood the output.

Options to ask about:

- **Nullable reference types**: `<Nullable>enable</Nullable>`. On existing code it surfaces many warnings, so land it as its own PR.
- **StyleCop.Analyzers**: stricter layout and documentation rules, configured through `.editorconfig`.
- **Warnings as errors**: in CI only, with `dotnet build -warnaserror`, so local builds stay usable mid-change.

## CI

Run the check commands where the repo's pipeline builds: `npm run lint`, `npm run format:check`, and `dotnet format --verify-no-changes`.
