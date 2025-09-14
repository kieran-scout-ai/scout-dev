#!/bin/bash
# Scout AI - Trigger Clean GitHub Deployment
# Usage: ./trigger-clean-deployment.sh [branch] [vm-user] [vm-ip]

set -e

BRANCH="${1:-main}"
AZURE_VM_USER="${2:-azureuser}"
AZURE_VM_IP="${3:-4.196.108.56}"

echo "🚀 Triggering CLEAN deployment from GitHub to Azure VM"
echo "Branch: $BRANCH | Target: $AZURE_VM_USER@$AZURE_VM_IP"
echo "⚠️  This will create a NEW deployment directory"
echo ""

# Check local changes
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Uncommitted changes detected. Please commit and push first."
    exit 1
fi

echo "📋 Deployment Details:"
echo "   • Source: GitHub repository"
echo "   • Branch: $BRANCH"
echo "   • Target: Clean deployment to ~/scout-dev-github/"
echo "   • Current deployment: Will remain untouched"
echo ""

read -p "Continue with clean deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Upload and execute clean deployment script
echo "📤 Uploading clean deployment script..."
scp deploy-github-clean.sh "$AZURE_VM_USER@$AZURE_VM_IP:~/"

# Trigger clean deployment on VM
echo "🚀 Executing clean deployment on VM..."
ssh -t "$AZURE_VM_USER@$AZURE_VM_IP" "
    chmod +x deploy-github-clean.sh
    ./deploy-github-clean.sh $BRANCH
"

echo ""
echo "✅ Clean deployment complete!"
echo ""
echo "🔧 Next Steps:"
echo "   1. Test the new deployment: http://$AZURE_VM_IP:3000"
echo "   2. Update nginx configuration to point to new deployment"
echo "   3. Test domain: demo.scout-ai.com.au"
echo "   4. Stop old deployment when satisfied"
echo ""
echo "📁 Directory Structure on VM:"
echo "   • Old deployment: ~/scout-dev-deployment/"
echo "   • New deployment: ~/scout-dev-github/"