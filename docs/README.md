# Documentation

Complete documentation for GitHub Actions Self-Hosted Runners multi-project setup.

## 📚 Documents

### [Quick Start: Multi-Project Setup](QUICKSTART_MULTI_PROJECT.md)
**⏱️ 5 minutes** - Get multiple projects running fast!

Perfect for:
- ✅ First-time multi-project setup
- ✅ Quick reference guide
- ✅ Common operations

### [Multi-Project Guide](MULTI_PROJECT_GUIDE.md)
**📖 Complete guide** - Three different approaches with pros/cons

Covers:
- ✅ Docker Compose Profiles (recommended)
- ✅ Multiple compose files
- ✅ Subdirectory approach
- ✅ Comparison and recommendations
- ✅ Real-world examples

### [Project Structure](PROJECT_STRUCTURE.md)
**🏗️ Architecture** - Understand how everything works

Includes:
- ✅ File structure overview
- ✅ Architecture diagrams (ASCII art)
- ✅ Detailed file explanations
- ✅ Workflows and tips

## 🚀 Quick Navigation

**Want to start now?** → [QUICKSTART_MULTI_PROJECT.md](QUICKSTART_MULTI_PROJECT.md)

**Need to understand profiles?** → [MULTI_PROJECT_GUIDE.md](MULTI_PROJECT_GUIDE.md)

**Want to see architecture?** → [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)

**Back to main docs** → [../README.md](../README.md)

## 🎯 Common Scenarios

### "I have 2+ projects and want to run runners for each"
→ Start with [QUICKSTART_MULTI_PROJECT.md](QUICKSTART_MULTI_PROJECT.md)

### "I want to understand different approaches"
→ Read [MULTI_PROJECT_GUIDE.md](MULTI_PROJECT_GUIDE.md) comparison section

### "My runners are conflicting"
→ Check [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for volume isolation explanation

### "How do I add a new project?"
→ See [QUICKSTART_MULTI_PROJECT.md](QUICKSTART_MULTI_PROJECT.md) "Add new project" section

## 💡 Key Concepts

**Docker Compose Profiles** = Groups of services you can start independently

**Benefits:**
- Start/stop projects independently
- One config file for everything
- No container/volume conflicts
- Token management per project

**Example:**
```bash
# Start only project A
docker compose -f docker-compose.multi-project.yml --profile project-a up -d

# Add project B (project A keeps running!)
docker compose -f docker-compose.multi-project.yml --profile project-b up -d
```

---

Made with ❤️ for managing multiple GitHub Action runners efficiently!
