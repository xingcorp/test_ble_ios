# Warp AI Global Naming Conventions

## 🌐 Universal Terminal & Workflow Standards
Apply these naming standards across all projects and terminal workflows.

## 📁 File and Directory Naming

### File Naming Conventions
```bash
# ✅ PREFERRED - Clear, descriptive, kebab-case
user-repository.swift
location-coordinator.ts
authentication-service.py
database-migration-001.sql
deploy-production.sh

# ❌ AVOID - Unclear, abbreviated, or inconsistent
UserRepo.swift
locCoord.ts
auth.py
migration1.sql
deploy.sh
```

### Directory Structure
```bash
# ✅ PREFERRED - Hierarchical and purposeful
project-root/
├── src/
│   ├── core/
│   │   ├── networking/
│   │   ├── location/
│   │   └── authentication/
│   ├── features/
│   │   ├── user-profile/
│   │   ├── location-tracking/
│   │   └── push-notifications/
│   └── shared/
│       ├── utilities/
│       ├── extensions/
│       └── constants/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
└── scripts/
    ├── deployment/
    ├── database/
    └── utilities/

# ❌ AVOID - Generic or unclear structure
project/
├── stuff/
├── things/
├── utils/
├── misc/
└── temp/
```

## 🔧 Command and Script Naming

### Script Naming Patterns
```bash
# ✅ PREFERRED - Verb-noun pattern with context
deploy-to-staging.sh
backup-production-database.sh
run-integration-tests.sh
generate-api-documentation.sh
migrate-database-schema.sh

# ❌ AVOID - Abbreviated or unclear purpose
deploy.sh
backup.sh
test.sh
docs.sh
migrate.sh
```

### Command Aliases
```bash
# ✅ PREFERRED - Memorable and meaningful
alias gst='git status'
alias gco='git checkout'
alias gpl='git pull'
alias gps='git push'
alias ll='ls -la'
alias deploy-staging='./scripts/deploy-to-staging.sh'
alias run-tests='npm run test:integration'

# ❌ AVOID - Cryptic or confusing
alias g='git'
alias d='deploy'
alias t='test'
alias x='exit'
```

### Function Naming in Scripts
```bash
# ✅ PREFERRED - Clear purpose and action
deploy_to_environment() {
    local environment=$1
    echo "Deploying to $environment..."
}

validate_environment_variables() {
    if [[ -z "$DATABASE_URL" ]]; then
        echo "Error: DATABASE_URL not set"
        exit 1
    fi
}

backup_database_with_timestamp() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    pg_dump "$DATABASE_URL" > "backup_${timestamp}.sql"
}

# ❌ AVOID - Generic or unclear functions
do_deploy() { }
check_stuff() { }
backup() { }
```

## 🌍 Environment Variables

### Environment Variable Naming
```bash
# ✅ PREFERRED - UPPER_SNAKE_CASE with context
DATABASE_URL="postgresql://localhost:5432/myapp"
API_BASE_URL="https://api.example.com"
JWT_SECRET_KEY="your-secret-key"
REDIS_CONNECTION_STRING="redis://localhost:6379"
LOG_LEVEL="info"
MAX_CONNECTION_POOL_SIZE=10
STAGING_DATABASE_URL="postgresql://staging.example.com:5432/myapp"
PRODUCTION_API_KEY="prod-api-key"

# ❌ AVOID - Generic or unclear variables
URL="some-url"
KEY="some-key"
CONFIG="some-config"
DB="database-url"
API="api-url"
```

### Environment-Specific Prefixes
```bash
# ✅ PREFERRED - Clear environment separation
DEV_DATABASE_URL="postgresql://localhost:5432/myapp_dev"
STAGING_DATABASE_URL="postgresql://staging:5432/myapp_staging"
PROD_DATABASE_URL="postgresql://prod:5432/myapp_prod"

DEV_API_KEY="dev-api-key"
STAGING_API_KEY="staging-api-key"
PROD_API_KEY="prod-api-key"

# ❌ AVOID - Ambiguous environment handling
DATABASE_URL_1="dev-db"
DATABASE_URL_2="staging-db"
DATABASE_URL_3="prod-db"
```

## 🔄 Workflow and Task Naming

