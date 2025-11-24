#!/bin/bash
# Setup Demo Repository on CentOS VM
# Run this script AFTER creating the 'demo-app' project in GitLab

# Configuration
GITLAB_URL="http://localhost"
PROJECT_NAME="demo-app"
USER_NAME="root"
# You might need to change this if you set a different password
PASSWORD="initial_root_password_or_your_new_password" 

echo "=== Setting up Demo Repository ==="

# 1. Configure Git Global Settings (if not already set)
git config --global user.name "Administrator"
git config --global user.email "admin@example.com"

# 2. Navigate to demo-app directory
cd ~/cloud-native-devops-platform/demo-app || { echo "❌ demo-app directory not found"; exit 1; }

# 3. Initialize Git
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
    git checkout -b main
else
    echo "Git repository already initialized."
fi

# 4. Add Remote
# Remove existing remote if it exists
git remote remove origin 2>/dev/null
# Add new remote pointing to local GitLab
echo "Adding remote origin..."
# Note: Using localhost for internal push
git remote add origin "$GITLAB_URL/$USER_NAME/$PROJECT_NAME.git"

# 5. Add and Commit Files
echo "Adding files..."
git add .
git commit -m "Initial commit for demo" || echo "Nothing to commit"

# 6. Push to GitLab
echo "Pushing to GitLab..."
echo "⚠️  You might be asked for your GitLab username (root) and password."
git push -u origin main

echo "=== Done! Check GitLab for the new project and pipeline ==="
