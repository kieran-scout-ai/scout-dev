#!/bin/bash
# Scout AI - Trigger GitHub Deployment
# Usage: ./trigger-deployment.sh [branch] [vm-user] [vm-ip]

set -e

BRANCH="${1:-dev}"
AZURE_VM_USER="${2:-azureuser}"
AZURE_VM_IP="${3:-4.196.108.56}"

echo "🚀 Triggering deployment from GitHub to Azure VM"
echo "Branch: $BRANCH | Target: $AZURE_VM_USER@$AZURE_VM_IP"
echo ""

# Check local changes
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Uncommitted changes detected. Please commit and push first."
    exit 1
fi

read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Trigger deployment on VM
ssh -t "$AZURE_VM_USER@$AZURE_VM_IP" "
    curl -s https://raw.githubusercontent.com/kieran-scout-ai/scout-dev/$BRANCH/deploy-from-github.sh -o deploy.sh
    chmod +x deploy.sh
    ./deploy.sh $BRANCH
"

echo "✅ Deployment complete!"