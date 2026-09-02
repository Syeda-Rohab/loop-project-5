# Project 5: Codify the Body

Project 4's fix loop, turned into **one re-runnable unit** (an
"engine") — then proven that it is NOT a loop, because it has no
memory between runs.

- **Time:** 1–1.5 hrs
- **Difficulty:** medium to hard
- **Concepts used:** Concept 8 (worktree), Concept 11 (maker-checker), the dynamic-workflows interlude

## The plain-words description of the workflow
> "Use a workflow to draft fixes for three candidates in parallel
> worktrees, and have a reviewer grade each one."

That's it — one sentence, and `run_workflow.ps1` / `run_workflow.sh`
is what executes it end to end, with no step-by-step prompting.

## Files
| File | Role |
|---|---|
| `1_setup.bat` | One-time setup — git init + first commit |
| `2_run_workflow.bat` | **The one command.** Double-click this. |
| `run_workflow.ps1` | The codified body (Windows/PowerShell) |
| `run_workflow.sh` | Same logic in bash (for reference / Linux/Mac) |
| `calculator.py` / `test_calculator.py` | The bug + the spec |
| `apply_good_fix.py` | Candidate 1: a correct, complete fix |
| `apply_bad_fix.py` | Candidate 2: a deliberately incomplete fix |
| `apply_cheat_fix.py` | Candidate 3: "fixes" it by weakening the test |
| `reviewer.py` | The checker — same one from Project 4 |
| `open_pr.py` | Called only when the reviewer says PASS |

## How the fan-out works
`run_workflow.ps1` starts 3 `Start-Job` background jobs (PowerShell's
equivalent of bash `&`), one per candidate. Each job:
1. Creates its own isolated `git worktree` (Concept 8) — no candidate
   can see or interfere with another's changes.
2. Writes its candidate fix into that worktree.
3. Commits.
4. Runs `reviewer.py` (Concept 11: maker-checker) against its own
   worktree, capturing PASS/FAIL and the reasons.
5. If PASS, calls `open_pr.py`.

`Wait-Job` (bash: `wait`) blocks until all three finish, then results
are collected and printed together. The reviewer's exit code — 0 or 1
— is literally the checker: no LLM judgment call, just a real signal.

## Proof #1: one command runs the whole body
Running `2_run_workflow.bat` once produces, with zero further input
from me:
```
--- Candidate: good  -> PASS ---   (PR opened)
--- Candidate: bad   -> FAIL ---   (tests don't pass)
--- Candidate: cheat -> FAIL ---   (touched the test file — caught)
```
Three isolated checkouts, three independent verdicts, one PR opened —
all from one command.

## Proof #2: it is not a loop
I ran the script twice in a row without changing anything in between.
**Run 1** and **Run 2** produced byte-for-byte identical verdicts:
```
Run 1: good -> PASS, bad -> FAIL, cheat -> FAIL
Run 2: good -> PASS, bad -> FAIL, cheat -> FAIL   (identical — no memory)
```
No file anywhere in the repo records that a previous run happened.
Search the directory after running twice — there is no `progress.md`,
no state file, nothing. The second run does not know the first run
ever occurred; it just redoes the same fixed work.

This is the interlude's warning, confirmed on my own machine: **a
workflow is an engine, not a loop.** It executes a fixed body
completely and correctly every time it's triggered, but it has no
concept of "last time."

## What it would need to become a loop
Two things, named explicitly:
1. **A heartbeat** — something that fires the workflow on its own
   schedule (a cron job / Windows Task Scheduler entry / systemd
   timer), instead of me double-clicking it. Concept 6 from Project 3.
2. **A progress file its agents write** — a small state file (like
   Project 3's `progress.md`) that each run reads before acting and
   updates after acting, so run N+1 can tell what run N already did
   (which candidates were already tried, which PRs already exist) and
   build on it instead of blindly repeating identical work.

Without both of those, what we have here is correctly described as an
**engine**: a reliable, single-shot, fully-automated unit of work —
not a loop.

## Running it yourself (Windows)
1. Put all files in one folder.
2. Double-click `1_setup.bat` once.
3. Double-click `2_run_workflow.bat` — watch all 3 candidates run in
   parallel and get graded.
4. Double-click `2_run_workflow.bat` again — confirm the output is
   identical to the first run, proving no memory exists.

## Cleaning up
```
git worktree remove ..\wf-fix-good --force
git worktree remove ..\wf-fix-bad --force
git worktree remove ..\wf-fix-cheat --force
```

## Note on the source docs
Dynamic workflows are a research preview. Where this project and
Anthropic's live docs disagree, the docs win:
https://agentfactory.panaversity.org/docs/loop-engineering-crash-course#11b-codify-the-body
