# run_workflow.ps1 — the codified body (Concept 8: worktree, Concept 11: maker-checker)
#
# ONE command runs the whole draft-and-review body:
#   - 3 candidates drafted in parallel, isolated worktrees
#   - each graded independently by reviewer.py
#   - PASS -> PR opened, FAIL -> reasons printed, no PR
#
# Deliberately has NO memory / state file. Every run starts from nothing.
# Run this script twice to prove it: the second run repeats identical
# work instead of building on the first (see Project 5 README).

$candidates = @("good", "bad", "cheat")

Write-Host "=== Cleaning up any leftover worktrees from a previous run ===" -ForegroundColor Cyan
foreach ($c in $candidates) {
    git worktree remove "../wf-fix-$c" --force 2>$null | Out-Null
    git branch -D "fix/$c" 2>$null | Out-Null
}
git worktree prune | Out-Null

Write-Host ""
Write-Host "=== Fanning out: drafting $($candidates.Count) candidates in parallel worktrees ===" -ForegroundColor Cyan

$root = Get-Location

$jobs = foreach ($c in $candidates) {
    Start-Job -ScriptBlock {
        param($c, $root)
        Set-Location $root
        $wt = "../wf-fix-$c"

        git worktree add $wt -b "fix/$c" -q | Out-Null

        switch ($c) {
            "good"  { python apply_good_fix.py "$wt/calculator.py" | Out-Null }
            "bad"   { python apply_bad_fix.py "$wt/calculator.py" | Out-Null }
            "cheat" { python apply_cheat_fix.py "$wt/calculator.py" "$wt/test_calculator.py" | Out-Null }
        }

        Push-Location $wt
        git add -A | Out-Null
        git commit -q -m "Candidate fix: $c" | Out-Null
        Pop-Location

        $output = python reviewer.py main $wt test_calculator.py 2>&1
        $verdict = if ($LASTEXITCODE -eq 0) { "PASS" } else { "FAIL" }

        if ($verdict -eq "PASS") {
            $prOutput = python open_pr.py "fix/$c" $wt "Fix palindrome bug (candidate: $c)" "Automated candidate fix"
            $output += $prOutput
        }

        [PSCustomObject]@{
            Candidate = $c
            Verdict   = $verdict
            Output    = ($output -join "`n")
        }
    } -ArgumentList $c, $root
}

Wait-Job -Job $jobs | Out-Null
$results = Receive-Job -Job $jobs
Remove-Job -Job $jobs

Write-Host "=== All candidates drafted and reviewed ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== RESULTS ===" -ForegroundColor Yellow

foreach ($r in $results) {
    Write-Host ""
    $color = if ($r.Verdict -eq "PASS") { "Green" } else { "Red" }
    Write-Host "--- Candidate: $($r.Candidate) -> $($r.Verdict) ---" -ForegroundColor $color
    Write-Host $r.Output
}
