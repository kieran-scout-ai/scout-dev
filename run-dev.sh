#!/bin/bash

# Scout AI Development Environment Startup Script

echo "🚀 Starting Scout AI Development Environment..."
echo ""

# Create dev-data directory if it doesn't exist
echo "📁 Creating development data directories..."
mkdir -p dev-data/qdrant_storage
mkdir -p dev-data/open-webui
mkdir -p functions

echo "🐳 Starting Docker services..."
echo "   - Qdrant will be available at: http://localhost:6335"
echo "   - Qdrant Web UI at: http://localhost:6335/dashboard"  
echo "   - Open Web UI will be available at: http://localhost:3001"
echo ""

# Start the development environment
docker-compose -f docker-compose.dev.yml --env-file .env.dev up -d

echo ""
echo "⏳ Waiting for services to be healthy..."

# Wait for Qdrant to be ready
echo "Waiting for Qdrant..."
while ! curl -s http://localhost:6335 > /dev/null 2>&1; do
    sleep 2
    echo -n "."
done
echo " ✅ Qdrant is ready!"

# Wait for Open Web UI to be ready
echo "Waiting for Open Web UI..."
while ! curl -s http://localhost:3001/health > /dev/null 2>&1; do
    sleep 2
    echo -n "."
done
echo " ✅ Open Web UI is ready!"

echo ""
echo "🎉 Development environment is ready!"
echo ""
echo "📍 Access points:"
echo "   • Open Web UI: http://localhost:3001"
echo "   • Qdrant API: http://localhost:6335"
echo "   • Qdrant Web UI: http://localhost:6335/dashboard"
echo ""
echo "🔧 Useful commands:"
echo "   • View logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "   • Stop services: docker-compose -f docker-compose.dev.yml down"
echo "   • Restart: docker-compose -f docker-compose.dev.yml restart"
echo ""