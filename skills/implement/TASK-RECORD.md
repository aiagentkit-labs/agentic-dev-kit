# Task record format

A task record is a human-readable Markdown file that preserves the agreed task and its verification evidence when there is no external tracker, or when the user wants a local copy. Default path: `work-items/<slug>.md`; ask before creating it and never overwrite an existing file.

```markdown
---
title: Persist private extraction state
status: accepted
source:
  type: text
  key: null
  url: null
  path: null
  capabilities: []
---

## Problem

Describe who is affected, the problem, and why it matters.

## Acceptance criteria

- [ ] AC-01: Given ..., when ..., then ...
- [ ] AC-02: Given ..., when ..., then ...

## Constraints and context

- Relevant technical or product constraints.

## Implementation plan

- [ ] Test layer and check for AC-01
- [ ] Test layer and check for AC-02

## Evidence

- Tests: pending
- Pull request: pending
```

Rules:

- `source.type` is `ado`, `jira`, another provider name, `text`, or `file`.
- Keep a provider's issue key and URL when one exists. For file input, record the path the user supplied. Use `null` where a value doesn't apply; never invent an issue ID.
- `source.capabilities` lists only operations the connected adapter actually supports: `read`, `update`, `link_pr`, or `create_child`. For pasted text and local files, keep it empty.
- Acceptance criteria are numbered, independent, and testable. Add one evidence entry per criterion as implementation completes.
- The record is not a tracker and does not imply that an external issue was updated. External writes still require the user's approval and a connected provider adapter.
- Do not copy credentials, secrets, or unnecessary personal data into the record.
