# Hello World Delivery

A minimal Node.js web application demonstrating release engineering, deployment automation, security controls, and practical delivery structure.

## Overview

This project showcases a complete delivery workflow from source to deployment, including:
- A minimal Express.js "Hello World" web application
- Multi-stage Azure DevOps CI/CD pipeline with automated security scanning

NOTE: AS AZURE STOPPED PUBLIC REPO ACCESS, CREATE ALL THE SETTING IN GITHUB/GITHUB ACTIONS
- Multi-stage GITHUB CI/CD pipeline with automated security scanning
- Containerized deployment using Docker with multi-stage builds
- Environment-separated deployment strategy (Development → Staging → Production)
- Automated security checks (Gitleaks secret detection, ESLint code quality)
- Reproducible local development setup

The application serves a simple HTTP endpoint that returns "Hello World" along with the container hostname, plus a health check endpoint for monitoring.

---

## Prerequisites

### Local Development
- **Node.js** 20.x or later
- **npm** (included with Node.js)
- **Docker** and **Docker Compose** (for containerized deployment)
- **Git** (for version control)

### Azure DevOps Requirements
- Azure DevOps organization and project
- Docker Hub account (for pushing `gcr.io/distroless/nodejs20-debian13` images)
- Pipeline variable group configured (optional: for secrets management)

### Supported Platforms
- Linux (Ubuntu 20.04+)
- macOS (Intel and Apple Silicon)
- Windows 10/11 with Docker Desktop or WSL2

---

## Setup & Installation

### 1. Clone the Repository
```bash
git clone https://github.com/your-org/hello-world-delivery.git
cd hello-world-delivery
```

### 2. Install Dependencies
```bash
cd app
npm install
```

### 3. Verify Setup
```bash
node app.js
```
Expected output: `App running on port 3001`

---

## Running the Application

### Local Execution
```bash
cd app
npm start
```
The app will start on `http://localhost:3001`

OUTPUT: Hello World from container 👋 Hostname: f80104148d2a

**Endpoints:**
- `GET /` - Returns greeting with hostname
- `GET /health` - Returns "OK" for health checks

### Docker Container

#### Build the Image
```bash
docker build -t hello-world:latest .
```

#### Run the Container
```bash
docker run -p 3001:3001 hello-world:latest
```

#### Test the Application
```bash
curl http://localhost:3001
curl http://localhost:3001/health -> It would return "OK"
```

---

## Pipeline Architecture

### Pipeline Stages

The Azure DevOps pipeline (`pipeline/azure-pipelines.yml`) implements a three-stage workflow:

#### **Stage 1: SecurityScan**
- **Purpose:** Detect secrets and sensitive data before build
- **Tool:** Gitleaks (Docker-based)
- **Action:** Fails pipeline if secrets are detected
- **Duration:** ~30 seconds
- **Configuration:** Uses `custom-rules.toml` for custom secret patterns

#### **Stage 2: Build**
- **Dependency:** Requires SecurityScan to pass
- **Steps:**
  1. Install Node.js 20.x
  2. Run `npm install` to fetch dependencies
  3. Run `npm run lint` (ESLint) to check code quality
  4. Publish build artifacts (app directory)
- **Duration:** ~2 minutes
- **Artifacts:** Packaged app directory with dependencies

#### **Stage 3: Deploy_Dev** (Available for implementation)
- **Dependency:** Requires Build to pass
- **Trigger:** Automatic on successful build
- **Environment:** Development
- **Action:** Deploy container to dev environment
- **Status:** Currently commented out; ready to implement

#### **Stage 4: Deploy_Staging** (Available for implementation)
- **Dependency:** Requires Deploy_Dev to pass
- **Trigger:** Automatic on dev deployment success
- **Environment:** Staging
- **Action:** Deploy container to staging environment
- **Status:** Currently commented out; ready to implement

### Trigger Configuration

The pipeline runs on:
- **Branches:** `main` and `develop`
- **On:** Push events and pull requests
- **Continuous Integration:** Enabled by default

```yaml
trigger:
  branches:
    include:
      - main
      - develop
```

---

## Deployment & Promotion

