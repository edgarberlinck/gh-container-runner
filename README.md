# GitHub Actions Self-Hosted Runners

A containerized solution for managing GitHub Actions self-hosted runners with Docker support. This repository provides an easy way to deploy and manage multiple self-hosted runners for your GitHub repositories or organizations.

## Features

- 🐳 **Docker-in-Docker Support**: Runners can execute Docker commands within workflows
- 🔄 **Multiple Runners**: Easy configuration for running multiple runners simultaneously  
- 📦 **Containerized**: Isolated environment for each runner
- 🔒 **Secure**: Proper permission handling for Docker socket access
- ⚙️ **Configurable**: Custom runner names and environment variables
- 🔁 **Auto-restart**: Containers restart automatically on failure

## Prerequisites

- Docker and Docker Compose installed
- A GitHub repository or organization
- Admin access to generate runner tokens

## Quick Start

### 1. Clone the Repository

\`\`\`bash
git clone <your-repo-url>
cd gh-action-runners
\`\`\`

### 2. Create Environment File

Create a \`.env\` file:

\`\`\`bash
RUNNER_URL=https://github.com/your-username/your-repo
RUNNER_TOKEN=your-runner-token-here
\`\`\`

**Note**: Runner tokens expire in 1 hour. Generate at:
- Repositories: \`https://github.com/USERNAME/REPO/settings/actions/runners/new\`
- Organizations: \`https://github.com/organizations/ORG/settings/actions/runners/new\`

### 3. Start the Runners

\`\`\`bash
docker compose up -d
\`\`\`

### 4. Verify

\`\`\`bash
docker compose logs -f
\`\`\`

Runners should appear in GitHub under Settings → Actions → Runners.

## Configuration

### Custom Runner Names

Edit \`docker-compose.yml\`:

\`\`\`yaml
environment:
  - RUNNER_NAME=my-custom-runner
\`\`\`

### Scaling Runners

Add more services in \`docker-compose.yml\`:

\`\`\`yaml
services:
  runner-3:
    build: .
    environment:
      - RUNNER_NAME=runner-3
      # ...
\`\`\`

## CI/CD Gotchas & Best Practices

### 🔴 Critical Issues We Solved

#### 1. Database Connection in Self-Hosted Runners

**Problem**: \`localhost\` doesn't work because workflows run inside the runner container.

\`\`\`yaml
# ❌ WRONG
DATABASE_URL: "postgresql://postgres:postgres@localhost:5432/db"
\`\`\`

**Solution**: Use \`host.docker.internal\`:

\`\`\`yaml
# ✅ CORRECT
DATABASE_URL: "postgresql://postgres:postgres@host.docker.internal:5432/db"
\`\`\`

**Why**: Runner container needs to reach services on the host. \`host.docker.internal\` resolves to the host's IP.

#### 2. GitHub Actions Services Don't Work

**Problem**: The \`services:\` keyword doesn't configure networking properly on self-hosted runners.

**Solution**: Manually manage containers:

\`\`\`yaml
jobs:
  test:
    runs-on: self-hosted
    steps:
      - name: Start PostgreSQL
        run: |
          docker run -d \\
            --name postgres-\${{ github.run_id }} \\
            -e POSTGRES_PASSWORD=postgres \\
            -p 5432:5432 \\
            postgres:16-alpine
          
          timeout 60 bash -c 'until docker exec postgres-\${{ github.run_id }} pg_isready; do sleep 2; done'
      
      - name: Run tests
        run: npm test
      
      - name: Cleanup
        if: always()
        run: docker rm -f postgres-\${{ github.run_id }}
\`\`\`

#### 3. Port Conflicts with Parallel Jobs

**Problem**: Multiple jobs try to use the same port simultaneously.

**Solution**: Use random ports:

\`\`\`yaml
jobs:
  build:
    runs-on: self-hosted
    steps:
      - name: Start PostgreSQL
        run: |
          POSTGRES_PORT=\$((50000 + RANDOM % 10000))
          echo "POSTGRES_PORT=\$POSTGRES_PORT" >> \$GITHUB_ENV
          docker run -d -p \$POSTGRES_PORT:5432 postgres
      
      - name: Run migrations
        run: |
          export DATABASE_URL="postgresql://user:pass@host.docker.internal:\$POSTGRES_PORT/db"
          npm run migrate
\`\`\`

#### 4. Docker Permission Denied

**Problem**: Runner can't access Docker socket.

**Solution**: Our entrypoint automatically fixes permissions:

\`\`\`bash
if [ -S /var/run/docker.sock ]; then
    sudo chgrp daemon /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock
fi
\`\`\`

#### 5. Prisma 7 Configuration

**Problem**: Prisma 7 ignores \`url\` in datasource and reads from \`prisma.config.ts\`.

**Solution**:
- Don't add \`url\` to \`schema.prisma\`
- Export \`DATABASE_URL\` before commands:

\`\`\`yaml
- name: Run migrations
  run: |
    export DATABASE_URL="postgresql://user:pass@host.docker.internal:5432/db"
    npx prisma db push
\`\`\`

#### 6. Runner Token Expiration

**Problem**: Tokens expire after 1 hour.

**Solution**: Regenerate and restart:

\`\`\`bash
docker compose down
# Update .env with new token
docker compose up -d
\`\`\`

### 📋 Workflow Best Practices

#### Run Jobs in Parallel

\`\`\`yaml
jobs:
  build:
    runs-on: self-hosted
    # No 'needs' - runs immediately
  
  lint:
    runs-on: self-hosted
    # Runs in parallel with build
  
  test:
    runs-on: self-hosted
    needs: [build, lint]  # Waits for both
\`\`\`

#### Always Cleanup Resources

\`\`\`yaml
- name: Cleanup
  if: always()  # ✅ Runs even on failure
  run: |
    docker stop postgres-\${{ github.run_id }} || true
    docker rm postgres-\${{ github.run_id }} || true
\`\`\`

#### Use Unique Container Names

\`\`\`yaml
# ✅ Use github.run_id for uniqueness
--name postgres-\${{ github.run_id }}

# ❌ Don't use static names
--name postgres
\`\`\`

## Troubleshooting

### Runners Not Appearing

1. Check logs: \`docker compose logs runner-1\`
2. Verify token hasn't expired
3. Check \`RUNNER_URL\` and \`RUNNER_TOKEN\` in \`.env\`

### Docker Permission Errors

Restart containers: \`docker compose restart\`

### Database Connection Errors

Use \`host.docker.internal\` instead of \`localhost\`

## Maintenance

### Updating

\`\`\`bash
docker compose down
docker compose build --no-cache
docker compose up -d
\`\`\`

### Logs

\`\`\`bash
docker compose logs -f
\`\`\`

## Security

- 🔒 Never commit \`.env\` to version control
- 🔐 Docker socket access = full Docker control - use in trusted environments only
- 🔑 Consider GitHub Apps for long-lived auth

## License

MIT
