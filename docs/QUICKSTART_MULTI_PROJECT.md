# Quick Start: Multi-Project Setup

## 🚀 5 Minutes to Multiple Projects

### Step 1: Copy the example file

```bash
cp .env.multi-project.example .env
```

### Step 2: Get your tokens

Generate tokens for each project:
- **Project A**: https://github.com/YOUR_ORG/PROJECT_A/settings/actions/runners/new
- **Project B**: https://github.com/YOUR_ORG/PROJECT_B/settings/actions/runners/new

⚠️ **Important**: Tokens expire in 1 hour!

### Step 3: Edit `.env`

```bash
# Event.me Project
EVENT_ME_RUNNER_URL=https://github.com/edgarberlinck/event.me
EVENT_ME_RUNNER_TOKEN=YOUR_EVENT_ME_TOKEN_HERE

# Office365 Admin Project  
OFFICE365_RUNNER_URL=https://github.com/edgarberlinck/office365-admin
OFFICE365_RUNNER_TOKEN=YOUR_OFFICE365_TOKEN_HERE
```

### Step 4: Start runners

```bash
# Option A: Start ALL projects
docker compose -f docker-compose.multi-project.yml --profile event-me --profile office365 up -d

# Option B: Start only one project
docker compose -f docker-compose.multi-project.yml --profile event-me up -d

# Option C: Start projects separately
docker compose -f docker-compose.multi-project.yml --profile office365 up -d
```

### Step 5: Verify

```bash
# Check running containers
docker ps --filter "name=gh-runner"

# Check logs
docker compose -f docker-compose.multi-project.yml logs -f

# Check specific project
docker compose -f docker-compose.multi-project.yml logs -f event-me-runner-1
```

## ✅ Expected Output

```
NAME                          STATUS          
event-me-gh-runner-1          Up 30 seconds
event-me-gh-runner-2          Up 30 seconds
office365-admin-gh-runner-1   Up 30 seconds
office365-admin-gh-runner-2   Up 30 seconds
```

In GitHub, you should see 4 runners (2 per project) under **Settings → Actions → Runners**.

## 🔧 Common Operations

### Start/Stop specific project

```bash
# Stop only event-me (office365 keeps running)
docker compose -f docker-compose.multi-project.yml --profile event-me stop

# Start it back
docker compose -f docker-compose.multi-project.yml --profile event-me start

# Restart with new token
docker compose -f docker-compose.multi-project.yml --profile event-me restart
```

### Update token (when expired)

```bash
# 1. Edit .env with new token
nano .env

# 2. Restart affected project
docker compose -f docker-compose.multi-project.yml --profile event-me down
docker compose -f docker-compose.multi-project.yml --profile event-me up -d
```

### Add new project

Edit `docker-compose.multi-project.yml`:

```yaml
  new-project-runner-1:
    build: .
    platform: linux/amd64
    container_name: new-project-gh-runner-1
    profiles: ["new-project"]
    environment:
      - RUNNER_URL=${NEW_PROJECT_RUNNER_URL}
      - RUNNER_TOKEN=${NEW_PROJECT_RUNNER_TOKEN}
      - RUNNER_NAME=new-project-runner-1
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - new-project-runner-1-data:/actions-runner/_work

volumes:
  new-project-runner-1-data:
```

Then add to `.env`:

```bash
NEW_PROJECT_RUNNER_URL=https://github.com/user/new-project
NEW_PROJECT_RUNNER_TOKEN=token_here
```

Start it:

```bash
docker compose -f docker-compose.multi-project.yml --profile new-project up -d
```

## 🎯 Why Use Profiles?

| Without Profiles | With Profiles |
|-----------------|---------------|
| All runners start together | Choose which projects to run |
| Can't stop one project independently | Stop/start projects individually |
| Need multiple compose files | One file for everything |
| Token update affects all | Update tokens per project |

## 🆘 Troubleshooting

**Problem**: Runner shows "404 Not Found"
- **Cause**: Token expired (they last 1 hour)
- **Fix**: Generate new token and restart

**Problem**: "port already in use"
- **Cause**: Multiple workflows using same port
- **Fix**: Use `host.docker.internal` and random ports (see main README)

**Problem**: Can't see runners in GitHub
- **Cause**: Wrong URL or token
- **Fix**: Check `.env` file and regenerate token

## 📚 Learn More

- [docs/MULTI_PROJECT_GUIDE.md](docs/MULTI_PROJECT_GUIDE.md) - Complete guide with 3 approaches
- [README.md](../README.md) - Full documentation and CI/CD gotchas
- [docker-compose.multi-project.yml](../docker-compose.multi-project.yml) - Example configuration
