#!/usr/bin/env python
"""
reviewer.py — the checker in the maker-checker loop.
Grades a fix in a worktree. Prints PASS or FAIL with reasons.
Exit code 0 = PASS, 1 = FAIL.
"""

import subprocess
import sys


def run(cmd, cwd):
    return subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True)


def review(base_ref, worktree_path, test_file):
    reasons_pass = []
    reasons_fail = []

    test_result = run("python -m pytest -q", worktree_path)
    tests_passed = test_result.returncode == 0
    if tests_passed:
        reasons_pass.append("All tests pass.")
    else:
        tail = "\n".join(test_result.stdout.strip().splitlines()[-8:])
        reasons_fail.append(f"Tests do not pass. pytest output:\n{tail}")

    diff_files = run(f"git diff --name-only {base_ref}", worktree_path).stdout.split()
    if test_file in diff_files:
        reasons_fail.append(
            f"The diff modifies '{test_file}'. The implementer is not allowed "
            "to change the spec (the test) to force a pass."
        )
    else:
        reasons_pass.append(f"Test file '{test_file}' was not touched (spec left intact).")

    diff_text = run(f"git diff {base_ref}", worktree_path).stdout
    added_lines = [l for l in diff_text.splitlines() if l.startswith("+") and not l.startswith("+++")]
    debug_prints = [l for l in added_lines if "print(" in l]
    if debug_prints:
        reasons_fail.append(f"Found {len(debug_prints)} leftover debug print statement(s) in the diff.")
    else:
        reasons_pass.append("No debug prints left in the diff.")

    added_count = len(added_lines)
    if added_count > 40:
        reasons_fail.append(f"Diff adds {added_count} lines — too large for a scoped bug fix.")
    else:
        reasons_pass.append(f"Diff is appropriately scoped ({added_count} added lines).")

    verdict = "PASS" if not reasons_fail else "FAIL"
    return verdict, reasons_pass, reasons_fail


def main():
    base_ref, worktree_path, test_file = sys.argv[1], sys.argv[2], sys.argv[3]
    verdict, reasons_pass, reasons_fail = review(base_ref, worktree_path, test_file)

    print(f"=== Reviewer verdict: {verdict} ===\n")
    if reasons_pass:
        print("Checks satisfied:")
        for r in reasons_pass:
            print(f"  [ok] {r}")
    if reasons_fail:
        print("\nReasons for FAIL:")
        for r in reasons_fail:
            print(f"  [x] {r}")

    sys.exit(0 if verdict == "PASS" else 1)


if __name__ == "__main__":
    main()
