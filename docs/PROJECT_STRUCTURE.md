# Project Structure

## 📁 Repository Layout

```
gh-action-runners/
├── 📄 README.md                          # Main documentation
├── 📄 QUICKSTART_MULTI_PROJECT.md        # 5-min multi-project setup
├── 📄 MULTI_PROJECT_GUIDE.md             # Complete multi-project guide
├── 📄 PROJECT_STRUCTURE.md               # This file
│
├── 🐳 Dockerfile                         # Runner image definition
├── 📜 entrypoint.sh                      # Runner startup script
│
├── �� docker-compose.yml                 # Single project config
├── 🔧 docker-compose.multi-project.yml   # Multi-project config with profiles
│
├── 📝 .env.example                       # Single project env template
├── 📝 .env.multi-project.example         # Multi-project env template
├── 📝 .env                               # Your actual config (gitignored)
│
└── 🙈 .gitignore                         # Git ignore rules
```

## 🎯 Which File to Use?

### Single Project (Simple)

**Use:** `docker-compose.yml` + `.env`

```bash
# Setup
cp .env.example .env
# Edit .env

# Run
docker compose up -d
```

**When to use:**
- ✅ One GitHub repository/organization
- ✅ Simple setup
- ✅ Just getting started

---

### Multiple Projects (Advanced)

**Use:** `docker-compose.multi-project.yml` + `.env`

```bash
# Setup
cp .env.multi-project.example .env
# Edit .env with multiple project tokens

# Run specific projects
docker compose -f docker-compose.multi-project.yml --profile project-a up -d
docker compose -f docker-compose.multi-project.yml --profile project-b up -d

# Or run all
docker compose -f docker-compose.multi-project.yml --profile project-a --profile project-b up -d
```

**When to use:**
- ✅ Multiple repositories/organizations
- ✅ Need independent control per project
- ✅ Want to scale different projects separately
- ✅ Different token expiration times

---

## 📊 Architecture Diagrams

### Single Project Setup

```
┌─────────────────────────────────────────────────┐
│                   Host Machine                   │
│                                                  │
│  ┌────────────────────┐  ┌────────────────────┐ │
│  │   runner-1         │  │   runner-2         │ │
│  │                    │  │                    │ │
│  │  GitHub Actions    │  │  GitHub Actions    │ │
│  │  Runner            │  │  Runner            │ │
│  │                    │  │                    │ │
│  │  ┌──────────────┐  │  │  ┌──────────────┐  │ │
│  │  │ Docker CLI   │  │  │  │ Docker CLI   │  │ │
│  │  └──────┬───────┘  │  │  └──────┬───────┘  │ │
│  └─────────┼──────────┘  └─────────┼──────────┘ │
│            │                       │             │
│            └───────────┬───────────┘             │
│                        │                         │
│                  ┌─────▼─────┐                   │
│                  │   Docker   │                  │
│                  │   Daemon   │                  │
│                  └────────────┘                  │
│                                                  │
│           Connected to: github.com/user/repo    │
└─────────────────────────────────────────────────┘
```

### Multi-Project Setup (with Profiles)

```
┌───────────────────────────────────────────────────────────────┐
│                        Host Machine                            │
│                                                                │
│  Profile: event-me              Profile: office365            │
│  ┌──────────────────┐            ┌──────────────────┐         │
│  │ event-me-runner-1│            │office365-runner-1│         │
│  │ ✓ Connected to   │            │ ✓ Connected to   │         │
│  │   event.me       │            │   office365-admin│         │
│  └──────────────────┘            └──────────────────┘         │
│  ┌──────────────────┐            ┌──────────────────┐         │
│  │ event-me-runner-2│            │office365-runner-2│         │
│  │ ✓ Connected to   │            │ ✓ Connected to   │         │
│  │   event.me       │            │   office365-admin│         │
│  └──────────────────┘            └──────────────────┘         │
│           │                               │                    │
│           └───────────────┬───────────────┘                    │
│                           │                                    │
│                     ┌─────▼─────┐                              │
│                     │   Docker   │                             │
│                     │   Daemon   │                             │
│                     └────────────┘                             │
│                                                                │
│  Isolated volumes per project                                 │
│  • event-me-runner-1-data                                     │
│  • event-me-runner-2-data                                     │
│  • office365-runner-1-data                                    │
│  • office365-runner-2-data                                    │
└───────────────────────────────────────────────────────────────┘
```

