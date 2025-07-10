# Essential Commands

Quick reference for common development commands in the Multimodal Search System project.

## Development Server

### Start Backend Server
```bash
# Development mode with auto-reload
cd backend
python -m uvicorn main:app --reload --port 8000

# With specific host
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production mode
python -m uvicorn main:app --workers 4
```

### Start Worker Process
```bash
# Start background worker for file processing
cd backend
python worker.py

# With specific Redis URL
REDIS_URL=redis://localhost:6379 python worker.py
```

### Start Frontend Development
```bash
# Serve static files locally
cd frontend
python -m http.server 3000

# Or using Node.js
npx serve -p 3000
```

## Database Commands

### PostgreSQL Setup
```bash
# Create database
createdb multimodal_search

# Connect to database
psql -d multimodal_search

# Run migrations
psql -d multimodal_search -f migrations/001_initial_schema.sql

# Create pgvector extension
psql -d multimodal_search -c "CREATE EXTENSION IF NOT EXISTS pgvector;"
```

### Database Backup/Restore
```bash
# Backup database
pg_dump multimodal_search > backup_$(date +%Y%m%d).sql

# Restore database
psql -d multimodal_search < backup_20250115.sql

# Export specific table
pg_dump -t uploads multimodal_search > uploads_backup.sql
```

### Common Database Queries
```sql
-- Check processing status
SELECT processing_status, COUNT(*) 
FROM uploads 
GROUP BY processing_status;

-- Find failed uploads
SELECT id, original_filename, processing_error 
FROM uploads 
WHERE processing_status = 'failed';

-- Recent uploads by user
SELECT * FROM uploads 
WHERE user_id = 'USER_UUID' 
ORDER BY created_at DESC 
LIMIT 10;

-- Search performance stats
SELECT AVG(search_latency_ms) as avg_latency, 
       MAX(search_latency_ms) as max_latency,
       COUNT(*) as total_searches
FROM search_history
WHERE created_at > NOW() - INTERVAL '1 day';
```

## Testing Commands

### Run All Tests
```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run with coverage
pytest --cov=backend --cov-report=html

# Open coverage report
open htmlcov/index.html
```

### Run Specific Tests
```bash
# Run single test file
pytest tests/unit/test_upload_model.py

# Run tests matching pattern
pytest -k "upload"

# Run only unit tests
pytest tests/unit/

# Run only integration tests
pytest tests/integration/
```

### Test Debugging
```bash
# Run with print statements visible
pytest -s

# Run with debugger on failure
pytest --pdb

# Run specific test function
pytest tests/unit/test_upload_model.py::test_create_upload
```

## Linting and Type Checking

### Ruff (Fast Python Linter)
```bash
# Check all files
ruff check .

# Check with auto-fix
ruff check --fix .

# Format code
ruff format .

# Check specific file
ruff check backend/models/upload.py
```

### Type Checking with mypy
```bash
# Check all backend code
mypy backend/

# Check specific module
mypy backend/models/

# Ignore missing imports
mypy --ignore-missing-imports backend/
```

## Docker Commands

### Build and Run
```bash
# Build Docker image
docker build -t multimodal-search:latest .

# Run container
docker run -p 8000:8000 --env-file .env multimodal-search:latest

# Run with volume mount
docker run -p 8000:8000 -v $(pwd):/app --env-file .env multimodal-search:latest
```

### Docker Compose
```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Rebuild and start
docker-compose up --build
```

## Redis Commands

### Redis CLI
```bash
# Connect to Redis
redis-cli

# Monitor Redis commands in real-time
redis-cli monitor

# Check queue lengths
redis-cli LLEN queue:uploads:pending
redis-cli LLEN queue:uploads:processing

# Clear specific queue
redis-cli DEL queue:uploads:failed

# Get job status
redis-cli GET job:status:JOB_UUID
```

### Redis Queue Management
```bash
# Move failed jobs back to pending
redis-cli LMOVE queue:uploads:failed queue:uploads:pending RIGHT LEFT

# Count total jobs
redis-cli EVAL "return redis.call('LLEN', 'queue:uploads:pending') + redis.call('LLEN', 'queue:uploads:processing')" 0
```

## Google Cloud Commands

