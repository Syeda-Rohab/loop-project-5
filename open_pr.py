#!/usr/bin/env python
"""open_pr.py — only ever called after reviewer.py exits with PASS."""

import subprocess
import sys


def open_pr(branch, worktree_path, title, body):
    log = subprocess.run("git log -1 --oneline", cwd=worktree_path, shell=True,
                          capture_output=True, text=True).stdout.strip()
    content = f"""# Pull Request (simulated — no GitHub remote in this demo)

**Branch:** {branch}
**Latest commit:** {log}

## Title
{title}

## Description
{body}

---
To make this a real PR with a GitHub remote + gh CLI set up:
    gh pr create --title "{title}" --body "{body}" --base main --head {branch}
"""
    with open(f"{worktree_path}/PR_DRAFT.md", "w") as f:
        f.write(content)
    print(f"[open_pr] PR opened for branch '{branch}'.")
    print(f"[open_pr] Draft written to {worktree_path}/PR_DRAFT.md")


if __name__ == "__main__":
    branch, worktree_path, title, body = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    open_pr(branch, worktree_path, title, body)
