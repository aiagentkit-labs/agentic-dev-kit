# Copilot instructions

## Local documentation export

When a doc needs to be exported to PDF or HTML, do not rebuild it ad hoc in chat or as a one-off prompt flow.

Use the repo-local generator in the git-ignored docs folder instead:

```bash
python3 .agentic-dev-kit/generate_doc_pdf.py .agentic-dev-kit/GUARDRAILS-GUIDE.md .agentic-dev-kit/GUARDRAILS-GUIDE.pdf
```

This avoids repeated token-heavy regeneration and keeps the documented output reproducible and reviewable.

Rules:
- keep generated docs under `.agentic-dev-kit/`
- prefer the repo-local generator over re-rendering markdown through chat
- update the source markdown first, then regenerate the PDF from the same script
- do not duplicate ad hoc export commands in prompts when the script already exists

This repo intentionally keeps local research and generated artifacts in `.agentic-dev-kit/`, which is git-ignored.
