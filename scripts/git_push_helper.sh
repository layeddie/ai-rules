#!/bin/bash

# Git Push Helper for .ai_rules Repository
# Helps resolve SSL/TLS issues when pushing to GitHub

set -e

echo "=== Git Push Helper for .ai_rules ==="
echo ""

# Check if we're in the right directory
if [ ! -f "git_rules.md" ]; then
    echo "Error: Must be run from .ai_rules directory"
    exit 1
fi

# Check current status
echo "Current branch: $(git branch --show-current)"
echo "Latest commits:"
git log --oneline -5
echo ""

# Show remote
echo "Remote configuration:"
git remote -v
echo ""

# Check if authenticated
echo "Checking GitHub authentication..."
if gh auth status &> /dev/null; then
    echo "✅ GitHub CLI is authenticated"
    gh auth status | grep "Logged in to github.com"
else
    echo "❌ GitHub CLI is not authenticated"
    echo "Run: gh auth login"
    exit 1
fi

echo ""
echo "=== Push Options ==="
echo ""
echo "1. Try HTTPS push (default)"
echo "2. Switch to SSH and push"
echo "3. Upload via GitHub web UI"
echo "4. Diagnose SSL issue"
echo ""

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo ""
        echo "Attempting HTTPS push..."
        echo ""

        # Try increasing buffer size
        echo "Setting HTTP buffer to 500MB..."
        git config http.postBuffer 524288000

        # Try pushing
        if git push -u origin main; then
            echo ""
            echo "✅ Push successful!"
        else
            echo ""
            echo "❌ Push failed. Try option 2 or 3."
            echo ""
            echo "To diagnose issue, run option 4."
        fi
        ;;

    2)
        echo ""
        echo "Setting up SSH..."

        # Check if SSH key exists
        if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
            echo "No SSH key found. Generating one..."
            ssh-keygen -t ed25519 -C "layeddie@gmail.com"
        fi

        # Add SSH key to GitHub
        echo ""
        echo "Adding SSH key to GitHub..."
        if command -v gh &> /dev/null; then
            if [ -f ~/.ssh/id_ed25519 ]; then
                gh ssh-key add ~/.ssh/id_ed25519.pub
            elif [ -f ~/.ssh/id_rsa ]; then
                gh ssh-key add ~/.ssh/id_rsa.pub
            fi
        fi

        # Change remote to SSH
        echo ""
        echo "Changing remote URL to SSH..."
        git remote set-url origin git@github.com:layeddie/ai-rules.git
        git remote -v

        # Test SSH connection
        echo ""
        echo "Testing SSH connection to GitHub..."
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo "✅ SSH connection successful"
        else
            echo "⚠️  SSH connection may need verification"
        fi

        # Push via SSH
        echo ""
        echo "Pushing via SSH..."
        if git push -u origin main; then
            echo ""
            echo "✅ Push successful!"
        else
            echo ""
            echo "❌ Push failed via SSH"
        fi
        ;;

    3)
        echo ""
        echo "Manual upload instructions:"
        echo ""
        echo "1. Visit: https://github.com/layeddie/ai-rules"
        echo "2. Click 'Add file' → 'Upload files'"
        echo "3. Select and upload all files from local repository"
        echo "4. Add commit message: 'feat: initial commit'"
        echo "5. Commit changes"
        echo ""
        echo "After uploading:"
        echo "1. git fetch origin"
        echo "2. git reset --hard origin/main"
        echo ""
        echo "Or use GitHub CLI:"
        echo "gh repo view layeddie/ai-rules --web"
        ;;

    4)
        echo ""
        echo "=== SSL Diagnosis ==="
        echo ""

        # Check git version
        echo "Git version: $(git --version)"
        echo ""

        # Check git SSL config
        echo "Git SSL settings:"
        git config --get-regexp "http.*ssl"
        echo ""

        # Check curl version
        echo "Curl version: $(curl --version | head -1)"
        echo ""

        # Test HTTPS connection
        echo "Testing HTTPS connection to GitHub..."
        if curl -I https://github.com &> /dev/null; then
            echo "✅ HTTPS connection works"
        else
            echo "❌ HTTPS connection failed"
        fi

        echo ""

        # Try small git push
        echo "Testing with small push..."
        if git push origin HEAD:main --dry-run 2>&1 | head -20; then
            echo "✅ Dry run successful"
        else
            echo "❌ Dry run failed"
        fi

        echo ""
        echo "=== Recommendations ==="
        echo ""
        echo "1. Try updating git: brew upgrade git"
        echo "2. Try updating curl: brew upgrade curl"
        echo "3. Try option 2 (SSH) which bypasses SSL"
        echo "4. Try option 3 (manual upload)"
        ;;

    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "=== Done ==="
