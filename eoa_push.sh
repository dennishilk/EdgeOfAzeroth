#!/usr/bin/env bash

# Edge Of Azeroth Git Push Script
# Field Research Workflow Edition

echo "-----------------------------------"
echo " Edge Of Azeroth – Git Push Tool"
echo "-----------------------------------"
echo ""

# Check if we're inside a git repo
if [ ! -d ".git" ]; then
    echo "❌ This directory is not a git repository."
    exit 1
fi

# Show status
echo "📦 Current changes:"
git status
echo ""

# Check if there are changes
if [ -z "$(git status --porcelain)" ]; then
    echo "✔ No changes to commit."
    exit 0
fi

# Ask for commit message
echo "✍ Enter commit message:"
read COMMIT_MSG

if [ -z "$COMMIT_MSG" ]; then
    echo "❌ Commit message cannot be empty."
    exit 1
fi

# Add only changed files
git add -u
git add .

# Commit
git commit -m "$COMMIT_MSG"

# Push
echo ""
echo "🚀 Pushing to GitHub..."
git push

echo ""
echo "✔ Done."
