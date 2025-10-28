#!/bin/bash
# Simple Git Push Script
# Usage: ./git-push.sh

set -e

echo "=================================="
echo "Push to GitHub"
echo "=================================="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "ERROR: Git is not installed"
    exit 1
fi

# Initialize repo if needed
if [ ! -d ".git" ]; then
    echo "[1/5] Initializing Git repository..."
    git init
    git branch -M main
else
    echo "[1/5] Git repository exists"
fi

# Add remote
echo "[2/5] Setting remote..."
if ! git remote | grep -q "origin"; then
    git remote add origin https://github.com/xueyy-999/demo-devops-app.git
else
    git remote set-url origin https://github.com/xueyy-999/demo-devops-app.git
fi

# Add files
echo "[3/5] Adding files..."
git add .

# Commit
echo "[4/5] Committing..."
git commit -m "feat: Complete cloud-native DevOps platform"

# Push
echo "[5/5] Pushing to GitHub..."
echo ""
echo "You may need to enter your GitHub credentials:"
echo "Username: xueyy-999"
echo "Password: Use Personal Access Token (PAT)"
echo ""
echo "Get PAT at: https://github.com/settings/tokens"
echo ""

git push -u origin main

echo ""
echo "SUCCESS! Project pushed to GitHub"
echo "View at: https://github.com/xueyy-999/demo-devops-app"

