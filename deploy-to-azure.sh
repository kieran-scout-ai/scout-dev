#!/bin/bash

# Scout AI - Deploy to Azure VM Script
# Run this from your local development machine to deploy to Azure VM

set -e

# Configuration
AZURE_VM_USER="your-username"
AZURE_VM_IP="your-vm-ip"
AZURE_VM_PATH="~/scout-dev-deployment"
BACKUP_PREFIX="backup-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Scout AI - Azure VM Deployment"
echo "=================================="
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if [ ! -f "docker-compose.dev-light.yml" ]; then
    echo "❌ Error: Must be run from the scout-dev directory"
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Error: You have uncommitted changes"
    echo "   Please commit and push your changes first"
    exit 1
fi

echo "✅ Prerequisites checked"
echo ""

# Get deployment details
echo "📋 Deployment Details:"
echo "   Source: Local development environment"
echo "   Target: $AZURE_VM_USER@$AZURE_VM_IP:$AZURE_VM_PATH"
echo "   Branch: $(git branch --show-current)"
echo "   Commit: $(git rev-parse --short HEAD)"
echo ""

read -p "🤔 Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 0
fi

echo ""
echo "🔄 Starting deployment process..."

# Step 1: Test SSH connection
echo "1️⃣ Testing SSH connection..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$AZURE_VM_USER@$AZURE_VM_IP" exit 2>/dev/null; then
    echo "❌ Cannot connect to Azure VM"
    echo "   Please check:"
    echo "   - VM IP address: $AZURE_VM_IP"
    echo "   - SSH key authentication"
    echo "   - VM is running"
    exit 1
fi
echo "✅ SSH connection successful"

# Step 2: Run pre-deployment backup on Azure VM
echo ""
echo "2️⃣ Creating backup on Azure VM..."
ssh "$AZURE_VM_USER@$AZURE_VM_IP" "
    set -e
    cd $AZURE_VM_PATH

    echo '📁 Creating backup: $BACKUP_PREFIX'

    # Create backup directory
    mkdir -p backups/$BACKUP_PREFIX

    # Backup current configuration
    cp -r docker-compose.yml functions/ Dockerfile.azure backups/$BACKUP_PREFIX/ 2>/dev/null || true

    # Backup Qdrant data (if not too large)
    if [ -d qdrant_storage ] && [ \$(du -s qdrant_storage | cut -f1) -lt 1000000 ]; then
        echo '💾 Backing up Qdrant data (small dataset)'
        cp -r qdrant_storage/ backups/$BACKUP_PREFIX/
    else
        echo '⚠️  Skipping Qdrant backup (large dataset - will use container backup instead)'
        docker-compose exec qdrant tar -czf /qdrant/storage/backup-pre-deploy.tar.gz -C /qdrant/storage . || true
    fi

    # Save current container state
    docker-compose ps > backups/$BACKUP_PREFIX/container_status.txt

    echo '✅ Backup complete: backups/$BACKUP_PREFIX'
"

# Step 3: Copy files from local to Azure VM
echo ""
echo "3️⃣ Copying files to Azure VM..."

# Copy main configuration files
echo "📄 Copying configuration files..."
scp docker-compose.yml "$AZURE_VM_USER@$AZURE_VM_IP:$AZURE_VM_PATH/"

# Copy functions directory if it exists and has content
if [ -d "functions" ] && [ "$(ls -A functions/)" ]; then
    echo "⚙️ Copying functions..."
    rsync -avz --delete functions/ "$AZURE_VM_USER@$AZURE_VM_IP:$AZURE_VM_PATH/functions/"
else
    echo "📝 No functions to copy"
fi

# Copy other important files
for file in Dockerfile.azure .env.example; do
    if [ -f "$file" ]; then
        echo "📄 Copying $file..."
        scp "$file" "$AZURE_VM_USER@$AZURE_VM_IP:$AZURE_VM_PATH/"
    fi
done

echo "✅ Files copied successfully"

# Step 4: Deploy on Azure VM
echo ""
echo "4️⃣ Deploying on Azure VM..."
ssh "$AZURE_VM_USER@$AZURE_VM_IP" "
    set -e
    cd $AZURE_VM_PATH

    echo '🔄 Deploying new version...'

    # Pull latest images
    echo '📥 Pulling Docker images...'
    docker-compose pull

    # Stop services gracefully
    echo '⏹️ Stopping services...'
    docker-compose down

    # Start services with new configuration
    echo '▶️ Starting services with new configuration...'
    docker-compose up -d

    echo '✅ Services started'
"

# Step 5: Health checks
echo ""
echo "5️⃣ Running health checks..."
echo "⏳ Waiting for services to start..."
sleep 30

ssh "$AZURE_VM_USER@$AZURE_VM_IP" "
    set -e
    cd $AZURE_VM_PATH

    echo '🔍 Checking service health...'

    # Check container status
    if ! docker-compose ps | grep -q 'Up'; then
        echo '❌ Some containers are not running'
        docker-compose ps
        exit 1
    fi

    # Check Qdrant health
    if ! curl -s http://localhost:6333/health >/dev/null; then
        echo '❌ Qdrant health check failed'
        exit 1
    fi

    # Check Open Web UI health (with retries)
    for i in {1..5}; do
        if curl -s http://localhost:3000/health >/dev/null; then
            echo '✅ Open Web UI health check passed'
            break
        elif [ \$i -eq 5 ]; then
            echo '❌ Open Web UI health check failed after 5 attempts'
            exit 1
        else
            echo '⏳ Waiting for Open Web UI... attempt \$i/5'
            sleep 10
        fi
    done

    echo '✅ All health checks passed'
"

# Step 6: Deployment success
echo ""
echo "🎉 Deployment Successful!"
echo "========================="
echo ""
echo "📍 Service URLs:"
echo "   • Open Web UI: http://$AZURE_VM_IP:3000"
echo "   • Qdrant Web UI: http://$AZURE_VM_IP:6333/dashboard"
echo ""
echo "📊 Deployment Summary:"
echo "   • Backup created: $BACKUP_PREFIX"
echo "   • Branch deployed: $(git branch --show-current)"
echo "   • Commit: $(git rev-parse --short HEAD) - $(git log -1 --pretty=format:'%s')"
echo "   • Timestamp: $(date)"
echo ""
echo "🔧 Useful commands:"
echo "   • View logs: ssh $AZURE_VM_USER@$AZURE_VM_IP 'cd $AZURE_VM_PATH && docker-compose logs -f'"
echo "   • Rollback: ./rollback-azure.sh $BACKUP_PREFIX"
echo "   • Monitor: ssh $AZURE_VM_USER@$AZURE_VM_IP 'cd $AZURE_VM_PATH && docker-compose ps'"
echo ""
echo "✅ Deployment complete!"