#!/bin/bash
# Scout AI - Clean GitHub Deployment to New Directory
# This deploys to a separate directory to avoid conflicts with existing deployments

set -e

GITHUB_REPO="https://github.com/kieran-scout-ai/scout-dev.git"
BRANCH="${1:-main}"
DEPLOYMENT_DIR="$HOME/scout-dev-github"
BACKUP_PREFIX="backup-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Clean Deployment from GitHub to Azure VM"
echo "Repository: $GITHUB_REPO"
echo "Branch: $BRANCH"
echo "Target Directory: $DEPLOYMENT_DIR"
echo ""

# Remove existing directory if it exists (clean slate)
if [ -d "$DEPLOYMENT_DIR" ]; then
    echo "📁 Removing existing directory for clean deployment..."
    rm -rf "$DEPLOYMENT_DIR"
fi

# Clone fresh from GitHub
echo "📦 Cloning fresh from GitHub..."
git clone -b "$BRANCH" "$GITHUB_REPO" "$DEPLOYMENT_DIR"
cd "$DEPLOYMENT_DIR"

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
    echo "⚠️ Open Web UI: Check logs - docker-compose logs -f"
fi

echo ""
echo "🎉 Clean Deployment Complete!"
echo "📍 Services running from: $DEPLOYMENT_DIR"
echo "📍 Access: http://$(curl -s ifconfig.me):3000"
echo ""
echo "🔧 Next Steps:"
echo "   1. Update nginx to point to this deployment"
echo "   2. Test the new deployment thoroughly"
echo "   3. Stop old deployment when satisfied"
echo ""
echo "🔄 Service Management:"
echo "   • View logs: docker-compose logs -f"
echo "   • Stop services: docker-compose down"
echo "   • Restart: docker-compose restart"