### Workflow File Naming
```yaml
# ✅ PREFERRED - Clear workflow purpose
# .warp/workflows/deploy-to-staging.yml
name: "Deploy to Staging"
command: |
  ./scripts/deploy-to-staging.sh
  echo "✅ Deployment to staging completed"

# .warp/workflows/run-full-test-suite.yml
name: "Run Full Test Suite"
command: |
  npm run test:unit
  npm run test:integration
  npm run test:e2e

# ❌ AVOID - Generic or unclear workflows
# .warp/workflows/task1.yml
# .warp/workflows/script.yml
# .warp/workflows/deploy.yml
```

### Task Naming in Workflows
```yaml
# ✅ PREFERRED - Descriptive task names
tasks:
  - name: "Install Dependencies"
    command: "npm install"
  
  - name: "Run TypeScript Compilation"
    command: "npm run build"
  
  - name: "Execute Unit Tests"
    command: "npm run test:unit"
  
  - name: "Deploy to Staging Environment"
    command: "./scripts/deploy-to-staging.sh"

# ❌ AVOID - Generic task names
tasks:
  - name: "Setup"
    command: "npm install"
  
  - name: "Build"
    command: "npm run build"
  
  - name: "Test"
    command: "npm test"
```

## 🐳 Docker and Container Naming

### Docker Image Naming
```bash
# ✅ PREFERRED - Clear purpose and versioning
myapp-api:1.2.3
myapp-frontend:latest
myapp-database-migration:v2.1.0
myapp-worker:staging
myapp-nginx-proxy:production

# ❌ AVOID - Generic or unclear images
app:latest
frontend:v1
db:prod
worker:1
```

### Container and Service Naming
```yaml
# ✅ PREFERRED - docker-compose.yml
services:
  api-server:
    image: myapp-api:latest
    container_name: myapp-api-server
  
  postgres-database:
    image: postgres:14
    container_name: myapp-postgres-db
  
  redis-cache:
    image: redis:7
    container_name: myapp-redis-cache
  
  nginx-reverse-proxy:
    image: nginx:alpine
    container_name: myapp-nginx-proxy

# ❌ AVOID - Generic service names
services:
  app:
    image: myapp:latest
  
  db:
    image: postgres:14
  
  cache:
    image: redis:7
```

## 📊 Monitoring and Logging

### Log File Naming
```bash
# ✅ PREFERRED - Timestamped and categorized
application-2024-01-15.log
error-2024-01-15.log
access-2024-01-15.log
database-migration-2024-01-15.log
deployment-staging-2024-01-15.log

# ❌ AVOID - Generic or unclear logs
app.log
error.log
log.txt
output.log
```

### Metric and Alert Naming
```bash
# ✅ PREFERRED - Clear metric purpose
api_response_time_seconds
database_connection_pool_size
user_authentication_success_rate
memory_usage_percentage
disk_space_available_bytes

# ❌ AVOID - Abbreviated or unclear metrics
api_time
db_conn
auth_rate
mem_usage
disk_space
```

## 🎯 Quality Standards

### Naming Checklist
- [ ] Names are pronounceable and searchable
- [ ] Context is clear without additional explanation
- [ ] Consistent vocabulary across all scripts and configs
- [ ] Environment-specific prefixes where applicable
- [ ] No abbreviations unless universally understood
- [ ] Hierarchical structure reflects logical organization

### Red Flags to Avoid
- [ ] Single-letter variables or aliases
- [ ] Numbers without clear meaning (script1, config2)
- [ ] Generic terms (data, info, stuff, thing)
- [ ] Inconsistent naming patterns within same project
- [ ] Cryptic abbreviations (usr, cfg, tmp, bak)

## 🚀 Integration with Development Workflow

### Git Branch Naming
```bash
# ✅ PREFERRED - Clear feature and purpose
feature/user-authentication-system
bugfix/location-permission-crash
hotfix/production-database-connection
refactor/networking-layer-cleanup
chore/update-dependencies

# ❌ AVOID - Generic or unclear branches
feature/new-stuff
fix/bug
update/things
dev/work
```

### Commit Message Standards
```bash
# ✅ PREFERRED - Clear action and scope
feat(auth): implement user authentication system
fix(location): resolve permission request crash
refactor(network): simplify API client architecture
chore(deps): update npm dependencies to latest versions
docs(readme): add installation and setup instructions

# ❌ AVOID - Vague or unclear commits
update stuff
fix bug
changes
work in progress
misc updates
```
