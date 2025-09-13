# Scout AI Development Environment

This repository contains the development environment for Scout AI's Open Web UI deployment.

## Quick Start

### Development Environment Setup

1. **Start the lightweight development environment** (recommended):
   ```bash
   ./run-dev.sh
   # OR manually:
   docker-compose -f docker-compose.dev-light.yml --env-file .env.dev up -d
   ```

2. **Access the services**:
   - **Open Web UI**: http://localhost:3001
   - **Qdrant Web UI**: http://localhost:6335/dashboard
   - **Qdrant API**: http://localhost:6335

### Development vs Production

| Environment | Open Web UI | Qdrant | Ollama | Purpose |
|-------------|-------------|--------|---------|---------|
| **Local Dev** | localhost:3001 | localhost:6335 | Azure VM (external) | Development & testing |
| **Azure VM** | vm-ip:3000 | vm-internal:6333 | vm-internal:11434 | Production |

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Test locally at localhost:3001

# Commit changes
git add .
git commit -m "Description of changes"

# Push to GitHub
git push origin feature/your-feature-name
```

### 2. Deployment to Azure VM
```bash
# After testing locally, deploy to Azure VM
# (Deployment scripts coming soon)
```

## Environment Configuration

### Local Development
- **Vector Database**: Fresh Qdrant instance (separate from production)
- **Models**: Uses Azure VM Ollama instance (4.196.108.56:11434)
- **Data**: Stored in `./dev-data/` (gitignored)
- **Functions**: Mounted from `./functions/` directory

### Environment Variables
Copy `.env.dev` and modify as needed:
- `QDRANT_URI`: Points to local Qdrant
- `OLLAMA_BASE_URL`: Points to Azure VM Ollama
- `VECTOR_DB`: Set to "qdrant"

## Useful Commands

### Container Management
```bash
# Start development environment
docker-compose -f docker-compose.dev-light.yml up -d

# View logs
docker-compose -f docker-compose.dev-light.yml logs -f

# Stop environment
docker-compose -f docker-compose.dev-light.yml down

# Restart services
docker-compose -f docker-compose.dev-light.yml restart
```

### Development Data
```bash
# Reset development data
rm -rf dev-data/
mkdir -p dev-data/qdrant_storage dev-data/open-webui

# Backup development data
cp -r dev-data/ dev-data-backup-$(date +%Y%m%d)/
```

## Troubleshooting

### High CPU Usage
- Use `docker-compose.dev-light.yml` instead of `docker-compose.dev.yml`
- The light version excludes local Ollama to reduce resource usage

### Port Conflicts
- Local development uses ports 3001, 6335, 6336
- Production uses ports 3000, 6333, 6334
- Ensure no conflicts with other local services

### Qdrant Connection Issues
- Verify Qdrant is healthy: `curl http://localhost:6335`
- Check container logs: `docker-compose -f docker-compose.dev-light.yml logs qdrant-dev`

## Architecture

```
Local Development Environment
├── Open Web UI (localhost:3001)
│   ├── Vector DB: Local Qdrant
│   ├── Models: Azure VM Ollama
│   └── Functions: ./functions/
├── Qdrant (localhost:6335)
│   ├── Fresh database
│   ├── Web UI: /dashboard
│   └── Storage: ./dev-data/qdrant_storage
└── Data: ./dev-data/ (gitignored)
```