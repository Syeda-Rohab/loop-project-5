#!/usr/bin/env bash
# run_workflow.sh — the codified body (Concept 8: worktree, Concept 11: maker-checker)
#
# ONE command runs the whole draft-and-review body:
#   - 3 candidates drafted in parallel, isolated worktrees
#   - each graded independently by reviewer.py
#   - PASS -> PR opened, FAIL -> reasons printed, no PR
#
# Deliberately has NO memory/state file. Every run starts from nothing
# and redoes all the work — this is proven in Project 5's "not a loop" step.

set -e
CANDIDATES=("good" "bad" "cheat")

echo "=== Cleaning up any leftover worktrees from a previous run ==="
for c in "${CANDIDATES[@]}"; do
    git worktree remove "../wf-fix-$c" --force 2>/dev/null || true
    git branch -D "fix/$c" 2>/dev/null || true
done
git worktree prune

run_candidate() {
    local c=$1
    local wt="../wf-fix-$c"

    git worktree add "$wt" -b "fix/$c" -q

    case "$c" in
        good)  python3 apply_good_fix.py "$wt/calculator.py" ;;
        bad)   python3 apply_bad_fix.py "$wt/calculator.py" ;;
        cheat) python3 apply_cheat_fix.py "$wt/calculator.py" "$wt/test_calculator.py" ;;
    esac

    (cd "$wt" && git add -A && git commit -q -m "Candidate fix: $c")

    if python3 reviewer.py main "$wt" test_calculator.py > "/tmp/verdict_$c.txt" 2>&1; then
        echo 0 > "/tmp/exitcode_$c.txt"
    else
        echo 1 > "/tmp/exitcode_$c.txt"
    fi

    if [ "$(cat /tmp/exitcode_$c.txt)" = "0" ]; then
        python3 open_pr.py "fix/$c" "$wt" "Fix palindrome bug (candidate: $c)" "Automated candidate fix" >> "/tmp/verdict_$c.txt"
    fi
}

echo ""
echo "=== Fanning out: drafting 3 candidates in parallel worktrees ==="
for c in "${CANDIDATES[@]}"; do
    run_candidate "$c" &
done
wait
echo "=== All candidates drafted and reviewed ==="

echo ""
echo "=== RESULTS ==="
for c in "${CANDIDATES[@]}"; do
    ec=$(cat "/tmp/exitcode_$c.txt")
    verdict="FAIL"
    [ "$ec" = "0" ] && verdict="PASS"
    echo ""
    echo "--- Candidate: $c -> $verdict ---"
    cat "/tmp/verdict_$c.txt"
done
