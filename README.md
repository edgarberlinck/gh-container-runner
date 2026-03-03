# GitHub Actions Self-Hosted Runners

A containerized solution for managing GitHub Actions self-hosted runners with Docker support. This repository provides an easy way to deploy and manage multiple self-hosted runners for your GitHub repositories or organizations.

## Features

- 🐳 **Docker-in-Docker Support**: Runners can execute Docker commands within workflows
- 🔄 **Multiple Runners**: Easy configuration for running multiple runners simultaneously
- 📦 **Containerized**: Isolated environment for each runner
- 🔒 **Secure**: Proper permission handling for Docker socket access
- ⚙️ **Configurable**: Custom runner names and environment variables
- 🔁 **Auto-restart**: Containers restart automatically on failure
- 💾 **Persistent Storage**: Work directories and caches preserved across restarts

## Prerequisites

- Docker and Docker Compose installed
- A GitHub repository or organization
- Admin access to generate runner tokens

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/edgarberlinck/gh-container-runner.git
cd gh-container-runner
```

### 2. Create Environment File

Create a `.env` file:

```bash
RUNNER_URL=https://github.com/your-username/your-repo
RUNNER_TOKEN=your-runner-token-here
```

**Note**: Runner tokens expire in 1 hour. Generate at:
- Repositories: `https://github.com/USERNAME/REPO/settings/actions/runners/new`
- Organizations: `https://github.com/organizations/ORG/settings/actions/runners/new`

### 3. Start the Runners

```bash
docker compose up -d
```

### 4. Verify

```bash
docker compose logs -f
```

Runners should appear in GitHub under **Settings → Actions → Runners**.

## Configuration

### Custom Runner Names

Edit `docker-compose.yml`:

```yaml
environment:
  - RUNNER_NAME=my-custom-runner
```

### Scaling Runners

Add more services in `docker-compose.yml`:

```yaml
services:
  runner-3:
    build: .
    environment:
      - RUNNER_NAME=runner-3
      - RUNNER_URL=${RUNNER_URL}
      - RUNNER_TOKEN=${RUNNER_TOKEN}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner-3-data:/actions-runner/_work

volumes:
  runner-3-data:
```

## Architecture

### Components

- **Dockerfile**: Builds the runner image with:
  - Ubuntu base
  - GitHub Actions runner binaries
  - Docker CLI and tools
  - Required dependencies

- **entrypoint.sh**: Handles:
  - Runner registration
  - Docker socket permissions
  - Graceful cleanup on shutdown

- **docker-compose.yml**: Orchestrates multiple runners

- **Persistent Volumes**: Each runner has dedicated storage for:
  - Workflow working directories (`_work`)
  - Build caches
  - Downloaded actions

### Docker Socket Sharing

Runners share the host's Docker daemon via socket mounting (`/var/run/docker.sock`). This allows workflows to:
- Build Docker images
- Run containers
- Execute docker-compose commands

## CI/CD Gotchas & Best Practices

### 🔴 Critical Issues We Solved

#### 1. Database Connection in Self-Hosted Runners

**Problem**: `localhost` doesn't work because workflows run inside the runner container.

```yaml
# ❌ WRONG
DATABASE_URL: "postgresql://postgres:postgres@localhost:5432/db"
```

**Solution**: Use `host.docker.internal`:

```yaml
# ✅ CORRECT
DATABASE_URL: "postgresql://postgres:postgres@host.docker.internal:5432/db"
```

**Why**: Runner container needs to reach services on the host. `host.docker.internal` resolves to the host's IP address.

---

#### 2. GitHub Actions Services Don't Work

**Problem**: The `services:` keyword doesn't configure networking properly on self-hosted runners.

```yaml
# ❌ This doesn't work properly
jobs:
  test:
    runs-on: self-hosted
    services:
      postgres:
        image: postgres:16
```

**Solution**: Manually manage containers:

```yaml
# ✅ CORRECT
jobs:
  test:
    runs-on: self-hosted
    steps:
      - name: Start PostgreSQL
        run: |
          docker run -d \
            --name postgres-${{ github.run_id }} \
            -e POSTGRES_PASSWORD=postgres \
            -p 5432:5432 \
            postgres:16-alpine
          
          timeout 60 bash -c 'until docker exec postgres-${{ github.run_id }} pg_isready; do sleep 2; done'
      
      - name: Run tests
        run: npm test
      
      - name: Cleanup
        if: always()
        run: docker rm -f postgres-${{ github.run_id }}
```

---

#### 3. Port Conflicts with Parallel Jobs

**Problem**: Multiple jobs try to use the same port simultaneously.