## 🔑 Key Concepts

### Docker Compose Profiles

Profiles let you define groups of services that can be started independently:

```yaml
services:
  event-me-runner-1:
    profiles: ["event-me"]  # Only starts with --profile event-me
  
  office365-runner-1:
    profiles: ["office365"]  # Only starts with --profile office365
```

**Commands:**
```bash
# Start only event-me runners
docker compose -f docker-compose.multi-project.yml --profile event-me up -d

# Start only office365 runners  
docker compose -f docker-compose.multi-project.yml --profile office365 up -d

# Start both projects
docker compose -f docker-compose.multi-project.yml --profile event-me --profile office365 up -d

# Stop only one project (others keep running)
docker compose -f docker-compose.multi-project.yml --profile event-me stop
```

### Volume Isolation

Each runner gets its own volume for:
- `_work/` - Workflow working directories
- Build caches
- Downloaded actions
- Git repositories

This prevents conflicts when different projects run simultaneously.

### Container Naming

Unique names prevent conflicts:
- Single project: `event-me-gh-runner-1`, `event-me-gh-runner-2`
- Multi-project: `event-me-gh-runner-1`, `office365-admin-gh-runner-1`

## 📚 Documentation Guide

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [README.md](../README.md) | Main documentation, CI/CD gotchas | Start here |
| [QUICKSTART_MULTI_PROJECT.md](QUICKSTART_MULTI_PROJECT.md) | 5-minute multi-project setup | Want multiple projects quickly |
| [MULTI_PROJECT_GUIDE.md](MULTI_PROJECT_GUIDE.md) | Complete guide with 3 approaches | Need advanced multi-project info |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | This file - architecture overview | Understanding the repo structure |

## 🛠️ Files Explained

### `Dockerfile`
Builds the runner image with:
- Ubuntu base
- GitHub Actions runner binaries (v2.332.0)
- Docker CLI for Docker-in-Docker
- Required dependencies

### `entrypoint.sh`
Handles runner lifecycle:
1. Validates `RUNNER_URL` and `RUNNER_TOKEN`
2. Fixes Docker socket permissions
3. Registers runner with GitHub
4. Starts runner
5. Gracefully unregisters on shutdown

### `docker-compose.yml`
Simple configuration for single project:
- 2 runners by default
- Shared environment variables from `.env`
- Docker socket mounting
- Persistent volumes

### `docker-compose.multi-project.yml`
Advanced configuration with profiles:
- Multiple projects defined
- Each project has 2 runners
- Profile-based service groups
- Independent environment variables per project
- Isolated volumes per runner

### `.env`
Contains sensitive configuration:
```bash
RUNNER_URL=https://github.com/user/repo
RUNNER_TOKEN=ABC123...
```

**⚠️ Never commit this file!** It contains authentication tokens.

### `.env.example` / `.env.multi-project.example`
Template files showing required variables. Safe to commit.

## 🔄 Workflow

### Typical Single Project Workflow

```bash
1. cp .env.example .env
2. Edit .env with token
3. docker compose up -d
4. Check logs: docker compose logs -f
5. Token expired? Edit .env and: docker compose restart
```

### Typical Multi-Project Workflow

```bash
1. cp .env.multi-project.example .env
2. Edit .env with all project tokens
3. docker compose -f docker-compose.multi-project.yml --profile project-a up -d
4. Later: add project-b without stopping project-a:
   docker compose -f docker-compose.multi-project.yml --profile project-b up -d
5. Token expired for project-a? Edit .env and:
   docker compose -f docker-compose.multi-project.yml --profile project-a restart
```

## 💡 Tips

1. **Keep both compose files**: Single project for quick tests, multi-project for production
2. **Use profiles names that match your projects**: Makes commands intuitive
3. **One token per project**: Tokens expire independently
4. **Monitor all runners**: `docker ps --filter "name=gh-runner"`
5. **Backup `.env`**: Keep secure backup of working tokens (not in git!)

## 🚀 Next Steps

- ✅ Read [README.md](../README.md) for complete documentation
- ✅ Try [QUICKSTART_MULTI_PROJECT.md](QUICKSTART_MULTI_PROJECT.md) for hands-on setup
- ✅ Explore [MULTI_PROJECT_GUIDE.md](MULTI_PROJECT_GUIDE.md) for alternative approaches
