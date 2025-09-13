#!/bin/bash

# Scout AI Deployment Preparation Script
# This script helps prepare changes for deployment to Azure VM

set -e

echo "🚀 Scout AI - Deployment Preparation"
echo "=================================="

# Check we're in the right directory
if [ ! -f "docker-compose.dev-light.yml" ]; then
    echo "❌ Error: Must be run from the scout-dev directory"
    exit 1
fi

# Check current git status
echo "📋 Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Warning: You have uncommitted changes"
    echo "   Please commit your changes first:"
    echo "   git add ."
    echo "   git commit -m 'Your commit message'"
    echo "   git push origin $(git branch --show-current)"
    exit 1
fi

echo "✅ Git status clean"

# Show current branch and recent commits
echo ""
echo "📍 Current branch: $(git branch --show-current)"
echo "📝 Recent commits:"
git log --oneline -5

echo ""
echo "🔍 Changes since last deployment:"
echo "(This would show differences from production - feature coming soon)"

echo ""
echo "📦 Deployment checklist:"
echo "  [ ] Local testing completed"
echo "  [ ] All changes committed and pushed to GitHub"
echo "  [ ] Functions tested (if any changes)"
echo "  [ ] Environment variables verified"
echo "  [ ] Ready to deploy to Azure VM"

echo ""
echo "📋 Files ready for deployment:"
echo "  - docker-compose.yml (production config)"
echo "  - functions/ (custom functions)"
echo "  - Any other changed files"

echo ""
echo "⏭️  Next steps:"
echo "  1. SSH to Azure VM: ssh user@your-vm-ip"
echo "  2. Navigate to scout-dev-deployment directory"
echo "  3. Pull changes (deployment script coming soon)"
echo "  4. Test deployment"

echo ""
echo "✅ Preparation complete! Ready for deployment."