### Deployment Strategy

The project is structured for **progressive delivery** across environments:

```
Source Code (git) 
    ↓
Pull Request (develop branch)
    ↓
Security Scan (Gitleaks)
    ↓
Build (npm install, lint, package)
    ↓
Deploy to Dev (automatic)
    ↓
Deploy to Staging (automatic after dev passes)
    ↓
Manual approval for Production
```

### Deployment Triggers

**Automatic Promotion:**
- Dev: Deploys on every successful build on `develop` branch
- Staging: Deploys when dev deployment completes successfully

**Manual Approval:**
- Production: Requires explicit approval (typically via pipeline approval gates)

### Rollback Procedure

1. Navigate to pipeline execution history in Azure DevOps
2. Locate the previous successful deployment
3. Click "Redeploy" on the target environment
4. Confirm rollback approval
5. Monitor deployment status and health checks

---

## Security Controls

### Gitleaks Secret Detection

**What It Does:**
Gitleaks scans repository history and working directory for secrets, API keys, passwords, and private keys before code enters the build process.

**Why Selected:**
- Prevents accidental credential commits
- Runs early in pipeline (fail-fast approach)
- Configurable rules for custom patterns
- No false positives with proper allowlisting
- Industry-standard for DevOps security

**Where in Pipeline:**
Runs as the first stage (SecurityScan), before any build or deployment steps. Entire pipeline fails if secrets are detected.

**Configuration:**
Defined in `custom-rules.toml`:
```toml
[[rules]]
id = "generic-password"
description = "Detect any PASSWORD assignment"
regex = '''(?i)password\s*=\s*["'][^"']+["']'''
tags = ["password", "custom"]

[[rules]]
description = "Generic API Key"
regex = '''(?i)api[_-]?key.{0,20}['\"][0-9a-zA-Z]{16,45}['\"]'''
tags = ["key", "API"]
```

**If Pipeline Fails:**
1. Review the Gitleaks scan output for flagged content
2. Identify and remove the secret from code
3. If already committed, use `git filter-branch` or BFG Repo-Cleaner to purge from history
4. Rotate compromised credentials
5. Push cleaned code and retry pipeline

### ESLint Code Quality

**What It Does:**
ESLint enforces JavaScript code quality standards, catching syntax errors, unused variables, and style violations.

**Configuration:**
- Config file: `app/.eslintrc.js`
- Rules: ESLint recommended baseline
- Environment: Node.js 12+ target

**Pipeline Integration:**
Runs during Build stage after dependency installation:
```bash
npm run lint
```

**If Pipeline Fails:**
```bash
cd app
npm run lint
npm run lint -- --fix  # Auto-fix issues (if enabled)
```

---

## Branch Protection Rules

Branch protection rules should be configured in Azure DevOps to enforce code quality and prevent direct commits to critical branches.

### Recommended Branch Policies for `main`

**1. Require Pull Request Reviews**
- Minimum reviewers: 2
- Allow completion when not all reviewers approve: No (all must approve)
- Require reviewers to have recently pushed: Yes (within 30 days)
- Purpose: Ensures code review before merge
- Enforcement: Reviewers from different teams preferred

**2. Build Validation**
- Associated pipeline: `azure-pipelines.yml`
- Build expiration: 24 hours
- Scope: `/` (all paths)
- Purpose: Ensures all tests/security scans pass
- Failure action: Automatic rebuild on source changes

**3. Require Linked Work Items**
- Allow completion: No (require linked work item)
- Purpose: Ensures traceability to requirements/bugs
- Work item types: Feature, Bug, Task

**4. Comment Requirements**
- Require comment resolution: Yes
- Purpose: Ensures all feedback is addressed

**5. Prohibit Self-Approval**
- Allow self-approval: No
- Purpose: Prevents unilateral code merge
- Exception: Automation and bot accounts

### Recommended Branch Policies for `develop`

**1. Build Validation**
- Same pipeline: `azure-pipelines.yml`
- Required: Yes
- Purpose: Catch issues early before merge to main

**2. Minimum Reviewers**
- Minimum: 1 reviewer (less strict than main)
- Purpose: Maintains code quality without blocking velocity

