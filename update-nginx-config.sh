#!/bin/bash
# Scout AI - Update Nginx Configuration for Clean Deployment
# Run this on the Azure VM after clean deployment

set -e

NEW_DEPLOYMENT_DIR="$HOME/scout-dev-github"
OLD_DEPLOYMENT_DIR="$HOME/scout-dev-deployment"

echo "🔧 Updating Nginx Configuration for Clean Deployment"
echo "=========================================="
echo ""

# Check if new deployment exists and is running
if [ ! -d "$NEW_DEPLOYMENT_DIR" ]; then
    echo "❌ New deployment directory not found: $NEW_DEPLOYMENT_DIR"
    echo "   Please run clean deployment first"
    exit 1
fi

cd "$NEW_DEPLOYMENT_DIR"

# Check if services are running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Services not running in new deployment"
    echo "   Please ensure deployment is healthy first"
    exit 1
fi

echo "✅ New deployment found and running"
echo ""

# Find nginx configuration files
echo "🔍 Locating nginx configuration..."

NGINX_CONFIG=""
POSSIBLE_CONFIGS=(
    "/etc/nginx/sites-available/default"
    "/etc/nginx/sites-available/scout-ai"
    "/etc/nginx/conf.d/default.conf"
    "/etc/nginx/nginx.conf"
)

for config in "${POSSIBLE_CONFIGS[@]}"; do
    if [ -f "$config" ] && grep -q "demo.scout-ai.com.au\|scout.*ai\|proxy_pass.*3000" "$config" 2>/dev/null; then
        NGINX_CONFIG="$config"
        break
    fi
done

if [ -z "$NGINX_CONFIG" ]; then
    echo "❌ Could not locate nginx configuration file"
    echo "   Please manually update nginx to proxy to localhost:3000"
    echo "   (The new deployment should be running on the same port)"
    exit 1
fi

echo "✅ Found nginx config: $NGINX_CONFIG"
echo ""

# Create backup of current nginx config
BACKUP_FILE="/tmp/nginx-config-backup-$(date +%Y%m%d-%H%M%S)"
echo "📁 Creating backup: $BACKUP_FILE"
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"

echo "✅ Nginx configuration backed up"
echo ""

echo "🔄 Since both deployments run on port 3000, nginx should automatically"
echo "   serve the new deployment without configuration changes."
echo ""

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"

    # Reload nginx
    echo "🔄 Reloading nginx..."
    if sudo systemctl reload nginx; then
        echo "✅ Nginx reloaded successfully"
    else
        echo "❌ Failed to reload nginx"
        exit 1
    fi
else
    echo "❌ Nginx configuration test failed"
    exit 1
fi

echo ""
echo "🎉 Configuration Update Complete!"
echo "================================="
echo ""
echo "📍 Test your domain: https://demo.scout-ai.com.au"
echo "📍 Direct access: http://$(curl -s ifconfig.me):3000"
echo ""
echo "🔧 Rollback if needed:"
echo "   sudo cp $BACKUP_FILE $NGINX_CONFIG"
echo "   sudo systemctl reload nginx"
echo ""
echo "🗑️ Clean up old deployment when satisfied:"
echo "   cd $OLD_DEPLOYMENT_DIR && docker-compose down"
echo "   rm -rf $OLD_DEPLOYMENT_DIR"