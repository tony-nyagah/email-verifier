#!/bin/bash

# Email Verifier - GitHub Repository Setup Script
# This script helps you set up your GitHub repository and push to GitHub Container Registry

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Email Verifier - GitHub Repository Setup${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install Git first.${NC}"
    exit 1
fi

# Check if gh CLI is installed (optional but recommended)
if command -v gh &> /dev/null; then
    HAS_GH_CLI=true
    echo -e "${GREEN}✅ GitHub CLI detected${NC}"
else
    HAS_GH_CLI=false
    echo -e "${YELLOW}⚠️  GitHub CLI not found. You'll need to create the repository manually.${NC}"
fi

echo ""

# Get repository information
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter repository name (default: email-verifier): " REPO_NAME
REPO_NAME=${REPO_NAME:-email-verifier}

REPO_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
GHCR_IMAGE="ghcr.io/${GITHUB_USERNAME}/${REPO_NAME}"

echo ""
echo -e "${BLUE}📋 Repository Details:${NC}"
echo -e "  Username: ${YELLOW}${GITHUB_USERNAME}${NC}"
echo -e "  Repository: ${YELLOW}${REPO_NAME}${NC}"
echo -e "  URL: ${YELLOW}${REPO_URL}${NC}"
echo -e "  Container Image: ${YELLOW}${GHCR_IMAGE}${NC}"
echo ""

read -p "Is this correct? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Setup cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🔧 Setting up local repository...${NC}"

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Initializing Git repository...${NC}"
    git init
    echo -e "${GREEN}✅ Git repository initialized${NC}"
else
    echo -e "${GREEN}✅ Git repository already exists${NC}"
fi

# Add all files
echo -e "${YELLOW}Adding files to Git...${NC}"
git add .

# Create initial commit if there are no commits
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating initial commit...${NC}"
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
    echo -e "${GREEN}✅ Initial commit created${NC}"
else
    echo -e "${GREEN}✅ Repository already has commits${NC}"
fi

# Set main branch
git branch -M main

# Create repository on GitHub if gh CLI is available
if [ "$HAS_GH_CLI" = true ]; then
    echo ""
    echo -e "${BLUE}🏗️  Creating GitHub repository...${NC}"

    read -p "Make repository public? (y/N): " PUBLIC
    if [[ $PUBLIC =~ ^[Yy]$ ]]; then
        VISIBILITY="--public"
    else
        VISIBILITY="--private"
    fi

    if gh repo create "$GITHUB_USERNAME/$REPO_NAME" $VISIBILITY --description "🔍 Beautiful Go web application for email verification without sending emails. Features SMTP verification, domain validation, disposable email detection, and more." --homepage "https://github.com/$GITHUB_USERNAME/$REPO_NAME" --confirm; then
        echo -e "${GREEN}✅ GitHub repository created${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository might already exist or there was an error${NC}"
    fi
else
    echo ""
    echo -e "${YELLOW}📝 Manual Steps Required:${NC}"
    echo -e "1. Go to https://github.com/new"
    echo -e "2. Create a new repository named: ${YELLOW}${REPO_NAME}${NC}"
    echo -e "3. Choose public or private visibility"
    echo -e "4. Don't initialize with README (we already have files)"
    echo -e "5. Press Enter when done..."
    read -p ""
fi

# Add remote origin
echo ""
echo -e "${BLUE}🔗 Adding remote origin...${NC}"
if git remote get-url origin >/dev/null 2>&1; then
    echo -e "${YELLOW}Updating existing remote origin...${NC}"
    git remote set-url origin "$REPO_URL"
else
    echo -e "${YELLOW}Adding remote origin...${NC}"
    git remote add origin "$REPO_URL"
fi
echo -e "${GREEN}✅ Remote origin configured${NC}"

# Push to GitHub
echo ""
echo -e "${BLUE}📤 Pushing to GitHub...${NC}"
if git push -u origin main; then
    echo -e "${GREEN}✅ Successfully pushed to GitHub${NC}"
else
    echo -e "${RED}❌ Failed to push to GitHub${NC}"
    echo -e "${YELLOW}Please check your GitHub credentials and repository access.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Repository setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo -e "1. Your code is now on GitHub: ${YELLOW}https://github.com/${GITHUB_USERNAME}/${REPO_NAME}${NC}"
echo -e "2. GitHub Actions will automatically build and push Docker images to GHCR"
echo -e "3. Create a tag to trigger a release build:"
echo -e "   ${YELLOW}git tag v1.0.0${NC}"
echo -e "   ${YELLOW}git push origin v1.0.0${NC}"
echo ""
echo -e "${BLUE}🐳 Docker Image Usage:${NC}"
echo -e "After the GitHub Action completes, you can use your image:"
echo -e "   ${YELLOW}docker pull ${GHCR_IMAGE}:latest${NC}"
echo -e "   ${YELLOW}docker run -p 8080:8080 ${GHCR_IMAGE}:latest${NC}"
echo ""
echo -e "${BLUE}🔧 Local Development:${NC}"
echo -e "   ${YELLOW}make run${NC}          # Run locally"
echo -e "   ${YELLOW}make test${NC}         # Run tests"
echo -e "   ${YELLOW}make docker-run${NC}   # Run with Docker"
echo ""
echo -e "${GREEN}✨ Happy coding!${NC}"

# Check if GitHub Packages permissions are set up
echo ""
echo -e "${BLUE}📦 Important: GitHub Packages Setup${NC}"
echo -e "${YELLOW}Make sure to configure GitHub Packages permissions:${NC}"
echo -e "1. Go to your repository settings"
echo -e "2. Navigate to 'Actions' > 'General'"
echo -e "3. Under 'Workflow permissions', select 'Read and write permissions'"
echo -e "4. Check 'Allow GitHub Actions to create and approve pull requests'"
echo -e "5. Save the settings"
echo ""
echo -e "${BLUE}🔐 For private repositories:${NC}"
echo -e "You may need to authenticate to pull images:"
echo -e "   ${YELLOW}echo \$GITHUB_TOKEN | docker login ghcr.io -u ${GITHUB_USERNAME} --password-stdin${NC}"