**3. Comment Resolution**
- Required: Yes
- Purpose: Ensures feedback is addressed

### Enforcement Behavior

| Action | main | develop |
|--------|------|---------|
| Direct push | ❌ Blocked | ❌ Blocked |
| PR without review | ❌ Blocked | ❌ Blocked |
| PR without build passing | ❌ Blocked | ❌ Blocked |
| PR without linked work item | ❌ Blocked | ✅ Allowed |
| Self-approval | ❌ Blocked | ❌ Blocked |

---

## Development Workflow

### Feature Development

1. **Create feature branch from `develop`:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-feature
   ```

2. **Make changes and commit:**
   ```bash
   git add .
   git commit -m "feat: add my feature"
   ```

3. **Push to remote:**
   ```bash
   git push origin feature/my-feature
   ```

4. **Create Pull Request (GitHub/Azure DevOps):**
   - Target: `develop` branch
   - Title: Clear description of changes
   - Link work item (Azure DevOps)
   - Pipeline will automatically run

5. **Address feedback:**
   - Make requested changes
   - Push commits (pipeline re-runs automatically)

6. **Merge to develop:**
   - Once approved and pipeline passes, merge via PR
   - Delete feature branch

### Release Process

1. **Create release branch from `develop`:**
   ```bash
   git checkout -b release/v1.0.0
   ```

2. **Update version in `package.json`:**
   ```json
   "version": "1.0.0"
   ```

3. **Create PR to `main`:**
   - Full pipeline validation on main branch
   - Requires 2 approvals minimum
   - Deploy to Dev, then Staging (automatic)

4. **Manual approval for Production:**
   - Release manager approves production deployment
   - Container is deployed with semantic version tag

5. **Tag release in Git:**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
---

## Monitoring & Health Checks

### Health Endpoint

The application provides a health check endpoint for monitoring:
```bash
curl http://localhost:3001/health
# Response: 200 OK
```
### Pipeline Status Monitoring

- View pipeline status in Azure DevOps
- Set up email notifications for deployment failures
- Configure webhooks for Slack/Teams integration

---

### Assumptions
1. **Docker is available** - All deployments assume Docker/container runtime
2. **Azure DevOps platform** - Pipeline uses Azure-specific tasks and features
3. **Minimal app scope** - Application intentionally simple for focus on delivery workflow
4. **Single container host** - Deployment assumes single-host container runtime (not Kubernetes)
5. **Publicly accessible repositories** - Assumes public source and artifact repositories

### Trade-Offs
| Aspect | Choice | Reason |
|--------|--------|--------|
| Base image | Distroless | Minimal attack surface; not suitable for debugging |
| Node version | 20.x LTS | Stability over latest features |
| Secret management | Gitleaks only | Sufficient for preventing commits; not runtime secret injection |
| Deployment | Manual approval | Demonstrates governance; not fully automated for prod |
| Testing | Linting only | No unit/integration tests (scope limitation) |
| Documentation | Single README | Best practice for small projects; would split for larger projects |


## Troubleshooting Pipeline Failures
**Gitleaks fails:**
```bash
# Review what was flagged
docker run --rm -v $(pwd):/repo zricethezav/gitleaks detect --verbose
# Remove the secret and retry
```
**ESLint fails:**
```bash
cd app
npm run lint
npm run lint -- --fix
```
**Docker build fails:**
- Verify Node 20 is in use
- Check network connectivity for npm package downloads
- Ensure `app/package.json` exists
**Container won't start:**
```bash
docker run -it hello-world:latest /bin/bash  # (Not applicable with Distroless)
docker logs <container-id>
```

### Local Development Issues

**Port 3001 already in use:**
```bash
lsof -i :3001  # Find process using port
kill -9 <PID>  # Kill the process
```

**npm install fails:**
- Clear npm cache: `npm cache clean --force`
- Delete node_modules: `rm -rf node_modules`
- Reinstall: `npm install`

---

## Contributing
1. Create feature branch from `develop`
2. Make changes following project conventions
3. Commit with clear messages
4. Push and create pull request
5. Address review feedback
6. Merge to `develop` after approval
