#!/bin/bash
# GitHub Sync Script - Daily automation at 3:00 AM HKT
# Pushes local git changes to GitHub

cd /Users/alexlam/.openclaw/workspace

# Check if there are any uncommitted changes
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Nothing to sync. Skipping."
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Changes detected, syncing to GitHub..."

# Stage all changes
git add . 2>&1

# Create a commit with timestamp
git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')" 2>&1

# Push to origin
git push 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync successful."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync FAILED (exit code: $EXIT_CODE)"
    exit $EXIT_CODE
fi
