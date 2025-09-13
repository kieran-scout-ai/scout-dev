#!/bin/bash
# Scout AI - Deploy from GitHub to Azure VM
# Run this on the Azure VM

set -e

GITHUB_REPO="https://github.com/kieran-scout-ai/scout-dev.git"
BRANCH="${1:-dev}"
DEPLOYMENT_DIR="$HOME/scout-dev-deployment"
BACKUP_PREFIX="backup-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Deploying from GitHub to Azure VM"
echo "Repository: $GITHUB_REPO"
echo "Branch: $BRANCH"
echo ""

# Create backup
if [ -d "$DEPLOYMENT_DIR" ]; then
    cd "$DEPLOYMENT_DIR"
    echo "📁 Creating backup: $BACKUP_PREFIX"
    mkdir -p backups/$BACKUP_PREFIX
    cp -r docker-compose.yml functions/ backups/$BACKUP_PREFIX/ 2>/dev/null || true
    docker-compose ps > backups/$BACKUP_PREFIX/containers.txt 2>/dev/null || true
fi

# Clone or pull from GitHub
if [ -d "$DEPLOYMENT_DIR/.git" ]; then
    # Directory is already a git repository
    cd "$DEPLOYMENT_DIR"
    git fetch origin && git checkout "$BRANCH" && git pull origin "$BRANCH"
elif [ -d "$DEPLOYMENT_DIR" ]; then
    # Directory exists but is not a git repository - initialize it
    cd "$DEPLOYMENT_DIR"
    echo "📦 Initializing git repository in existing directory..."
    git init
    git remote add origin "$GITHUB_REPO"
    git fetch origin
    git checkout -b "$BRANCH" origin/"$BRANCH"
else
    # Directory doesn't exist - clone it
    cd "$(dirname "$DEPLOYMENT_DIR")"
    git clone -b "$BRANCH" "$GITHUB_REPO" "$DEPLOYMENT_DIR"
    cd "$DEPLOYMENT_DIR"
fi

echo "📍 Deploying commit: $(git rev-parse --short HEAD)"

# Setup production config
if [ ! -f "docker-compose.yml" ]; then
    cp docker-compose.prod.yml docker-compose.yml
fi

# Setup environment file
if [ ! -f ".env.prod" ]; then
    echo "⚠️ Creating .env.prod - EDIT WITH YOUR VALUES!"
    cat > .env.prod << 'EOF'
WEBUI_SECRET_KEY=CHANGE-THIS-SECRET-KEY
AZURE_COMMUNICATION_CONNECTION_STRING=your-connection-string
SENDER_ADDRESS=donotreply@your-domain.com
SENDER_NAME=Scout AI
EOF
fi

# Deploy
echo "🚀 Deploying services..."
docker-compose pull
docker-compose down || true
docker-compose --env-file .env.prod up -d

# Health checks
echo "⏳ Checking deployment..."
sleep 15

if curl -s http://localhost:6333/health >/dev/null; then
    echo "✅ Qdrant: Healthy"
else
    echo "❌ Qdrant: Unhealthy"
fi

if curl -s http://localhost:3000/health >/dev/null 2>&1; then
    echo "✅ Open Web UI: Healthy"
else
    echo "⚠️ Open Web UI: Check logs"
fi

echo ""
echo "🎉 Deployment Complete!"
echo "📍 Access: http://$(curl -s ifconfig.me):3000"
echo "🔧 Rollback: cp backups/$BACKUP_PREFIX/docker-compose.yml . && docker-compose up -d"