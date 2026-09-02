@echo off
echo === Setting up the repo (run this ONCE) ===
git init
git add -A
git commit -m "Initial commit: calculator with a real bug"
git branch -M main
echo.
echo === Setup done. Now double-click 2_run_workflow.bat ===
pause
