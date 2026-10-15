# Contributing

Thanks for helping. Anyone can open issues and pull requests; the [maintainers](.github/CODEOWNERS) review and merge.

## Report a bug or ask for a feature

Use the [issue forms](https://github.com/aiagentkit-labs/agentic-dev-kit/issues/new/choose). Leave out secrets, tokens, and private work-item content. Report a security problem privately, through **Security → Report a vulnerability**, not in an issue.

## Change something

1. Fork the repo and create a branch: `feat/<slug>`, `fix/<slug>`, or `docs/<slug>`.
2. Make the change, keeping one change per pull request.
3. Run the checks below.
4. Open a pull request against `main` that says what changed and why. A maintainer's approval is required to merge.

### Run the checks

```bash
bash scripts/guardrails.test.sh
bash scripts/guardrails-config.test.sh
bash scripts/shared-fetch.test.sh
bash scripts/validate-overrides.test.sh
```

Changed a guardrail rule? Add a case to `scripts/guardrails.test.sh` that fails without your change.

## Where things live

| What | Where |
|---|---|
| Skills | `skills/<name>/SKILL.md`; the folder name must match the skill's `name` |
| Custom agents | `com.github.copilot/agents/<name>.agent.md` |
| Guardrails hook | `scripts/guardrails.sh` (and `guardrails.ps1` for Windows), wired in `com.github.copilot/hooks/hooks.json` |
| Default controls | `review-controls/`, `testing-controls/`, `practice-controls/`, `lint-controls/`; merge rules in [CONTROLS.md](CONTROLS.md) |
| Docs site | `docs/`, published to [GitHub Pages](https://aiagentkit-labs.github.io/agentic-dev-kit/) |

Update the matching page under `docs/` in the same pull request when you change how something behaves.

## Releases

Maintainers bump `version` in `plugin.json`, merge, then tag the merge commit `v<version>` and publish a GitHub release. Installed copies update when the version changes.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