### GCS Operations
```bash
# List buckets
gsutil ls

# List files in bucket
gsutil ls gs://multimodal-uploads-PROJECT_ID/

# Upload file
gsutil cp local_file.jpg gs://multimodal-uploads-PROJECT_ID/test/

# Download file
gsutil cp gs://multimodal-uploads-PROJECT_ID/test/file.jpg ./

# Delete file
gsutil rm gs://multimodal-uploads-PROJECT_ID/test/file.jpg

# Set CORS policy
gsutil cors set cors.json gs://multimodal-uploads-PROJECT_ID
```

### Cloud Run Deployment
```bash
# Deploy to Cloud Run
gcloud run deploy multimodal-search \
  --image gcr.io/PROJECT_ID/multimodal-search:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated

# View service details
gcloud run services describe multimodal-search --region us-central1

# Stream logs
gcloud run services logs multimodal-search --region us-central1 --tail 50
```

### Secret Management
```bash
# Create secret
gcloud secrets create openai-api-key --data-file=openai_key.txt

# Add secret version
echo -n "NEW_API_KEY" | gcloud secrets versions add openai-api-key --data-file=-

# Grant access to service account
gcloud secrets add-iam-policy-binding openai-api-key \
  --member="serviceAccount:multimodal-search-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Monitoring Commands

### View Logs
```bash
# Tail application logs
tail -f logs/app.log

# Search for errors
grep ERROR logs/app.log

# View logs with timestamp range
awk '/2025-01-15 10:00/,/2025-01-15 11:00/' logs/app.log
```

### Performance Monitoring
```bash
# Check API response times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8000/health

# Load test with Apache Bench
ab -n 1000 -c 10 http://localhost:8000/api/search

# Monitor system resources
htop

# Check port usage
lsof -i :8000
```

## Environment Management

### Python Virtual Environment
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Deactivate
deactivate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Freeze current dependencies
pip freeze > requirements.txt
```

### Environment Variables
```bash
# Load from .env file
export $(cat .env | xargs)

# Check current environment
env | grep REDIS

# Set specific variable
export REDIS_URL=redis://localhost:6379
```

## Git Commands

### Common Operations
```bash
# Check status
git status

# Stage all changes
git add .

# Commit with message
git commit -m "feat: Add video processing pipeline"

# Push to remote
git push origin main

# Create feature branch
git checkout -b feature/batch-upload

# Merge branch
git checkout main
git merge feature/batch-upload
```

### Useful Git Aliases
```bash
# Add to ~/.gitconfig
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.last 'log -1 HEAD'
```

## Debugging Commands

### Python Debugging
```bash
# Run with debugger
python -m pdb backend/main.py

# Insert breakpoint in code
import pdb; pdb.set_trace()

# Profile code execution
python -m cProfile -s cumulative backend/worker.py
```

### API Testing with curl
```bash
# Test upload endpoint
curl -X POST http://localhost:8000/api/upload \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@test_image.jpg" \
  -F 'metadata={"tags": ["test"]}'

# Test search endpoint
curl -X POST http://localhost:8000/api/search \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "sunset beach", "limit": 10}'

# Check job status
curl http://localhost:8000/api/upload/status/JOB_UUID \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Quick Scripts

### Reset Development Environment
```bash
# Reset database
dropdb multimodal_search && createdb multimodal_search && psql -d multimodal_search -f migrations/001_initial_schema.sql

# Clear Redis
redis-cli FLUSHALL

# Clear GCS bucket (BE CAREFUL!)
gsutil -m rm -r gs://multimodal-uploads-PROJECT_ID/**
```

### Health Check Script
```bash
#!/bin/bash
# Save as check_health.sh
echo "Checking services..."
curl -s http://localhost:8000/health | jq .
redis-cli ping
psql -d multimodal_search -c "SELECT 1" > /dev/null && echo "PostgreSQL: OK"
```

## Useful Aliases

Add these to your ~/.bashrc or ~/.zshrc:

```bash
# Project navigation
alias cdm="cd ~/path/to/multimodal-search"
alias cdmb="cd ~/path/to/multimodal-search/backend"
alias cdmf="cd ~/path/to/multimodal-search/frontend"

# Common commands
alias runapi="python -m uvicorn main:app --reload"
alias runworker="python worker.py"
alias runtests="pytest -v"
alias checkcode="ruff check . && mypy backend/"

# Docker shortcuts
alias dcu="docker-compose up"
alias dcd="docker-compose down"
alias dcl="docker-compose logs -f"
```