#!/usr/bin/env bash
# setup.sh - Initialize git fixture
# Run this once to create the git repo fixture
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/repo"

# Clean up existing
rm -rf "$REPO_DIR" "$SCRIPT_DIR/remote.git"

# Create repo directory
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

# Initialize git
git init --quiet
git config user.email "test@example.com"
git config user.name "Test User"

# Initial commit
echo "# Test Repository" > README.md
echo "" >> README.md
echo "This is a test repository for git fixture tests." >> README.md
git add README.md
git commit -m "Initial commit" --quiet

# Second commit
echo "committed content" > committed.txt
git add committed.txt
git commit -m "Add committed file" --quiet

# Third commit
echo "more committed content" >> committed.txt
git commit -am "Update committed file" --quiet

# Create feature branch
git checkout -b feature --quiet
echo "feature work in progress" > feature.txt
git add feature.txt
git commit -m "Feature work" --quiet
git checkout main --quiet

# Stage a change (not committed)
echo "staged but not committed" > staged.txt
git add staged.txt

# Create untracked file
echo "untracked content" > untracked.txt

# Create local bare repo as "remote"
mkdir -p "$SCRIPT_DIR/remote.git"
git clone --bare "$REPO_DIR" "$SCRIPT_DIR/remote.git" --quiet

# Add remote
git remote add origin "$SCRIPT_DIR/remote.git"

echo "Git fixture created at $REPO_DIR"
echo "  - 3 commits on main"
echo "  - 1 commit on feature branch"
echo "  - 1 staged file (staged.txt)"
echo "  - 1 untracked file (untracked.txt)"
echo "  - bare remote at $SCRIPT_DIR/remote.git"
