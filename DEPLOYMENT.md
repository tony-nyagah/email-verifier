# 🚀 Deployment Guide - Email Verifier

This guide covers deploying the Email Verifier application using GitHub Actions and GitHub Container Registry (GHCR).

## 📋 Prerequisites

- Go 1.22+ installed locally
- Docker installed for local testing
- GitHub account with repository access
- Git configured with your GitHub credentials

## 🔧 Repository Setup

### 1. Create GitHub Repository

**Option A: Using GitHub CLI (Recommended)**
```bash
# Create repository
gh repo create yourusername/email-verifier --public --description "🔍 Beautiful Go web application for email verification"

# Clone and setup
git clone https://github.com/yourusername/email-verifier.git
cd email-verifier
```

**Option B: Manual Setup**
1. Go to [GitHub](https://github.com/new)
2. Create repository named `email-verifier`
3. Choose public/private visibility
4. Don't initialize with README
5. Clone the empty repository

### 2. Quick Setup Script

Use the provided setup script for automated configuration:

```bash
./setup-repo.sh
```

Or follow manual steps below.

### 3. Manual Repository Configuration

```bash
# Initialize git (if not already done)
git init
git branch -M main

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Email Verifier Go application

Features:
- Beautiful web interface with glassmorphism design
- Email syntax validation and SMTP verification  
- Domain MX record validation
- Disposable email detection
- Role account and free provider detection
- Domain typo suggestions
- REST API with JSON responses
- Docker support with multi-arch builds
- Comprehensive test suite
- GitHub Actions CI/CD pipeline"

# Add remote and push
git remote add origin https://github.com/yourusername/email-verifier.git
git push -u origin main
```

## ⚙️ GitHub Repository Settings

### Required Permissions

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Actions** → **General**
3. Under **Workflow permissions**, select:
   - ✅ **Read and write permissions**
   - ✅ **Allow GitHub Actions to create and approve pull requests**
4. Click **Save**

### Enable GitHub Packages

GitHub Container Registry is automatically enabled for public repositories. For private repositories:

1. Go to **Settings** → **Developer settings** → **Personal access tokens**
2. Create token with `write:packages` and `read:packages` scopes
3. Use for authentication when pulling private images

## 🐳 Docker Images and Tags

### Automatic Tagging Strategy

The GitHub Action creates the following tags:

| Trigger | Tags Created | Example |
|---------|-------------|---------|
| Push to `main` | `latest`, `main` | `ghcr.io/user/email-verifier:latest` |
| Push to other branch | `branch-name` | `ghcr.io/user/email-verifier:develop` |
| Create tag `v1.0.0` | `v1.0.0`, `v1.0`, `v1` | `ghcr.io/user/email-verifier:v1.0.0` |
| Pull request | `pr-123` | `ghcr.io/user/email-verifier:pr-123` |
| Commit SHA | `sha-abc1234` | `ghcr.io/user/email-verifier:sha-abc1234` |

### Multi-Architecture Support

Images are built for:
- ✅ `linux/amd64` (Intel/AMD x64)
- ✅ `linux/arm64` (Apple Silicon, ARM servers)

## 🚀 Deployment Options

### 1. Docker Run

```bash
# Pull latest image
docker pull ghcr.io/yourusername/email-verifier:latest

# Run container
docker run -d \
  --name email-verifier \
  -p 8080:8080 \
  --restart unless-stopped \
  ghcr.io/yourusername/email-verifier:latest
```

### 2. Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  email-verifier:
    image: ghcr.io/yourusername/email-verifier:latest
    container_name: email-verifier
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/main", "--health-check"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s
```

Deploy:
```bash
docker-compose up -d
```

### 3. Kubernetes Deployment

Create `k8s-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: email-verifier
  labels:
    app: email-verifier
spec:
  replicas: 3
  selector:
    matchLabels:
      app: email-verifier
  template:
    metadata:
      labels:
        app: email-verifier
    spec:
      containers:
      - name: email-verifier
        image: ghcr.io/yourusername/email-verifier:latest
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        livenessProbe:
          exec:
            command: ["/main", "--health-check"]
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command: ["/main", "--health-check"]
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: email-verifier-service
spec:
  selector:
    app: email-verifier
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

Deploy:
```bash
kubectl apply -f k8s-deployment.yaml
```

### 4. Cloud Platforms

#### Google Cloud Run

```bash
# Deploy to Cloud Run
gcloud run deploy email-verifier \
  --image ghcr.io/yourusername/email-verifier:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080
```

#### AWS ECS/Fargate

```bash
# Create task definition
aws ecs register-task-definition \
  --family email-verifier \
  --network-mode awsvpc \
  --requires-attributes FARGATE \
  --cpu 256 \
  --memory 512 \
  --container-definitions '[{
    "name": "email-verifier",
    "image": "ghcr.io/yourusername/email-verifier:latest",
    "portMappings": [{"containerPort": 8080}],
    "essential": true
  }]'
```

#### Azure Container Instances

```bash
# Deploy to ACI
az container create \
  --resource-group myResourceGroup \
  --name email-verifier \
  --image ghcr.io/yourusername/email-verifier:latest \
  --dns-name-label email-verifier-unique \
  --ports 8080
```

## 🔄 CI/CD Workflow

### Trigger Builds

#### For Development
```bash
# Push to main branch
git push origin main
# → Creates: latest, main tags
```

#### For Releases
```bash
# Create and push version tag
git tag v1.0.0
git push origin v1.0.0
# → Creates: v1.0.0, v1.0, v1 tags
```

#### For Feature Testing
```bash
# Push feature branch
git checkout -b feature/new-validation
git push origin feature/new-validation
# → Creates: feature-new-validation tag
```

### Workflow Status

Monitor builds at:
`https://github.com/yourusername/email-verifier/actions`

### Build Artifacts

Each successful build produces:
- ✅ Multi-arch Docker images
- ✅ Test results and coverage reports
- ✅ Security scan results
- ✅ Build cache for faster subsequent builds

## 🔐 Authentication

### For Private Repositories

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u yourusername --password-stdin

# Pull private image
docker pull ghcr.io/yourusername/email-verifier:latest
```

### Personal Access Token

If needed, create a PAT with these scopes:
- `read:packages` - Pull images
- `write:packages` - Push images (for manual pushes)

## 🔍 Monitoring and Health Checks

### Health Check Endpoint

The application provides a health check endpoint:

```bash
# Check application health
curl http://localhost:8080/health

# Response:
{
  "status": "healthy",
  "service": "email-verifier"
}
```

### Container Health Check

The Docker image includes a built-in health check:

```bash
# Check container health
docker ps
# Shows health status in STATUS column
```

### Monitoring Integration

For production monitoring, integrate with:
- **Prometheus**: Scrape `/health` endpoint
- **New Relic**: Add agent for APM
- **DataDog**: Use Docker integration
- **AWS CloudWatch**: For ECS deployments

## 🛠️ Troubleshooting

### Common Issues

#### Build Fails - Go Version
```
Error: go.mod requires go >= 1.22
```
**Solution**: Ensure Dockerfile uses `golang:1.22-alpine` or newer

#### Container Won't Start
```
Error: templates not found
```
**Solution**: Check Dockerfile copies templates directory correctly

#### GitHub Action Fails - Permissions
```
Error: denied: permission_denied
```
**Solution**: Enable "Read and write permissions" in repository settings

#### Image Pull Fails
```
Error: denied: permission_denied
```
**Solution**: Login to GHCR or make repository public

### Debug Commands

```bash
# Check running containers
docker ps -a

# View container logs
docker logs email-verifier

# Execute into container
docker exec -it email-verifier sh

# Test health check manually
docker exec email-verifier /main --health-check

# Check image details
docker inspect ghcr.io/yourusername/email-verifier:latest
```

## 📊 Performance Optimization

### Production Recommendations

1. **Resource Limits**
   ```yaml
   resources:
     requests:
       memory: "64Mi"
       cpu: "100m"
     limits:
       memory: "256Mi"
       cpu: "500m"
   ```

2. **Replica Count**: Start with 2-3 replicas for high availability

3. **Load Balancing**: Use nginx or cloud load balancer

4. **Caching**: Consider Redis for frequent email validations

5. **Rate Limiting**: Implement at load balancer level

## 🔒 Security Considerations

- ✅ Container runs as non-root user (scratch base image)
- ✅ Minimal attack surface (distroless final image)
- ✅ No secrets in container image
- ✅ HTTPS termination at load balancer
- ✅ Regular dependency updates via Dependabot

## 📝 Maintenance

### Regular Tasks

1. **Monitor Dependencies**: Dependabot creates PRs for updates
2. **Review Security Scans**: Check GitHub Security tab
3. **Update Base Images**: Rebuild monthly for security patches
4. **Monitor Performance**: Check response times and error rates
5. **Backup Configurations**: Keep deployment configs in version control

### Version Management

Use semantic versioning:
- `v1.0.0` - Major release
- `v1.1.0` - Minor release (new features)
- `v1.0.1` - Patch release (bug fixes)

---

## 📞 Support

For deployment issues:
1. Check [GitHub Issues](https://github.com/yourusername/email-verifier/issues)
2. Review [GitHub Actions logs](https://github.com/yourusername/email-verifier/actions)
3. Create new issue with deployment details

Happy deploying! 🚀