```yaml
# ❌ WRONG - Both jobs conflict
jobs:
  build:
    steps:
      - run: docker run -p 5432:5432 postgres
  
  test:
    steps:
      - run: docker run -p 5432:5432 postgres  # ❌ Port conflict!
```

**Solution**: Use random ports:

```yaml
# ✅ CORRECT
jobs:
  build:
    runs-on: self-hosted
    steps:
      - name: Start PostgreSQL
        run: |
          POSTGRES_PORT=$((50000 + RANDOM % 10000))
          echo "POSTGRES_PORT=$POSTGRES_PORT" >> $GITHUB_ENV
          docker run -d -p $POSTGRES_PORT:5432 postgres
      
      - name: Run migrations
        run: |
          export DATABASE_URL="postgresql://user:pass@host.docker.internal:$POSTGRES_PORT/db"
          npm run migrate
```

---

#### 4. Docker Permission Denied

**Problem**: Runner can't access Docker socket.

```
permission denied while trying to connect to the Docker daemon socket
```

**Solution**: Our entrypoint automatically fixes permissions:

```bash
if [ -S /var/run/docker.sock ]; then
    sudo chgrp daemon /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock
fi
```

**Why**: The Docker socket on macOS has GID 1 (daemon), so we add the runner user to that group.

---

#### 5. Prisma 7 Configuration

**Problem**: Prisma 7 ignores `url` in datasource and reads from `prisma.config.ts`.

**Solution**:
- Don't add `url` to `schema.prisma`
- Export `DATABASE_URL` before commands:

```yaml
- name: Run migrations
  run: |
    export DATABASE_URL="postgresql://user:pass@host.docker.internal:5432/db"
    npx prisma db push
```

---

#### 6. Runner Token Expiration

**Problem**: Tokens expire after 1 hour.

**Solution**: Regenerate and restart:

```bash
docker compose down
# Update .env with new token
docker compose up -d
```

---

### 📋 Workflow Best Practices

#### Run Jobs in Parallel

```yaml
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
```

#### Always Cleanup Resources

```yaml
- name: Cleanup
  if: always()  # ✅ Runs even on failure
  run: |
    docker stop postgres-${{ github.run_id }} || true
    docker rm postgres-${{ github.run_id }} || true
```

#### Use Unique Container Names

```yaml
# ✅ Use github.run_id for uniqueness
--name postgres-${{ github.run_id }}

# ❌ Don't use static names
--name postgres
```

## Troubleshooting

### Runners Not Appearing

1. Check logs: `docker compose logs runner-1`
2. Verify token hasn't expired (1 hour lifetime)
3. Check `RUNNER_URL` and `RUNNER_TOKEN` in `.env`

### Docker Permission Errors

Restart containers: `docker compose restart`

### Database Connection Errors

Ensure you're using `host.docker.internal` instead of `localhost`

### Port Already in Use

Check what's using the port:
```bash
lsof -i :5432
```

## Maintenance

### Updating Runners

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Viewing Logs

```bash
# All runners
docker compose logs -f

# Specific runner
docker compose logs -f runner-1
```

### Managing Volumes

```bash
# List volumes
docker volume ls | grep runner

# Inspect volume
docker volume inspect gh-container-runner_runner-1-data

# Clean old data (caution: removes all work directories)
docker compose down -v
```

### Backup Runner Data

```bash
# Backup runner 1 data
docker run --rm \
  -v gh-container-runner_runner-1-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/runner-1-backup.tar.gz /data

# Restore
docker run --rm \
  -v gh-container-runner_runner-1-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/runner-1-backup.tar.gz -C /
```

## Security Considerations

- 🔒 **Token Security**: Never commit `.env` to version control
- 🔐 **Docker Socket**: Mounting Docker socket gives full Docker access - use in trusted environments only
- 🔑 **PAT Alternative**: Consider using GitHub Apps for long-lived authentication
- 🛡️ **Network Isolation**: Runners have access to host network - ensure proper firewall rules

## FAQ

**Q: Why not use GitHub-hosted runners?**
A: Self-hosted runners offer:
- More control over environment
- Better performance for large builds
- Cost savings for high-volume CI/CD
- Access to internal resources

**Q: Can I run this in production?**
A: Yes, but ensure:
- Secure token management
- Regular updates
- Monitoring and alerting
- Backup strategy for volumes

**Q: How many runners can I run?**
A: Limited by your host resources. Each runner needs ~1GB RAM minimum.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT

## Acknowledgments

Built with lessons learned from real-world CI/CD challenges with GitHub Actions self-hosted runners.
