#!/usr/bin/env python3
"""Shared policy loader for repo-level configuration overlays.

This script resolves the default -> shared -> repo merge order used by the
agentic-dev-kit guardrail config and other policy surfaces.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tempfile


def parse(path):
    data = {"mode": "merge", "extends": None, "deny": [], "ask": []}
    if not path or not os.path.exists(path):
        return data

    current = None
    invalid = False
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.rstrip()
            stripped = line.strip()
            if not stripped or stripped.startswith("#") or stripped in {"---", "..."}:
                continue
            if stripped.startswith("extends:"):
                spec = stripped.split(":", 1)[1].strip().strip("\"'")
                if not spec or "#" not in spec:
                    invalid = True
                else:
                    full_url, rest = spec.split("#", 1)
                    if not full_url or ":" not in rest:
                        invalid = True
                    else:
                        ref, file_path = rest.split(":", 1)
                        if not ref or not file_path:
                            invalid = True
                        else:
                            data["extends"] = spec
                continue
            if stripped.startswith("mode:"):
                mode = stripped.split(":", 1)[1].strip().strip("\"'")
                if mode in {"merge", "replace"}:
                    data["mode"] = mode
                else:
                    invalid = True
                continue
            if stripped in {"deny:", "ask:", "allow:"}:
                current = stripped[:-1]
                continue
            if stripped.startswith("- ") and current:
                item = stripped[2:].strip().strip("\"'")
                if item:
                    data.setdefault(current, []).append(item)
                continue
            if stripped.startswith("-") and current:
                invalid = True
                continue
            if stripped and current is None and not stripped.startswith("#"):
                invalid = True

    if invalid:
        return {"mode": "merge", "extends": None, "deny": [], "ask": []}
    return data


def fetch_shared(spec):
    if not spec or "#" not in spec:
        return None
    full_url, rest = spec.split("#", 1)
    if ":" not in rest:
        return None
    ref, path = rest.split(":", 1)
    if not full_url or not ref or not path:
        return None

    tmp = tempfile.mkdtemp(prefix="policy-loader-")
    clone = subprocess.run(
        [
            "git",
            "clone",
            "--quiet",
            "--depth",
            "1",
            "--branch",
            ref,
            full_url,
            os.path.join(tmp, "src"),
        ],
        env={
            **os.environ,
            "GIT_TERMINAL_PROMPT": "0",
            "GIT_SSH_COMMAND": os.environ.get("GIT_SSH_COMMAND", "ssh -o BatchMode=yes"),
        },
        capture_output=True,
        text=True,
    )
    if clone.returncode != 0:
        return None

    candidate = os.path.join(tmp, "src", path)
    if not os.path.exists(candidate):
        return None
    return candidate


def fetch_shared_content(spec):
    candidate = fetch_shared(spec)
    if not candidate or not os.path.exists(candidate):
        return ""
    return open(candidate, encoding="utf-8").read()


def merge(base, extra, mode):
    merged = {"deny": list(base.get("deny", [])), "ask": list(base.get("ask", []))}
    if mode == "replace":
        merged = {"deny": [], "ask": []}
    for key in ("deny", "ask"):
        for item in extra.get(key, []):
            if item not in merged[key]:
                merged[key].append(item)
    return merged


def effective_rules(default_path, repo_path, cmd):
    config = parse(default_path)
    if repo_path and os.path.exists(repo_path):
        repo_cfg = parse(repo_path)
        shared_path = fetch_shared(repo_cfg.get("extends"))
        if shared_path:
            shared_cfg = parse(shared_path)
            config = merge(config, shared_cfg, "merge")
        config = merge(config, repo_cfg, repo_cfg.get("mode", "merge"))

    for key in ("deny", "ask"):
        for rule in config.get(key, []):
            if re.search(rule, cmd, re.IGNORECASE):
                return f"{key}\t{rule}"
    return ""


def main():
    parser = argparse.ArgumentParser(description="Resolve layered policy rules for guardrails or shared policy configs.")
    parser.add_argument("--default", dest="default_path", default="")
    parser.add_argument("--repo", dest="repo_path", default="")
    parser.add_argument("--command", dest="command", default="")
    parser.add_argument("--fetch-shared", dest="fetch_shared_spec", default="")
    args = parser.parse_args()

    if args.fetch_shared_spec:
        print(fetch_shared_content(args.fetch_shared_spec), end="")
        return 0

    result = effective_rules(args.default_path, args.repo_path, args.command)
    if result:
        print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
