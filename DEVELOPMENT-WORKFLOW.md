# Scout AI Development Workflow

## Branch Strategy

- **`dev` branch**: Development and testing
- **`main` branch**: Production-ready releases

## Development Process

### 1. Local Development
```bash
# Work on dev branch locally
git checkout dev

# Start local development environment
./run-dev.sh

# Develop at: http://localhost:3001
# Test with local Qdrant: http://localhost:6335/dashboard
```

### 2. Feature Development
```bash
# Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/feature-name

# Make changes, test locally
# Commit changes
git add .
git commit -m "Add feature description"

# Push feature branch
git push origin feature/feature-name
```

### 3. Integration to Dev Branch
```bash
# Switch to dev branch
git checkout dev

# Merge feature (or create PR for review)
git merge feature/feature-name
git push origin dev

# Delete feature branch
git branch -d feature/feature-name
git push origin --delete feature/feature-name
```

### 4. Release to Production
```bash
# When dev is stable and ready for production
# MANUAL REVIEW: Carefully review all changes before merging to main

git checkout main
git pull origin main

# Review changes that will be merged
git log main..dev --oneline
git diff main..dev

# Manually merge dev into main (only when ready)
git merge dev
git push origin main

# Deploy to production (pulls from main)
./trigger-clean-deployment.sh
```

## Environment Summary

| Environment | Branch | URL | Qdrant | Purpose |
|-------------|--------|-----|---------|---------|
| **Local Dev** | `dev` | localhost:3001 | localhost:6335 | Feature development |
| **Production** | `main` | demo.scout-ai.com.au | VM internal | Live application |

## Deployment Commands

### Local Development
```bash
./run-dev.sh                    # Start local development
```

### Production Deployment
```bash
./trigger-clean-deployment.sh   # Deploy main branch to production
```

### Development Testing Deployment
```bash
./trigger-clean-deployment.sh dev  # Deploy dev branch (testing only)
```

## Best Practices

1. **Always develop on `dev` branch**
2. **Test thoroughly in local environment**
3. **NEVER automatically merge `dev` to `main`**
4. **Manually review all changes before merging to `main`**
5. **Only merge stable, tested code to `main`**
6. **Production deploys only from `main`**
7. **Use feature branches for complex changes**
8. **Keep commits atomic and descriptive**

## Review Process

Before merging `dev` to `main`:
1. **Code Review**: Review all commits since last main merge
2. **Testing**: Ensure all features work in development environment
3. **Documentation**: Update relevant documentation
4. **Stability Check**: Confirm no breaking changes
5. **Manual Merge**: Consciously merge dev to main