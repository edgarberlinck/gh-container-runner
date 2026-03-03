# Guia: Gerenciamento de Runners para Múltiplos Projetos

Este guia apresenta **3 abordagens** para gerenciar runners de diferentes projetos sem bagunçar o repositório.

---

## 🏆 Opção 1: Docker Compose Profiles (Recomendada)

**Vantagens:**
- ✅ Um único arquivo para todos os projetos
- ✅ Controle granular sobre quais runners iniciar
- ✅ Volumes e containers isolados por projeto
- ✅ Fácil de manter

**Como usar:**

### 1. Configure as variáveis de ambiente

```bash
cp .env.multi-project.example .env
# Edite o .env com os tokens de cada projeto
```

### 2. Inicie runners de um projeto específico

```bash
# Apenas event-me
docker compose -f docker-compose.multi-project.yml --profile event-me up -d

# Apenas other-project
docker compose -f docker-compose.multi-project.yml --profile other-project up -d

# Todos os projetos
docker compose -f docker-compose.multi-project.yml --profile event-me --profile other-project up -d
```

### 3. Gerenciar runners

```bash
# Ver logs de um projeto
docker compose -f docker-compose.multi-project.yml logs -f event-me-runner-1

# Parar runners de um projeto
docker compose -f docker-compose.multi-project.yml --profile event-me down

# Restart de um projeto
docker compose -f docker-compose.multi-project.yml --profile other-project restart
```

### 4. Adicionar novo projeto

Edite `docker-compose.multi-project.yml`:

```yaml
  new-project-runner-1:
    build: .
    platform: linux/amd64
    container_name: new-project-gh-runner-1
    profiles: ["new-project"]  # Novo profile
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

---

## 📁 Opção 2: Múltiplos Arquivos Compose

**Vantagens:**
- ✅ Separação total por projeto
- ✅ Cada projeto tem seu próprio arquivo
- ✅ Mais fácil entender para projetos complexos

**Como usar:**

### 1. Crie um arquivo por projeto

```bash
# Para event-me
cp docker-compose.yml docker-compose.event-me.yml

# Para outro projeto
cp docker-compose.yml docker-compose.other-project.yml
```

### 2. Edite cada arquivo

`docker-compose.event-me.yml`:
```yaml
services:
  runner-1:
    container_name: event-me-gh-runner-1
    environment:
      - RUNNER_URL=${EVENT_ME_RUNNER_URL}
      - RUNNER_TOKEN=${EVENT_ME_RUNNER_TOKEN}
      - RUNNER_NAME=event-me-runner-1
    volumes:
      - event-me-runner-1-data:/actions-runner/_work

volumes:
  event-me-runner-1-data:
```

### 3. Use arquivos separados

```bash
# Event-me
docker compose -f docker-compose.event-me.yml up -d

# Other project
docker compose -f docker-compose.other-project.yml up -d
```

---

## 📂 Opção 3: Subdiretórios por Projeto

**Vantagens:**
- ✅ Isolamento completo
- ✅ Cada projeto é independente
- ✅ Diferentes versões do runner por projeto

**Estrutura:**

```
gh-action-runners/
├── projects/
│   ├── event-me/
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── README.md
│   └── other-project/
│       ├── docker-compose.yml
│       ├── .env
│       └── README.md
├── Dockerfile (compartilhado)
└── entrypoint.sh (compartilhado)
```

**Setup:**

```bash
# Criar estrutura
mkdir -p projects/event-me projects/other-project

# Copiar configs
cp docker-compose.yml projects/event-me/
cp docker-compose.yml projects/other-project/

# Usar
cd projects/event-me
docker compose up -d

cd ../other-project
docker compose up -d
```

---

## 🎯 Comparação Rápida

| Aspecto | Profiles | Múltiplos Files | Subdiretórios |
|---------|----------|----------------|---------------|
| Simplicidade | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Isolamento | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Manutenção | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Escalabilidade | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## 💡 Recomendação

**Use Opção 1 (Profiles)** se:
- Você tem até ~5 projetos
- Quer gerenciamento centralizado
- Prefere simplicidade

**Use Opção 2 (Múltiplos Files)** se:
- Cada projeto tem configurações muito diferentes
- Você quer separação clara no git
- Prefere arquivos menores

**Use Opção 3 (Subdiretórios)** se:
- Você tem muitos projetos (5+)
- Cada projeto precisa de versões diferentes do runner
- Você quer isolamento total

---

## 🔧 Scripts Úteis

### Script para trocar tokens facilmente

Crie `update-token.sh`:

```bash
#!/bin/bash

PROJECT=$1
NEW_TOKEN=$2

if [ -z "$PROJECT" ] || [ -z "$NEW_TOKEN" ]; then
    echo "Usage: ./update-token.sh <project-name> <new-token>"
    exit 1
fi

# Atualiza .env
sed -i '' "s/${PROJECT^^}_RUNNER_TOKEN=.*/${PROJECT^^}_RUNNER_TOKEN=$NEW_TOKEN/" .env

# Restart runners
docker compose -f docker-compose.multi-project.yml --profile $PROJECT restart

echo "✅ Token updated and runners restarted for $PROJECT"
```

Uso:
```bash
./update-token.sh event-me ABC123XYZ
```

### Script para adicionar novo projeto

Crie `add-project.sh`:

```bash
#!/bin/bash

PROJECT_NAME=$1
RUNNER_URL=$2
RUNNER_TOKEN=$3

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: ./add-project.sh <project-name> <runner-url> <runner-token>"
    exit 1
fi

echo "
# $PROJECT_NAME Project
${PROJECT_NAME^^}_RUNNER_URL=$RUNNER_URL
${PROJECT_NAME^^}_RUNNER_TOKEN=$RUNNER_TOKEN
" >> .env

echo "✅ Project $PROJECT_NAME added to .env"
echo "📝 Now add the service definition to docker-compose.multi-project.yml"
```

---

## 🚨 Lembretes Importantes

1. **Tokens expiram em 1 hora** - Gere novos tokens antes de subir runners
2. **Use `.gitignore`** - Nunca commitar `.env` com tokens
3. **Container names únicos** - Cada projeto precisa de nomes diferentes
4. **Volumes separados** - Cada runner tem seu próprio volume
5. **Port conflicts** - Atenção ao usar múltiplos runners simultaneamente

---

## 📚 Exemplos de Uso Real

### Cenário 1: Dev + Prod do mesmo projeto

```bash
# .env
DEV_RUNNER_URL=https://github.com/org/project
DEV_RUNNER_TOKEN=token1

PROD_RUNNER_URL=https://github.com/org/project
PROD_RUNNER_TOKEN=token2

# Subir apenas dev
docker compose -f docker-compose.multi-project.yml --profile dev up -d

# Subir apenas prod
docker compose -f docker-compose.multi-project.yml --profile prod up -d
```

### Cenário 2: Múltiplos clientes

```bash
# Cliente A
docker compose -f docker-compose.multi-project.yml --profile client-a up -d

# Cliente B
docker compose -f docker-compose.multi-project.yml --profile client-b up -d

# Ver status de todos
docker ps --filter "name=gh-runner"
```

### Cenário 3: Manutenção de um projeto sem afetar outros

```bash
# Parar event-me para manutenção (other-project continua rodando)
docker compose -f docker-compose.multi-project.yml --profile event-me down

# Rebuild apenas event-me
docker compose -f docker-compose.multi-project.yml build

# Restart event-me
docker compose -f docker-compose.multi-project.yml --profile event-me up -d
```
