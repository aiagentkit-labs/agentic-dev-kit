#!/usr/bin/env python3
"""Central registry for repo policy topics and their default customization paths.

This keeps the configuration surface explicit for the review and guardrail
systems: each topic declares its default file path, repo override path, valid
severities, and merge mode.
"""

from __future__ import annotations

import argparse
import json
from typing import Dict, List

TOPIC_REGISTRY: Dict[str, Dict[str, object]] = {
    "security": {
        "default_path": "review-controls/security.md",
        "repo_override_path": ".github/review-controls/security.md",
        "valid_severities": ["blocker", "should-fix", "nit", "escalate", "setup", "off"],
        "merge_mode": "merge",
        "applied_by": "Security Reviewer",
    },
    "privacy": {
        "default_path": "review-controls/privacy.md",
        "repo_override_path": ".github/review-controls/privacy.md",
        "valid_severities": ["blocker", "should-fix", "nit", "escalate", "setup", "off"],
        "merge_mode": "merge",
        "applied_by": "Privacy Reviewer",
    },
    "testing": {
        "default_path": "testing-controls/testing.md",
        "repo_override_path": ".github/testing-controls/testing.md",
        "valid_severities": ["blocker", "should-fix", "nit", "escalate", "setup", "off"],
        "merge_mode": "merge",
        "applied_by": "PR Reviewer / ado-implement",
    },
    "practices": {
        "default_path": "practice-controls/practices.md",
        "repo_override_path": ".github/practice-controls/practices.md",
        "valid_severities": ["blocker", "should-fix", "nit", "escalate", "setup", "off"],
        "merge_mode": "merge",
        "applied_by": "ado-implement / PR Reviewer",
    },
    "lint": {
        "default_path": "lint-controls/lint.md",
        "repo_override_path": ".github/lint-controls/lint.md",
        "valid_severities": ["blocker", "should-fix", "nit", "escalate", "setup", "off"],
        "merge_mode": "merge",
        "applied_by": "Lint Runner / PR Reviewer",
    },
}


def list_topics() -> List[str]:
    return list(TOPIC_REGISTRY.keys())


def get_topic(topic: str) -> Dict[str, object]:
    key = topic.strip().lower()
    if key not in TOPIC_REGISTRY:
        raise KeyError(f"Unknown policy topic: {topic}")
    return TOPIC_REGISTRY[key]


def main() -> int:
    parser = argparse.ArgumentParser(description="List the formal topic registry for policy configuration.")
    parser.add_argument("--list", action="store_true", help="List all policy topics.")
    parser.add_argument("--topic", help="Show metadata for a single policy topic.")
    args = parser.parse_args()

    if args.topic:
        print(json.dumps(get_topic(args.topic), indent=2, sort_keys=True))
        return 0

    if args.list:
        print(" ".join(list_topics()))
        return 0

    print(json.dumps(TOPIC_REGISTRY, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
