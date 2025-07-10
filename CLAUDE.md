# Multimodal Search System - Claude Code Context

This is the main context file for the Multimodal Search System project. It provides comprehensive guidance for development, architecture, and best practices.

## Quick Start

1. **Production Setup**:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   
   # Production server with Gunicorn
   gunicorn main:app \
       --workers 4 \
       --worker-class uvicorn.workers.UvicornWorker \
       --bind 0.0.0.0:8000 \
       --timeout 300 \
       --graceful-timeout 60 \
       --access-logfile - \
       --error-logfile - \
       --preload
   ```

2. **Database Setup**:
   ```bash
   # Use Alembic migrations (never manual SQL in production)
   alembic upgrade head
   ```

3. **Environment Variables**: Use Google Secret Manager or environment-specific configs (never .env files in production)

## Project Overview

A multimodal AI-powered search system that processes images, videos, audio files, and documents. Users upload files which are analyzed by Gemini Pro to generate summaries, then embedded using OpenAI's text-embedding-3-small for semantic search via pgvector.

## Key Dependencies

```txt
# Core Framework
fastapi==0.115.0
uvicorn[standard]==0.32.0
gunicorn==23.0.0
python-multipart==0.0.12

# Database
asyncpg==0.30.0
pgvector==0.3.6
sqlalchemy==2.0.35
alembic==1.13.3

# AI/ML
google-generativeai==0.8.3
openai==1.54.0
pillow==11.0.0
opencv-python-headless==4.10.0  # Headless for production

# Cloud Services
google-cloud-storage==2.18.2
google-cloud-secret-manager==2.20.2
firebase-admin==6.6.0
redis[hiredis]==5.2.0  # With C speedups

# Production Utilities
pydantic==2.9.2
pydantic-settings==2.6.1
prometheus-client==0.21.0
sentry-sdk[fastapi]==2.17.0
python-json-logger==2.0.7

# Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
slowapi==0.1.9

# Testing (separate requirements-test.txt in production)
# pytest==8.3.3
# pytest-asyncio==0.24.0
# pytest-cov==5.0.0

# Linting (CI/CD only, not in production image)
# ruff==0.8.0
# mypy==1.13.0
```

## Architecture Decisions (FINAL)

### Core Technology Stack
```yaml
Backend: Python 3.11 + FastAPI + Gunicorn (ASGI)
Database: Cloud SQL PostgreSQL 16 + pgvector + pgbouncer
Cache/Queue: Redis (Cloud Memorystore)
Storage: Google Cloud Storage with CDN
AI Models: 
  - Gemini Pro 1.5 (multimodal analysis)
  - OpenAI text-embedding-3-small (1536 dimensions)
Auth: Firebase Auth (managed service)
Frontend: CDN-hosted static files
Infrastructure: Terraform + Cloud Run + Load Balancer
Monitoring: Prometheus + Grafana + Sentry
Secrets: Google Secret Manager
```

### Processing Strategy
- **Asynchronous Processing** with Redis job queue
- Immediate file upload to GCS, return job ID
- Background worker processes files
- WebSocket/SSE for real-time status updates

### Key Constraints
- File size limit: 100MB
- Processing timeout: 5 minutes per file
- Search results: Top 20 most relevant
- User access: Users see only their own files

## Import Additional Documentation

@.claude/commands.md
@.claude/workflows.md
@.claude/patterns.md
@.claude/errors.md

## Production Environment Setup

### Prerequisites
- Docker 24.0+
- Kubernetes 1.28+ or Cloud Run
- Terraform 1.6+
- Google Cloud SDK
- Production SSL certificates

### Infrastructure Provisioning

1. **Terraform Setup**:
   ```bash
   cd infrastructure
   terraform init
   terraform plan -var="project_id=$GCP_PROJECT_ID"
   terraform apply -auto-approve
   ```

2. **Database Setup with Migrations**:
   ```bash
   # Never create database manually - use Terraform
   # Migrations run automatically on deployment
   kubectl apply -f k8s/migrations-job.yaml
   ```

3. **Secrets Configuration**:
   ```bash
   # Create secrets in Google Secret Manager
   gcloud secrets create db-connection-string \
     --data-file=- <<< "postgresql://user:pass@/dbname?host=/cloudsql/CONNECTION_NAME"
   
   gcloud secrets create redis-connection-string \
     --data-file=- <<< "redis://10.0.0.3:6379/0"
   
   gcloud secrets create openai-api-key \
     --data-file=- <<< "$OPENAI_API_KEY"
   ```

4. **Deploy Application**:
   ```bash
   # Build and push Docker image
   docker build -t gcr.io/$GCP_PROJECT_ID/multimodal-search:$VERSION .
   docker push gcr.io/$GCP_PROJECT_ID/multimodal-search:$VERSION
   
   # Deploy to Cloud Run
   gcloud run deploy multimodal-search \
     --image gcr.io/$GCP_PROJECT_ID/multimodal-search:$VERSION \
     --platform managed \
     --region us-central1 \
     --no-allow-unauthenticated \
     --service-account multimodal-search@$GCP_PROJECT_ID.iam.gserviceaccount.com \
     --set-secrets="DATABASE_URL=db-connection-string:latest,REDIS_URL=redis-connection-string:latest"
   ```

5. **Verify Deployment**:
   ```bash
   # Health checks
   curl https://api.yourdomain.com/health
   
   # Check metrics
   curl https://api.yourdomain.com/metrics
   ```

## Production Database Configuration

### Connection Pooling with PgBouncer

```ini
# pgbouncer.ini
[databases]
multimodal_search = host=10.0.0.5 port=5432 dbname=multimodal_search

[pgbouncer]
listen_port = 6432
listen_addr = *
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
reserve_pool_size = 5
reserve_pool_timeout = 3
server_lifetime = 3600
server_idle_timeout = 600
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
```

### Application Database Configuration

```python
# database/connection.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.pool import NullPool
import asyncpg

class DatabaseManager:
    """Production database connection management"""
    
    def __init__(self, database_url: str):
        # Use pgbouncer connection
        self.engine = create_async_engine(
            database_url.replace("postgresql://", "postgresql+asyncpg://"),
            poolclass=NullPool,  # Let pgbouncer handle pooling
            connect_args={
                "server_settings": {
                    "application_name": "multimodal_search",
                    "jit": "off"
                },
                "command_timeout": 60,
                "prepared_statement_cache_size": 0,  # Disable with pgbouncer
            }
        )
    
    async def get_session(self) -> AsyncSession:
        async with AsyncSession(self.engine, expire_on_commit=False) as session:
            yield session
```

### Production Database Optimizations

```sql
-- Performance settings for Cloud SQL
ALTER DATABASE multimodal_search SET shared_preload_libraries = 'pg_stat_statements,pgvector';
ALTER DATABASE multimodal_search SET effective_cache_size = '3GB';
ALTER DATABASE multimodal_search SET maintenance_work_mem = '256MB';
ALTER DATABASE multimodal_search SET random_page_cost = 1.1;
ALTER DATABASE multimodal_search SET effective_io_concurrency = 200;
ALTER DATABASE multimodal_search SET max_parallel_workers_per_gather = 2;
ALTER DATABASE multimodal_search SET max_parallel_workers = 8;
ALTER DATABASE multimodal_search SET max_parallel_maintenance_workers = 2;

-- pgvector optimizations
ALTER DATABASE multimodal_search SET ivfflat.probes = 10;
```

## Testing Strategy

### Test Structure
```
tests/
├── unit/           # Unit tests for models and services
├── integration/    # API endpoint tests
├── fixtures/       # Test data and mocks
└── conftest.py     # Shared test configuration
```

### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=backend --cov-report=html

# Run specific test file
pytest tests/unit/test_upload_model.py

# Run tests matching pattern
pytest -k "test_upload"
```

### Test Patterns
```python
# Use pytest fixtures for dependency injection
@pytest.fixture
async def test_client():
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

# Mock external services
@pytest.fixture
def mock_gemini(mocker):
    return mocker.patch('services.ai.GeminiService.analyze')

# Test async functions
@pytest.mark.asyncio
async def test_upload_creation(db_session):
    upload = await Upload.create(user_id=test_user_id, file_data=test_data)
    assert upload.id is not None
```

## Detailed System Architecture

### Data Flow
1. **Upload**: Frontend → FastAPI → GCS → Redis Queue
2. **Processing**: Worker → Gemini Pro → OpenAI Embeddings → PostgreSQL
3. **Search**: Query → OpenAI Embedding → pgvector similarity search
4. **Results**: PostgreSQL → Thumbnails/Previews → Frontend

### Component Specifications

#### 1. Google Cloud Storage (GCS)
```
Bucket: multimodal-uploads-{project-id}
Structure:
  /{user_id}/{file_id}/{original_filename}
  /{user_id}/{file_id}/thumbnail.jpg  # Generated thumbnails
  /{user_id}/{file_id}/preview.mp4    # Video previews (first 30s)
```

#### 2. PostgreSQL Database Schema
```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";

-- Main uploads table
CREATE TABLE uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    
    -- File information
    gs_uri TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    file_type VARCHAR(20) NOT NULL CHECK (file_type IN ('image', 'video', 'audio', 'document')),
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_hash VARCHAR(64) NOT NULL, -- SHA-256 for duplicate detection
    
    -- Processing status
    processing_status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
    processing_started_at TIMESTAMP,
    processing_completed_at TIMESTAMP,
    processing_error TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- AI analysis results
    gemini_summary TEXT,
    gemini_token_count INTEGER,
    embedding vector(1536),
    embedding_model VARCHAR(50) DEFAULT 'text-embedding-3-small',
    
    -- Metadata
    metadata JSONB DEFAULT '{}', -- Stores EXIF, duration, dimensions, etc.
    thumbnail_uri TEXT,
    preview_uri TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_uploads_user_id ON uploads(user_id);
CREATE INDEX idx_uploads_user_created ON uploads(user_id, created_at DESC);
CREATE INDEX idx_uploads_status ON uploads(processing_status) WHERE processing_status != 'completed';
CREATE INDEX idx_uploads_file_hash ON uploads(file_hash);
CREATE INDEX idx_uploads_embedding ON uploads USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Processing queue table
CREATE TABLE processing_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    upload_id UUID REFERENCES uploads(id) ON DELETE CASCADE,
    job_type VARCHAR(50) NOT NULL,
    priority INTEGER DEFAULT 5,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    status VARCHAR(20) DEFAULT 'queued',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Search history for analytics
CREATE TABLE search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    query_text TEXT NOT NULL,
    query_embedding vector(1536),
    result_count INTEGER,
    search_latency_ms INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 3. Redis Queue Structure
```python
# Job queue keys
UPLOAD_QUEUE = "queue:uploads:pending"
PROCESSING_QUEUE = "queue:uploads:processing"
FAILED_QUEUE = "queue:uploads:failed"

# Job status keys (TTL: 24 hours)
JOB_STATUS = "job:status:{job_id}"

# Rate limiting keys
RATE_LIMIT_USER = "ratelimit:user:{user_id}"  # TTL: 1 hour

# Job payload structure
{
    "job_id": "uuid",
    "upload_id": "uuid",
    "user_id": "uuid",
    "file_type": "image|video|audio|document",
    "gs_uri": "gs://bucket/path",
    "priority": 5,  # 1-10, higher = more important
    "created_at": "2025-01-15T10:00:00Z",
    "attempts": 0
}
```

## File Processing Pipelines

### Image Processing Pipeline
```python
def process_image(gs_uri: str, upload_id: str):
    # 1. Download from GCS
    # 2. Generate thumbnail (300x300)
    # 3. Extract EXIF metadata
    # 4. Send to Gemini Pro for analysis
    # 5. Generate embedding from summary
    # 6. Update database
    # 7. Upload thumbnail to GCS
```

### Video Processing Pipeline
```python
def process_video(gs_uri: str, upload_id: str):
    # 1. Download first 60 seconds
    # 2. Extract frames (1 per 10 seconds)
    # 3. Generate thumbnail from first frame
    # 4. Create 30-second preview clip
    # 5. Extract metadata (duration, codec, resolution)
    # 6. Send frames to Gemini Pro
    # 7. Generate embedding
    # 8. Upload preview/thumbnail to GCS
```

### Audio Processing Pipeline
```python
def process_audio(gs_uri: str, upload_id: str):
    # 1. Download from GCS
    # 2. Extract metadata (duration, bitrate)
    # 3. Create waveform visualization
    # 4. Send to Gemini Pro (up to 5 minutes)
    # 5. Generate embedding
    # 6. Store waveform as thumbnail
```

### Document Processing Pipeline
```python
def process_document(gs_uri: str, upload_id: str):
    # 1. Download from GCS
    # 2. Extract text (PyPDF2 for PDFs)
    # 3. OCR if needed (for image PDFs)
    # 4. Create first-page thumbnail
    # 5. Send text to Gemini Pro (first 10k chars)
    # 6. Generate embedding
    # 7. Upload thumbnail
```

## API Endpoints Specification

### Authentication
All endpoints require Firebase JWT token in header:
```
Authorization: Bearer {firebase_jwt_token}
```

### File Upload Endpoints
```python
POST /api/upload
Body: multipart/form-data
  - file: binary
  - metadata: JSON (optional)
Response: {
    "job_id": "uuid",
    "upload_id": "uuid",
    "status": "queued",
    "estimated_time": 30
}

GET /api/upload/status/{job_id}
Response: {
    "status": "processing|completed|failed",
    "progress": 75,
    "error": null,
    "result": {...} // if completed
}

GET /api/uploads
Query params: ?limit=20&offset=0&file_type=image
Response: {
    "uploads": [...],
    "total": 150,
    "has_more": true
}

DELETE /api/upload/{upload_id}
Response: {"success": true}
```

### Search Endpoints
```python
POST /api/search
Body: {
    "query": "sunset over mountains",
    "file_types": ["image", "video"],  // optional filter
    "limit": 20
}
Response: {
    "results": [
        {
            "upload_id": "uuid",
            "filename": "vacation.jpg",
            "file_type": "image",
            "summary": "...",
            "similarity_score": 0.92,
            "thumbnail_url": "https://...",
            "created_at": "2025-01-15T10:00:00Z"
        }
    ],
    "search_id": "uuid",
    "processing_time_ms": 45
}

GET /api/search/history
Response: {
    "searches": [...],
    "total": 50
}
```

### File Access Endpoints
```python
GET /api/file/{upload_id}/thumbnail
Response: Redirect to signed GCS URL (5 min expiry)

GET /api/file/{upload_id}/preview
Response: Redirect to signed GCS URL (5 min expiry)

GET /api/file/{upload_id}/download
Response: Redirect to signed GCS URL (5 min expiry)

GET /api/file/{upload_id}/metadata
Response: {
    "filename": "video.mp4",
    "file_type": "video",
    "size": 52428800,
    "duration": 120,
    "dimensions": {"width": 1920, "height": 1080},
    "created_at": "2025-01-15T10:00:00Z"
}
```

## Error Handling Strategy

### Graceful Degradation
```python
class ProcessingError(Exception):
    def __init__(self, error_type, message, retry_able=True):
        self.error_type = error_type
        self.message = message
        self.retry_able = retry_able

# Error types
ERRORS = {
    "GEMINI_QUOTA": ProcessingError("quota_exceeded", "Gemini API quota exceeded", retry_able=True),
    "FILE_TOO_LARGE": ProcessingError("file_size", "File exceeds token limit", retry_able=False),
    "UNSUPPORTED_FORMAT": ProcessingError("format", "File format not supported", retry_able=False),
    "NETWORK_ERROR": ProcessingError("network", "Network timeout", retry_able=True),
    "CORRUPT_FILE": ProcessingError("corrupt", "File appears corrupted", retry_able=False)
}

# Retry logic
MAX_RETRIES = 3
RETRY_DELAYS = [10, 60, 300]  # seconds
```

### User Feedback
- Clear error messages in UI
- Suggested actions for common errors
- Option to retry failed uploads
- Email notification for processing completion (optional)

## Security Implementation

### Firebase Authentication
```python
# Middleware for all protected routes
async def verify_firebase_token(authorization: str):
    token = authorization.replace("Bearer ", "")
    decoded = firebase_admin.auth.verify_id_token(token)
    return decoded["uid"]
```

### Access Control
- Row-level security: Users can only access their own files
- Rate limiting: 100 uploads per user per day
- File validation: Check MIME types and magic bytes
- Content scanning: Basic NSFW detection for images

### Data Privacy
- 30-day retention for deleted files
- No sharing between users
- Encrypted GCS storage
- No PII in Gemini summaries

## Frontend Specifications

### Upload Interface
```html
<!-- Drag & drop with progress -->
<div id="upload-zone" class="upload-dropzone">
    <input type="file" id="file-input" multiple accept="image/*,video/*,audio/*,.pdf">
    <div class="upload-progress" style="display:none;">
        <div class="progress-bar"></div>
        <span class="progress-text">Uploading... 45%</span>
    </div>
</div>

<!-- Real-time status updates via WebSocket -->
<script>
const ws = new WebSocket('wss://api.example.com/ws');
ws.onmessage = (event) => {
    const status = JSON.parse(event.data);
    updateUploadStatus(status);
};
</script>
```

### Search Interface
```html
<!-- Search with filters -->
<div class="search-container">
    <input type="text" id="search-input" placeholder="Search your files...">
    <div class="filters">
        <label><input type="checkbox" value="image"> Images</label>
        <label><input type="checkbox" value="video"> Videos</label>
        <label><input type="checkbox" value="audio"> Audio</label>
        <label><input type="checkbox" value="document"> Documents</label>
    </div>
</div>

<!-- Results grid with lazy loading -->
<div class="results-grid" id="search-results">
    <!-- Dynamically populated -->
</div>
```

### Result Display
- Grid layout with thumbnails
- Hover for preview (images/videos)
- Click for full view/play
- Download button
- Delete option with confirmation

## Performance Optimizations

### Caching Strategy
```python
# Redis caching layers
CACHE_SEARCH_RESULTS = "cache:search:{query_hash}"  # TTL: 5 minutes
CACHE_USER_UPLOADS = "cache:uploads:{user_id}"     # TTL: 1 minute
CACHE_THUMBNAILS = "cache:thumbnail:{upload_id}"   # TTL: 1 hour

# Response caching
@cache(ttl=300)
async def search_files(query: str, user_id: str):
    # Implementation
```

### Database Optimizations
- Partitioning by user_id for large scale
- Periodic VACUUM for pgvector performance
- Connection pooling (min=10, max=100)
- Read replicas for search queries

### Processing Optimizations
- Batch embeddings (up to 100 at once)
- Parallel frame extraction for videos
- Thumbnail generation on upload (not on view)
- Progressive video streaming

## Deployment Configuration

### Cloud Run Service
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: multimodal-search-api
spec:
  template:
    metadata:
      annotations:
        run.googleapis.com/execution-environment: gen2
        run.googleapis.com/cpu-throttling: "false"
    spec:
      containerConcurrency: 100
      timeoutSeconds: 300
      serviceAccountName: multimodal-search-sa
      containers:
      - image: gcr.io/PROJECT_ID/multimodal-search:latest
        resources:
          limits:
            cpu: "4"
            memory: "8Gi"
        env:
        - name: REDIS_URL
          value: "redis://10.0.0.3:6379"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
```

### Environment Variables
```bash
# Required environment variables
DATABASE_URL=postgresql://user:pass@host/db
REDIS_URL=redis://localhost:6379
GCS_BUCKET=multimodal-uploads-{project-id}
GOOGLE_CLOUD_PROJECT=project-id
GEMINI_API_KEY=***
OPENAI_API_KEY=***
FIREBASE_ADMIN_SDK_PATH=/secrets/firebase-admin.json

# Optional
MAX_FILE_SIZE=104857600  # 100MB
PROCESSING_TIMEOUT=300   # 5 minutes
ENABLE_CONTENT_MODERATION=true
```

## Monitoring & Observability

### Key Metrics
```python
# Prometheus metrics
upload_counter = Counter('uploads_total', 'Total uploads', ['file_type', 'status'])
processing_duration = Histogram('processing_duration_seconds', 'Processing time', ['file_type'])
search_latency = Histogram('search_latency_seconds', 'Search response time')
active_jobs = Gauge('active_processing_jobs', 'Currently processing jobs')
```

### Logging Structure
```json
{
    "timestamp": "2025-01-15T10:00:00Z",
    "level": "INFO",
    "service": "processor",
    "user_id": "uuid",
    "upload_id": "uuid",
    "action": "process_video",
    "duration_ms": 4523,
    "status": "success",
    "metadata": {
        "file_size": 52428800,
        "gemini_tokens": 1523
    }
}
```

### Alerts
- Processing queue depth > 1000
- Error rate > 5% over 5 minutes
- API response time > 2 seconds (p95)
- Gemini API quota approaching limit

## Cost Management

### API Cost Estimates
```
Gemini Pro: ~$0.00125 per 1K tokens
- Image: ~500 tokens = $0.0006
- Video: ~2000 tokens = $0.0025
- Audio: ~1500 tokens = $0.0019
- Document: ~1000 tokens = $0.0013

OpenAI Embeddings: $0.00002 per 1K tokens
- ~150 tokens per summary = $0.000003

Monthly estimate (1000 users, 100 files each):
- Gemini: ~$150
- OpenAI: ~$0.30
- GCS: ~$20
- Cloud SQL: ~$100
```

### Cost Optimization
- Cache embeddings aggressively
- Batch API calls
- Implement user quotas
- Archive old/unused files
- Use Cloud CDN for thumbnails

## Future Enhancements (Phase 2+)

1. **Advanced Search**
   - Hybrid search (vector + keyword)
   - Faceted filtering
   - Semantic re-ranking

2. **Batch Operations**
   - Bulk upload via ZIP
   - Batch delete/download
   - Folder organization

3. **Enhanced AI**
   - Custom fine-tuned models
   - Multi-language support
   - Better video understanding

4. **Collaboration**
   - Shared folders
   - Public links
   - Team workspaces

5. **Analytics**
   - Usage dashboards
   - Search insights
   - Popular content

## Implementation Checklist

### Phase 1 (MVP)
- [ ] Basic FastAPI server with Firebase auth
- [ ] PostgreSQL with pgvector setup
- [ ] GCS bucket configuration
- [ ] Simple upload endpoint
- [ ] Gemini Pro integration for images
- [ ] OpenAI embedding generation
- [ ] Basic search endpoint
- [ ] Simple HTML/JS frontend
- [ ] Docker container for Cloud Run

### Phase 2 (Production)
- [ ] Redis queue implementation
- [ ] Async processing workers
- [ ] All file type support
- [ ] Thumbnail generation
- [ ] WebSocket status updates
- [ ] Error handling & retries
- [ ] Rate limiting
- [ ] Monitoring setup
- [ ] Cost tracking

### Phase 3 (Scale)
- [ ] Performance optimizations
- [ ] Advanced search features
- [ ] Batch operations
- [ ] Analytics dashboard
- [ ] Auto-scaling configuration

## Backend Architecture Guidelines

### Core Principles

This project follows strict architectural patterns and industry best practices. Every developer must adhere to these guidelines to maintain code quality, consistency, and scalability.

### 1. MVC Structure

#### Models - Database & Business Logic
- **Models** handle ALL database operations and business logic
- Every query, insert, update, or delete MUST live in model class methods
- Examples: `User.find_by_email()`, `Upload.create()`, `Search.find_similar()`
- Models contain validation logic, data transformations, and business rules
- NO direct database access outside of models

#### Controllers - Thin HTTP Layer Only
- Controllers are "thin" - they ONLY orchestrate HTTP requests
- Responsibilities:
  - Parse and validate request input (via decorators/schemas)
  - Call appropriate model or service methods
  - Serialize and return responses
- Controllers MUST NOT:
  - Contain business logic
  - Make direct database queries
  - Perform complex data manipulations
  - Call ORM methods directly

#### Views/Schemas - Data Transfer Objects
- Define JSON request/response shapes
- Handle serialization/deserialization
- Define validation rules for API inputs
- NO ORM classes should leak into HTTP payloads
- Keep API contracts separate from database models

### 2. Database Operations in Models

```python
# CORRECT - Database operations in model
class Upload(BaseModel):
    @classmethod
    async def find_by_user(cls, user_id: UUID, limit: int = 20) -> List['Upload']:
        """Find all uploads for a specific user"""
        return await db.query(
            "SELECT * FROM uploads WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2",
            user_id, limit
        )
    
    async def update_processing_status(self, status: str, error: str = None):
        """Update the processing status of this upload"""
        self.processing_status = status
        self.processing_error = error
        await self.save()

# INCORRECT - Database operations in controller
@router.get("/uploads")
async def get_uploads(user_id: UUID):
    # NEVER do this in controllers!
    uploads = await db.query("SELECT * FROM uploads WHERE user_id = $1", user_id)
    return uploads
```

### 3. Thin Controllers Pattern

```python
# CORRECT - Thin controller
@router.post("/upload", response_model=UploadResponse)
async def create_upload(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    upload_schema: UploadSchema = Depends()
):
    """Thin controller - only orchestrates the request"""
    # Validate input (handled by FastAPI dependencies)
    # Call model method
    upload = await Upload.create_from_file(
        user_id=user.id,
        file=file,
        metadata=upload_schema.metadata
    )
    # Return serialized response
    return UploadResponse.from_model(upload)

# INCORRECT - Fat controller with business logic
@router.post("/upload")
async def create_upload(file: UploadFile, user: User):
    # NEVER put business logic in controllers!
    if file.size > 100 * 1024 * 1024:
        raise HTTPException(400, "File too large")
    
    file_hash = hashlib.sha256(await file.read()).hexdigest()
    await file.seek(0)
    
    # Direct database access - WRONG!
    existing = await db.query("SELECT id FROM uploads WHERE file_hash = $1", file_hash)
    if existing:
        raise HTTPException(409, "Duplicate file")
    
    # More business logic that belongs in models...
```

### 4. Services Layer (For Complex Workflows)

For operations spanning multiple models or external systems, create dedicated service modules:

```python
# services/processing_service.py
class ProcessingService:
    """Orchestrates complex file processing workflows"""
    
    @staticmethod
    async def process_upload(upload_id: UUID):
        """Complex workflow spanning multiple models and external services"""
        # Get upload from model
        upload = await Upload.find_by_id(upload_id)
        
        # Call AI service
        summary = await GeminiService.analyze_file(upload.gs_uri)
        
        # Generate embedding
        embedding = await EmbeddingService.generate(summary)
        
        # Update via model
        await upload.update_analysis(summary, embedding)
        
        # Create job record via model
        await ProcessingJob.mark_completed(upload_id)

# Controller uses service
@router.post("/process/{upload_id}")
async def trigger_processing(
    upload_id: UUID,
    user: User = Depends(get_current_user)
):
    """Thin controller delegates to service"""
    # Verify ownership via model
    upload = await Upload.find_by_id_and_user(upload_id, user.id)
    if not upload:
        raise HTTPException(404)
    
    # Delegate to service
    await ProcessingService.process_upload(upload_id)
    
    return {"status": "processing"}
```

### 5. Clear Separation of Concerns

#### Models (models/)
- Data persistence and retrieval
- Business rules and validation
- Domain logic
- Database transactions
- Example: `models/upload.py`, `models/user.py`

#### Controllers (routers/)
- HTTP routing
- Request/response handling
- Authentication/authorization checks
- Input validation via schemas
- Example: `routers/upload_router.py`, `routers/search_router.py`

#### Schemas (schemas/)
- Request/response DTOs
- Input validation rules
- Serialization logic
- API documentation
- Example: `schemas/upload_schema.py`, `schemas/search_schema.py`

#### Services (services/)
- Complex business workflows
- External API integrations
- Multi-model operations
- Background job orchestration
- Example: `services/processing_service.py`, `services/ai_service.py`

### 6. File Organization

```
backend/
├── models/              # Domain models with database operations
│   ├── __init__.py
│   ├── base.py         # Base model class
│   ├── upload.py       # Upload model
│   ├── user.py         # User model
│   └── search.py       # Search-related models
├── routers/            # Thin controllers
│   ├── __init__.py
│   ├── upload.py       # Upload endpoints
│   ├── search.py       # Search endpoints
│   └── auth.py         # Auth endpoints
├── schemas/            # Request/response schemas
│   ├── __init__.py
│   ├── upload.py       # Upload DTOs
│   ├── search.py       # Search DTOs
│   └── common.py       # Shared schemas
├── services/           # Business logic services
│   ├── __init__.py
│   ├── processing.py   # File processing workflows
│   ├── ai.py          # AI integration service
│   └── storage.py      # Cloud storage service
└── main.py            # FastAPI app setup
```

### 7. Example Implementation

```python
# models/upload.py
class Upload(BaseModel):
    """Upload model - handles all database operations"""
    
    @classmethod
    async def create(cls, user_id: UUID, file_data: dict) -> 'Upload':
        """Create a new upload record"""
        upload_id = uuid4()
        await db.execute(
            """
            INSERT INTO uploads (id, user_id, filename, file_size, gs_uri)
            VALUES ($1, $2, $3, $4, $5)
            """,
            upload_id, user_id, file_data['filename'], 
            file_data['size'], file_data['gs_uri']
        )
        return cls(id=upload_id, user_id=user_id, **file_data)
    
    async def mark_as_processed(self, summary: str, embedding: List[float]):
        """Update upload with processing results"""
        await db.execute(
            """
            UPDATE uploads 
            SET processing_status = 'completed',
                gemini_summary = $1,
                embedding = $2,
                processing_completed_at = NOW()
            WHERE id = $3
            """,
            summary, embedding, self.id
        )

# schemas/upload.py
class UploadRequest(BaseModel):
    """Request schema for file upload"""
    metadata: Optional[Dict[str, Any]] = None

class UploadResponse(BaseModel):
    """Response schema for file upload"""
    upload_id: UUID
    job_id: UUID
    status: str
    estimated_time: int
    
    @classmethod
    def from_model(cls, upload: Upload, job_id: UUID) -> 'UploadResponse':
        return cls(
            upload_id=upload.id,
            job_id=job_id,
            status='queued',
            estimated_time=30
        )

# routers/upload.py
@router.post("/upload", response_model=UploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    request: UploadRequest = Body(...),
    user: User = Depends(get_current_user)
):
    """Thin controller - just orchestrates"""
    # Call service for complex logic
    upload, job_id = await FileUploadService.handle_upload(
        user_id=user.id,
        file=file,
        metadata=request.metadata
    )
    
    # Return serialized response
    return UploadResponse.from_model(upload, job_id)

# services/file_upload.py
class FileUploadService:
    """Service for handling file upload workflow"""
    
    @staticmethod
    async def handle_upload(user_id: UUID, file: UploadFile, metadata: dict):
        """Complex upload workflow"""
        # Validate file
        await FileValidator.validate(file)
        
        # Upload to storage
        gs_uri = await StorageService.upload(file)
        
        # Create database record via model
        upload = await Upload.create(
            user_id=user_id,
            file_data={
                'filename': file.filename,
                'size': file.size,
                'gs_uri': gs_uri,
                'metadata': metadata
            }
        )
        
        # Queue for processing
        job_id = await ProcessingQueue.enqueue(upload.id)
        
        return upload, job_id
```

### 8. Testing Strategy

Following MVC makes testing straightforward:

```python
# Test models independently
async def test_upload_model():
    upload = await Upload.create(user_id, file_data)
    assert upload.id is not None
    
    await upload.mark_as_processed(summary, embedding)
    assert upload.processing_status == 'completed'

# Test controllers with mocked dependencies
async def test_upload_controller():
    with mock.patch('services.FileUploadService.handle_upload') as mock_service:
        mock_service.return_value = (mock_upload, mock_job_id)
        
        response = await client.post('/upload', files={'file': ...})
        assert response.status_code == 200
        assert response.json()['upload_id'] == str(mock_upload.id)

# Test services with mocked models
async def test_upload_service():
    with mock.patch('models.Upload.create') as mock_create:
        result = await FileUploadService.handle_upload(...)
        mock_create.assert_called_once()
```

### 9. Common Anti-Patterns to Avoid

❌ **DON'T: Mix concerns**
```python
# BAD - Controller doing model's job
@router.get("/search")
async def search(query: str):
    embedding = await openai.embed(query)  # Business logic!
    results = await db.query(...)          # Direct DB access!
    return [process_result(r) for r in results]  # Data transformation!
```

✅ **DO: Separate concerns**
```python
# GOOD - Each layer does its job
@router.get("/search")
async def search(query: str, user: User = Depends(get_current_user)):
    results = await SearchService.search(query, user.id)
    return SearchResponse.from_results(results)
```

❌ **DON'T: Fat models with HTTP concerns**
```python
# BAD - Model knows about HTTP
class Upload:
    def to_json_response(self):
        return JSONResponse(content={...}, status_code=200)
```

✅ **DO: Keep models pure**
```python
# GOOD - Model is just data + business logic
class Upload:
    def to_dict(self) -> dict:
        return {'id': self.id, 'filename': self.filename}
```

### 10. Benefits of This Architecture

1. **Testability**: Each layer can be tested in isolation
2. **Maintainability**: Clear boundaries make changes easier
3. **Scalability**: Easy to split into microservices later
4. **Reusability**: Models and services can be used across different interfaces
5. **Team Collaboration**: Clear responsibilities prevent conflicts
6. **Performance**: Easier to optimize when concerns are separated

### Enforcement

- Code reviews MUST check for MVC compliance
- PRs violating these patterns will be rejected
- Refactor existing code that doesn't follow these patterns
- New features MUST follow this architecture from the start

## API Versioning

### URL Path Versioning Strategy

This project uses URL path versioning for clear, explicit version management:

```python
# main.py
from fastapi import FastAPI
from api.v1 import router as v1_router
from api.v2 import router as v2_router

app = FastAPI(title="Multimodal Search API")

# Mount versioned routers
app.include_router(v1_router, prefix="/api/v1", tags=["v1"])
app.include_router(v2_router, prefix="/api/v2", tags=["v2"])
```

### Project Structure for Versioning

```
backend/
├── api/
│   ├── v1/
│   │   ├── __init__.py
│   │   ├── endpoints/
│   │   │   ├── upload.py
│   │   │   ├── search.py
│   │   │   └── auth.py
│   │   └── schemas/
│   │       └── responses.py
│   └── v2/
│       ├── __init__.py
│       ├── endpoints/
│       └── schemas/
```

### Version Management Rules

1. **Backward Compatibility**: v1 endpoints remain unchanged once released
2. **Deprecation Policy**: 6-month deprecation notice before removing versions
3. **Feature Flags**: Use feature flags for gradual rollout within versions
4. **Documentation**: Each version has separate OpenAPI docs at `/api/v{n}/docs`

## Consistent Response Envelope

### Standard Response Format

All API responses follow this consistent envelope pattern:

```python
# schemas/responses.py
from typing import Optional, Any, List
from pydantic import BaseModel
from datetime import datetime

class ResponseEnvelope(BaseModel):
    """Standard API response envelope"""
    status: str  # "success" or "error"
    data: Optional[Any] = None
    error: Optional[dict] = None
    meta: Optional[dict] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    
class SuccessResponse(ResponseEnvelope):
    status: str = "success"
    
class ErrorResponse(ResponseEnvelope):
    status: str = "error"
    error: dict = Field(..., example={
        "code": "VALIDATION_ERROR",
        "message": "Invalid input data",
        "details": [{"field": "email", "message": "Invalid email format"}]
    })

class PaginatedResponse(SuccessResponse):
    data: List[Any]
    meta: dict = Field(..., example={
        "total": 100,
        "limit": 20,
        "offset": 0,
        "has_more": True
    })
```

### Usage Examples

```python
# Success response
@router.get("/uploads", response_model=SuccessResponse)
async def list_uploads(user: User = Depends(get_current_user)):
    uploads = await Upload.find_by_user(user.id)
    return SuccessResponse(
        data=[upload.dict() for upload in uploads],
        meta={"count": len(uploads)}
    )

# Error response
@app.exception_handler(ValidationError)
async def validation_exception_handler(request: Request, exc: ValidationError):
    return JSONResponse(
        status_code=400,
        content=ErrorResponse(
            error={
                "code": "VALIDATION_ERROR",
                "message": str(exc),
                "details": exc.errors()
            }
        ).dict()
    )
```

## Automated Documentation

### FastAPI with Pydantic Integration

FastAPI automatically generates OpenAPI documentation. Enhance it with:

```python
# main.py
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    title="Multimodal Search API",
    description="AI-powered multimodal file search system",
    version="2.0.0",
    terms_of_service="https://example.com/terms",
    contact={
        "name": "API Support",
        "email": "api@example.com",
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT",
    }
)

# Custom OpenAPI schema
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    
    # Add security schemes
    openapi_schema["components"]["securitySchemes"] = {
        "bearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
        }
    }
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi
```

### Documentation Enhancement

```python
# Enhanced endpoint documentation
@router.post(
    "/upload",
    response_model=SuccessResponse,
    summary="Upload a file for processing",
    description="""
    Upload a file to be processed by AI models.
    
    The file will be:
    1. Validated for format and size
    2. Uploaded to cloud storage
    3. Queued for AI analysis
    4. Made searchable after processing
    """,
    response_description="Upload job details",
    responses={
        200: {"description": "File uploaded successfully"},
        400: {"description": "Invalid file format or size"},
        401: {"description": "Authentication required"},
        413: {"description": "File too large"},
        429: {"description": "Rate limit exceeded"}
    }
)
async def upload_file(
    file: UploadFile = File(
        ...,
        description="File to upload (max 100MB)",
        example="document.pdf"
    ),
    user: User = Depends(get_current_user)
):
    pass
```

### Client Code Generation

```bash
# Generate TypeScript client
openapi-generator-cli generate \
    -i http://localhost:8000/openapi.json \
    -g typescript-axios \
    -o ./generated/typescript-client

# Generate Python client
openapi-generator-cli generate \
    -i http://localhost:8000/openapi.json \
    -g python \
    -o ./generated/python-client
```

## Configuration & Secrets Management

### Pydantic Settings

```python
# config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from typing import Optional

class Settings(BaseSettings):
    """Application settings with validation"""
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="forbid"  # Fail on unknown env vars
    )
    
    # Application
    app_name: str = "Multimodal Search API"
    environment: str  # development, staging, production
    debug: bool = False
    
    # Database
    database_url: str
    database_pool_size: int = 20
    database_max_overflow: int = 40
    
    # Redis
    redis_url: str
    redis_max_connections: int = 50
    
    # External APIs
    openai_api_key: str
    gemini_api_key: str
    
    # Security
    secret_key: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # Cloud Storage
    gcs_bucket: str
    gcs_project_id: Optional[str] = None
    
    # Feature Flags
    enable_video_processing: bool = True
    enable_rate_limiting: bool = True
    
    @validator('environment')
    def validate_environment(cls, v):
        allowed = ['development', 'staging', 'production']
        if v not in allowed:
            raise ValueError(f'environment must be one of {allowed}')
        return v

@lru_cache()
def get_settings() -> Settings:
    """Cached settings instance"""
    return Settings()

# Usage
settings = get_settings()
```

### Secrets Management Best Practices

```python
# secrets_manager.py
import os
from typing import Optional
from google.cloud import secretmanager

class SecretsManager:
    """Manage secrets from various sources"""
    
    def __init__(self):
        self.client = secretmanager.SecretManagerServiceClient()
        self.project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
    
    def get_secret(self, key: str) -> Optional[str]:
        """Get secret with fallback hierarchy"""
        # 1. Try environment variable
        value = os.getenv(key)
        if value:
            return value
        
        # 2. For local testing only - use docker-compose with env_file
        # Never use .env files in production
        
        # 3. Try Google Secret Manager (production)
        if self.project_id:
            try:
                name = f"projects/{self.project_id}/secrets/{key}/versions/latest"
                response = self.client.access_secret_version(request={"name": name})
                return response.payload.data.decode("UTF-8")
            except Exception as e:
                logger.error(f"Failed to get secret {key}: {e}")
        
        return None
```

## Database Migrations

### Alembic Setup and Configuration

```bash
# Initialize Alembic
alembic init migrations

# Create initial migration
alembic revision --autogenerate -m "Initial schema"

# Apply migrations
alembic upgrade head
```

### Alembic Configuration

```python
# alembic.ini
[alembic]
script_location = migrations
prepend_sys_path = .
version_path_separator = os
sqlalchemy.url = postgresql://user:pass@localhost/dbname

# migrations/env.py
from logging.config import fileConfig
from sqlalchemy import pool
from alembic import context
from app.database import Base
from app.config import get_settings

config = context.config
settings = get_settings()

# Override sqlalchemy.url with environment variable
config.set_main_option("sqlalchemy.url", settings.database_url)

target_metadata = Base.metadata

def run_migrations_online():
    """Run migrations in 'online' mode"""
    configuration = config.get_section(config.config_ini_section)
    configuration['sqlalchemy.url'] = settings.database_url
    
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
        )

        with context.begin_transaction():
            context.run_migrations()
```

### Migration Best Practices

```python
# Example migration with rollback support
"""Add user preferences table

Revision ID: 3f146c5f8b24
Revises: 2a3b4c5d6e7f
Create Date: 2024-01-15 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '3f146c5f8b24'
down_revision = '2a3b4c5d6e7f'

def upgrade():
    # Create table
    op.create_table(
        'user_preferences',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('theme', sa.String(20), default='light'),
        sa.Column('notifications_enabled', sa.Boolean, default=True),
        sa.Column('created_at', sa.DateTime, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, server_default=sa.func.now())
    )
    
    # Create indexes
    op.create_index('ix_user_preferences_user_id', 'user_preferences', ['user_id'])
    
    # Add foreign key
    op.create_foreign_key(
        'fk_user_preferences_user_id',
        'user_preferences', 'users',
        ['user_id'], ['id'],
        ondelete='CASCADE'
    )

def downgrade():
    op.drop_table('user_preferences')
```

## Testing Strategy

### Test Structure and Organization

```
tests/
├── unit/                 # Unit tests
│   ├── models/
│   ├── services/
│   └── utils/
├── integration/          # Integration tests
│   ├── api/
│   ├── database/
│   └── external/
├── contract/            # Contract tests
│   └── openapi/
├── e2e/                 # End-to-end tests
├── fixtures/            # Test data
├── conftest.py          # Shared fixtures
└── factories.py         # Test data factories
```

### Unit Tests for Models and Services

```python
# tests/unit/models/test_upload_model.py
import pytest
from unittest.mock import Mock, patch
from models.upload import Upload

class TestUploadModel:
    @pytest.fixture
    def mock_db(self):
        """Mock database connection"""
        with patch('models.upload.db') as mock:
            yield mock
    
    @pytest.mark.asyncio
    async def test_create_upload(self, mock_db):
        """Test upload creation"""
        # Arrange
        mock_db.fetchrow.return_value = {
            'id': 'test-id',
            'filename': 'test.pdf',
            'status': 'pending'
        }
        
        # Act
        upload = await Upload.create(
            user_id='user-123',
            filename='test.pdf',
            file_size=1024
        )
        
        # Assert
        assert upload.id == 'test-id'
        assert upload.filename == 'test.pdf'
        mock_db.fetchrow.assert_called_once()
```

### Integration Tests for Controllers

```python
# tests/integration/api/test_upload_api.py
import pytest
from httpx import AsyncClient
from fastapi import status

class TestUploadAPI:
    @pytest.mark.asyncio
    async def test_upload_file_success(
        self,
        test_client: AsyncClient,
        authenticated_user,
        test_file
    ):
        """Test successful file upload"""
        response = await test_client.post(
            "/api/v1/upload",
            files={"file": test_file},
            headers=authenticated_user.headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["status"] == "success"
        assert "job_id" in data["data"]
    
    @pytest.mark.asyncio
    async def test_upload_file_unauthenticated(
        self,
        test_client: AsyncClient,
        test_file
    ):
        """Test upload without authentication"""
        response = await test_client.post(
            "/api/v1/upload",
            files={"file": test_file}
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
```

### Contract Tests Against OpenAPI Spec

```python
# tests/contract/test_openapi_contract.py
import pytest
from openapi_spec_validator import validate_spec
from openapi_schema_validator import validate
import json

class TestOpenAPIContract:
    @pytest.fixture
    def openapi_spec(self, test_client):
        """Get OpenAPI specification"""
        response = test_client.get("/openapi.json")
        return response.json()
    
    def test_openapi_spec_valid(self, openapi_spec):
        """Test OpenAPI spec is valid"""
        validate_spec(openapi_spec)
    
    @pytest.mark.asyncio
    async def test_response_matches_contract(
        self,
        test_client,
        openapi_spec,
        authenticated_user
    ):
        """Test actual responses match OpenAPI contract"""
        # Make request
        response = await test_client.get(
            "/api/v1/uploads",
            headers=authenticated_user.headers
        )
        
        # Validate against schema
        schema = openapi_spec["paths"]["/api/v1/uploads"]["get"]["responses"]["200"]["content"]["application/json"]["schema"]
        validate(response.json(), schema)
```

### Test Configuration

```python
# conftest.py
import pytest
import asyncio
from typing import AsyncGenerator
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from app.main import app
from app.database import Base

@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="function")
async def test_db():
    """Create test database"""
    engine = create_async_engine("postgresql://test@localhost/test_db")
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with AsyncSession(engine) as session:
        yield session
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
async def test_client() -> AsyncGenerator[AsyncClient, None]:
    """Create test client"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
```

## CI/CD & Containerization

### Dockerfile

```dockerfile
# Multi-stage build for optimization
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Create non-root user
RUN useradd -m -u 1000 appuser

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run application with Gunicorn in production
EXPOSE 8000
CMD ["gunicorn", "main:app", \
     "--workers", "4", \
     "--worker-class", "uvicorn.workers.UvicornWorker", \
     "--bind", "0.0.0.0:8000", \
     "--timeout", "300", \
     "--graceful-timeout", "60", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--preload"]
```

### GitHub Actions CI Pipeline

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  PYTHON_VERSION: "3.11"
  POETRY_VERSION: "1.7.0"

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Install dependencies
        run: |
          pip install ruff mypy
      
      - name: Run linting
        run: |
          ruff check .
          mypy backend/

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
      
      - name: Install Poetry
        uses: snok/install-poetry@v1
        with:
          version: ${{ env.POETRY_VERSION }}
      
      - name: Install dependencies
        run: poetry install
      
      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost/test_db
          REDIS_URL: redis://localhost:6379
        run: |
          poetry run pytest -v --cov=backend --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run security checks
        run: |
          pip install safety bandit
          safety check
          bandit -r backend/

  build:
    needs: [lint, test, security]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Build Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: false
          tags: multimodal-search:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### CD Pipeline for Production

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1
      
      - name: Configure Docker for GCR
        run: gcloud auth configure-docker
      
      - name: Build and push image
        run: |
          docker build -t gcr.io/${{ secrets.GCP_PROJECT }}/multimodal-search:${{ github.ref_name }} .
          docker push gcr.io/${{ secrets.GCP_PROJECT }}/multimodal-search:${{ github.ref_name }}
      
      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy multimodal-search \
            --image gcr.io/${{ secrets.GCP_PROJECT }}/multimodal-search:${{ github.ref_name }} \
            --platform managed \
            --region us-central1 \
            --allow-unauthenticated
      
      - name: Run smoke tests
        run: |
          SERVICE_URL=$(gcloud run services describe multimodal-search --platform managed --region us-central1 --format 'value(status.url)')
          curl -f $SERVICE_URL/health || exit 1
```

## Security & Monitoring

### Security Implementation

```python
# security/middleware.py
from fastapi import Request, HTTPException
from fastapi.security import HTTPBearer
from starlette.middleware.base import BaseHTTPMiddleware
import time
import hashlib
from collections import defaultdict

class SecurityMiddleware(BaseHTTPMiddleware):
    """Comprehensive security middleware"""
    
    def __init__(self, app, settings):
        super().__init__(app)
        self.settings = settings
        self.rate_limiter = RateLimiter()
    
    async def dispatch(self, request: Request, call_next):
        # 1. HTTPS enforcement
        if self.settings.environment == "production":
            if request.headers.get("X-Forwarded-Proto") != "https":
                raise HTTPException(status_code=400, detail="HTTPS required")
        
        # 2. Security headers
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Content-Security-Policy"] = "default-src 'self'"
        
        return response

class RateLimiter:
    """Token bucket rate limiter"""
    
    def __init__(self):
        self.buckets = defaultdict(lambda: {"tokens": 100, "last_refill": time.time()})
    
    async def check_rate_limit(self, key: str, cost: int = 1) -> bool:
        bucket = self.buckets[key]
        now = time.time()
        
        # Refill tokens
        time_passed = now - bucket["last_refill"]
        bucket["tokens"] = min(100, bucket["tokens"] + time_passed * 10)  # 10 tokens/second
        bucket["last_refill"] = now
        
        # Check if enough tokens
        if bucket["tokens"] >= cost:
            bucket["tokens"] -= cost
            return True
        
        return False
```

### Input Validation

```python
# security/validators.py
from pydantic import validator, constr, conint
import re
from typing import Any

class SecureValidators:
    """OWASP-compliant input validators"""
    
    @staticmethod
    def sanitize_string(v: str) -> str:
        """Remove potentially dangerous characters"""
        # Remove null bytes
        v = v.replace('\x00', '')
        # Remove control characters
        v = re.sub(r'[\x01-\x1F\x7F]', '', v)
        return v.strip()
    
    @staticmethod
    def validate_filename(filename: str) -> str:
        """Validate and sanitize filename"""
        # Remove path traversal attempts
        filename = filename.replace('..', '').replace('/', '').replace('\\', '')
        
        # Whitelist allowed characters
        if not re.match(r'^[a-zA-Z0-9_\-\.]+$', filename):
            raise ValueError("Invalid filename")
        
        # Check extension
        allowed_extensions = {'.jpg', '.png', '.pdf', '.mp4', '.mp3', '.doc', '.docx'}
        if not any(filename.lower().endswith(ext) for ext in allowed_extensions):
            raise ValueError("File type not allowed")
        
        return filename

# Usage in Pydantic models
class SecureFileUpload(BaseModel):
    filename: constr(min_length=1, max_length=255)
    file_size: conint(gt=0, le=104857600)  # Max 100MB
    
    @validator('filename')
    def validate_filename(cls, v):
        return SecureValidators.validate_filename(v)
```

### Structured Logging with Correlation IDs

```python
# logging_config.py
import logging
import json
from datetime import datetime
from contextvars import ContextVar
from pythonjsonlogger import jsonlogger

# Context variable for correlation ID
correlation_id: ContextVar[str] = ContextVar('correlation_id', default='')

class CorrelationIdFilter(logging.Filter):
    """Add correlation ID to log records"""
    
    def filter(self, record):
        record.correlation_id = correlation_id.get()
        return True

class CustomJsonFormatter(jsonlogger.JsonFormatter):
    """Custom JSON formatter with additional fields"""
    
    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)
        log_record['timestamp'] = datetime.utcnow().isoformat()
        log_record['service'] = 'multimodal-search'
        log_record['environment'] = settings.environment
        log_record['correlation_id'] = getattr(record, 'correlation_id', '')

# Configure logging
def setup_logging():
    handler = logging.StreamHandler()
    handler.setFormatter(CustomJsonFormatter())
    handler.addFilter(CorrelationIdFilter())
    
    logger = logging.getLogger()
    logger.handlers = [handler]
    logger.setLevel(logging.INFO)
    
    # Middleware to set correlation ID
    @app.middleware("http")
    async def correlation_id_middleware(request: Request, call_next):
        request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
        correlation_id.set(request_id)
        
        response = await call_next(request)
        response.headers['X-Request-ID'] = request_id
        
        return response
```

### Error Tracking with Sentry

```python
# monitoring/sentry_config.py
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
from sentry_sdk.integrations.redis import RedisIntegration

def setup_sentry(settings):
    """Configure Sentry error tracking"""
    if settings.environment in ["staging", "production"]:
        sentry_sdk.init(
            dsn=settings.sentry_dsn,
            environment=settings.environment,
            integrations=[
                FastApiIntegration(transaction_style='endpoint'),
                SqlalchemyIntegration(),
                RedisIntegration(),
            ],
            traces_sample_rate=0.1,  # 10% of transactions
            profiles_sample_rate=0.1,  # 10% profiling
            before_send=before_send_filter,
            attach_stacktrace=True,
            send_default_pii=False,  # Don't send PII
        )

def before_send_filter(event, hint):
    """Filter sensitive data before sending to Sentry"""
    # Remove sensitive headers
    if 'request' in event and 'headers' in event['request']:
        sensitive_headers = ['authorization', 'x-api-key', 'cookie']
        for header in sensitive_headers:
            event['request']['headers'].pop(header, None)
    
    return event
```

### Monitoring Setup

```python
# monitoring/metrics.py
from prometheus_client import Counter, Histogram, Gauge, Info
from prometheus_client import generate_latest
from fastapi import Response

# Define metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

active_uploads = Gauge(
    'active_uploads',
    'Number of active file uploads'
)

app_info = Info('app_info', 'Application information')
app_info.info({
    'version': settings.app_version,
    'environment': settings.environment
})

# Metrics endpoint
@app.get("/metrics", include_in_schema=False)
async def metrics():
    return Response(content=generate_latest(), media_type="text/plain")

# Middleware to collect metrics
@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    http_requests_total.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    http_request_duration.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    return response
```

## Performance & Scaling

### Redis Caching Strategy

```python
# cache/redis_cache.py
from typing import Optional, Any, Callable
import redis.asyncio as redis
import json
import hashlib
from functools import wraps

class RedisCache:
    """Redis caching with best practices"""
    
    def __init__(self, redis_url: str):
        self.redis = redis.from_url(
            redis_url,
            encoding="utf-8",
            decode_responses=True,
            max_connections=50,
            health_check_interval=30
        )
    
    async def get_or_set(
        self,
        key: str,
        factory: Callable,
        ttl: int = 300,
        namespace: str = "cache"
    ) -> Any:
        """Cache-aside pattern implementation"""
        full_key = f"{namespace}:{key}"
        
        # Try to get from cache
        cached = await self.redis.get(full_key)
        if cached:
            return json.loads(cached)
        
        # Generate value
        value = await factory()
        
        # Store in cache with TTL
        await self.redis.setex(
            full_key,
            ttl,
            json.dumps(value, default=str)
        )
        
        return value
    
    def cached(
        self,
        ttl: int = 300,
        namespace: str = "cache",
        key_builder: Optional[Callable] = None
    ):
        """Decorator for caching function results"""
        def decorator(func):
            @wraps(func)
            async def wrapper(*args, **kwargs):
                # Build cache key
                if key_builder:
                    cache_key = key_builder(*args, **kwargs)
                else:
                    # Default key building
                    key_parts = [func.__name__]
                    key_parts.extend(str(arg) for arg in args)
                    key_parts.extend(f"{k}:{v}" for k, v in sorted(kwargs.items()))
                    cache_key = hashlib.md5(":".join(key_parts).encode()).hexdigest()
                
                return await self.get_or_set(
                    cache_key,
                    lambda: func(*args, **kwargs),
                    ttl,
                    namespace
                )
            
            # Add cache management
            wrapper.invalidate = lambda *args, **kwargs: self.invalidate(
                namespace, key_builder(*args, **kwargs) if key_builder else None
            )
            
            return wrapper
        return decorator
    
    async def invalidate(self, namespace: str, key: Optional[str] = None):
        """Invalidate cache entries"""
        if key:
            await self.redis.delete(f"{namespace}:{key}")
        else:
            # Invalidate entire namespace
            async for key in self.redis.scan_iter(f"{namespace}:*"):
                await self.redis.delete(key)

# Usage
cache = RedisCache(settings.redis_url)

@cache.cached(ttl=600, namespace="search")
async def search_files(query: str, user_id: str):
    # Expensive search operation
    results = await perform_search(query, user_id)
    return results
```

### Pagination Implementation

```python
# utils/pagination.py
from typing import Generic, TypeVar, List
from pydantic import BaseModel, Field
from fastapi import Query

T = TypeVar('T')

class PaginationParams(BaseModel):
    """Pagination parameters"""
    page: int = Field(1, ge=1, description="Page number")
    size: int = Field(20, ge=1, le=100, description="Page size")
    
    @property
    def offset(self) -> int:
        return (self.page - 1) * self.size

class PaginatedResponse(BaseModel, Generic[T]):
    """Paginated response wrapper"""
    items: List[T]
    total: int
    page: int
    size: int
    pages: int
    has_next: bool
    has_prev: bool
    
    @classmethod
    def create(
        cls,
        items: List[T],
        total: int,
        params: PaginationParams
    ) -> 'PaginatedResponse[T]':
        pages = (total + params.size - 1) // params.size
        return cls(
            items=items,
            total=total,
            page=params.page,
            size=params.size,
            pages=pages,
            has_next=params.page < pages,
            has_prev=params.page > 1
        )

# Usage in endpoint
@router.get("/uploads", response_model=PaginatedResponse[UploadSchema])
async def list_uploads(
    pagination: PaginationParams = Depends(),
    user: User = Depends(get_current_user)
):
    items = await Upload.find_by_user(
        user.id,
        limit=pagination.size,
        offset=pagination.offset
    )
    total = await Upload.count_by_user(user.id)
    
    return PaginatedResponse.create(items, total, pagination)
```

### Rate Limiting

```python
# middleware/rate_limit.py
from fastapi import Request, HTTPException
from typing import Dict, Tuple
import time
import asyncio

class RateLimitMiddleware:
    """Token bucket rate limiting"""
    
    def __init__(
        self,
        rate: int = 100,  # requests per minute
        burst: int = 20   # burst capacity
    ):
        self.rate = rate / 60  # Convert to per second
        self.burst = burst
        self.buckets: Dict[str, Tuple[float, float]] = {}
        self.lock = asyncio.Lock()
    
    async def check_rate_limit(self, key: str) -> bool:
        async with self.lock:
            now = time.time()
            
            if key not in self.buckets:
                self.buckets[key] = (self.burst, now)
                return True
            
            tokens, last_update = self.buckets[key]
            
            # Calculate new tokens
            elapsed = now - last_update
            tokens = min(self.burst, tokens + elapsed * self.rate)
            
            if tokens < 1:
                return False
            
            # Consume token
            self.buckets[key] = (tokens - 1, now)
            return True
    
    async def __call__(self, request: Request, call_next):
        # Get rate limit key (IP or user ID)
        key = request.client.host
        if hasattr(request.state, "user"):
            key = f"user:{request.state.user.id}"
        
        # Check rate limit
        if not await self.check_rate_limit(key):
            raise HTTPException(
                status_code=429,
                detail="Rate limit exceeded",
                headers={"Retry-After": "60"}
            )
        
        response = await call_next(request)
        return response

# Apply to specific routes
from fastapi import APIRouter
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/upload")
@limiter.limit("5/minute")
async def upload_file(request: Request, file: UploadFile):
    pass
```

### Nginx Configuration

```nginx
# nginx.conf
upstream backend {
    least_conn;
    server backend1:8000 max_fails=3 fail_timeout=30s;
    server backend2:8000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80;
    server_name api.example.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    # SSL configuration
    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;
    
    # Proxy settings
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        
        # Connection reuse
        proxy_set_header Connection "";
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://backend;
        access_log off;
    }
    
    # Static files with caching
    location /static/ {
        alias /var/www/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## Additional Best Practices

### Feature Flags

```python
# feature_flags.py
from typing import Dict, Any
from pydantic import BaseModel
import httpx
from functools import lru_cache

class FeatureFlag(BaseModel):
    """Feature flag configuration"""
    name: str
    enabled: bool
    rollout_percentage: int = 100
    user_whitelist: List[str] = []
    metadata: Dict[str, Any] = {}

class FeatureFlagService:
    """Feature flag management"""
    
    def __init__(self, provider: str = "local"):
        self.provider = provider
        self._flags: Dict[str, FeatureFlag] = {}
        self._load_flags()
    
    def _load_flags(self):
        """Load feature flags from provider"""
        if self.provider == "local":
            # Load from configuration
            self._flags = {
                "new_upload_flow": FeatureFlag(
                    name="new_upload_flow",
                    enabled=True,
                    rollout_percentage=50
                ),
                "video_processing_v2": FeatureFlag(
                    name="video_processing_v2",
                    enabled=False
                )
            }
        elif self.provider == "launchdarkly":
            # Load from LaunchDarkly
            pass
    
    def is_enabled(
        self,
        flag_name: str,
        user_id: Optional[str] = None
    ) -> bool:
        """Check if feature is enabled for user"""
        flag = self._flags.get(flag_name)
        if not flag or not flag.enabled:
            return False
        
        # Check whitelist
        if user_id and user_id in flag.user_whitelist:
            return True
        
        # Check rollout percentage
        if flag.rollout_percentage < 100:
            # Simple hash-based rollout
            user_hash = hash(user_id or "anonymous") % 100
            return user_hash < flag.rollout_percentage
        
        return True

# Usage
feature_flags = FeatureFlagService()

@router.post("/upload")
async def upload_file(file: UploadFile, user: User = Depends(get_current_user)):
    if feature_flags.is_enabled("new_upload_flow", user.id):
        return await new_upload_handler(file, user)
    else:
        return await legacy_upload_handler(file, user)
```

### OAuth/OIDC Integration

```python
# auth/oauth.py
from authlib.integrations.starlette_client import OAuth
from fastapi import Request, HTTPException
from jose import jwt, JWTError

oauth = OAuth()

# Configure OAuth providers
oauth.register(
    name='google',
    client_id=settings.google_client_id,
    client_secret=settings.google_client_secret,
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
    client_kwargs={'scope': 'openid email profile'}
)

oauth.register(
    name='github',
    client_id=settings.github_client_id,
    client_secret=settings.github_client_secret,
    authorize_url='https://github.com/login/oauth/authorize',
    access_token_url='https://github.com/login/oauth/access_token',
    client_kwargs={'scope': 'user:email'}
)

# OAuth endpoints
@router.get("/auth/{provider}")
async def oauth_login(provider: str, request: Request):
    """Initiate OAuth flow"""
    redirect_uri = request.url_for('oauth_callback', provider=provider)
    return await oauth.create_client(provider).authorize_redirect(request, redirect_uri)

@router.get("/auth/{provider}/callback")
async def oauth_callback(provider: str, request: Request):
    """Handle OAuth callback"""
    client = oauth.create_client(provider)
    token = await client.authorize_access_token(request)
    
    # Get user info
    user_info = token.get('userinfo')
    if not user_info:
        user_info = await client.userinfo(token=token)
    
    # Create or update user
    user = await User.find_or_create_oauth(
        provider=provider,
        provider_id=user_info['sub'],
        email=user_info['email'],
        name=user_info.get('name')
    )
    
    # Generate JWT
    access_token = create_access_token(user.id)
    
    return {"access_token": access_token, "token_type": "bearer"}
```

### Infrastructure as Code

```hcl
# terraform/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  default = "us-central1"
}

# Cloud Run Service
resource "google_cloud_run_service" "api" {
  name     = "multimodal-search-api"
  location = var.region
  
  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/multimodal-search:latest"
        
        resources {
          limits = {
            cpu    = "2"
            memory = "4Gi"
          }
        }
        
        env {
          name = "DATABASE_URL"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.db_url.secret_id
              key  = "latest"
            }
          }
        }
      }
      
      service_account_name = google_service_account.api.email
    }
    
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = "1"
        "autoscaling.knative.dev/maxScale"      = "100"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.main.connection_name
      }
    }
  }
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "multimodal-search-db"
  database_version = "POSTGRES_16"
  region           = var.region
  
  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.id
    }
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
    }
    
    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }
}

# Redis Instance
resource "google_redis_instance" "cache" {
  name           = "multimodal-search-cache"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region
  
  redis_configs = {
    "maxmemory-policy" = "allkeys-lru"
  }
}

# Load Balancer
resource "google_compute_backend_service" "api" {
  name        = "multimodal-search-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30
  
  backend {
    group = google_compute_network_endpoint_group.api.id
  }
  
  health_checks = [google_compute_health_check.api.id]
  
  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    client_ttl                   = 7200
    max_ttl                      = 86400
    negative_caching             = true
    serve_while_stale            = 86400
    signed_url_cache_max_age_sec = 7200
  }
}

# Monitoring Dashboard
resource "google_monitoring_dashboard" "api" {
  dashboard_json = jsonencode({
    displayName = "Multimodal Search API"
    widgets = [
      {
        title = "Request Rate"
        xyChart = {
          dataSets = [{
            timeSeriesQuery = {
              timeSeriesFilter = {
                filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\""
              }
            }
          }]
        }
      }
    ]
  })
}
```

## Production Authentication Architecture

### Why Firebase Auth (Not Self-Managed JWT)

**Production Requirements Met by Firebase**:
1. **Security**: SOC 2, ISO 27001, GDPR compliant out-of-box
2. **Scalability**: Handles millions of concurrent users
3. **Availability**: 99.95% SLA
4. **Features**: MFA, password policies, brute force protection built-in
5. **Zero Maintenance**: No security patches, key rotation, or token management

**What Self-Managed JWT Would Require**:
- Key rotation infrastructure
- Token revocation database
- Refresh token management
- Rate limiting on auth endpoints  
- Security audit compliance
- 24/7 monitoring for auth attacks

### Production Auth Implementation

```python
# auth/firebase_auth.py
from firebase_admin import auth, credentials
from fastapi import Depends, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# Initialize once at startup
cred = credentials.Certificate({
    "type": "service_account",
    "project_id": os.getenv("GCP_PROJECT_ID"),
    # ... loaded from Secret Manager
})
firebase_admin.initialize_app(cred)

security = HTTPBearer()

async def verify_token(
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> dict:
    """Production-grade token verification"""
    try:
        # Firebase handles all security concerns
        decoded_token = auth.verify_id_token(
            credentials.credentials,
            check_revoked=True  # Important for production
        )
        return decoded_token
    except auth.RevokedIdTokenError:
        raise HTTPException(401, "Token has been revoked")
    except auth.ExpiredIdTokenError:
        raise HTTPException(401, "Token has expired")
    except Exception:
        raise HTTPException(401, "Invalid authentication credentials")

async def get_current_user(
    token: dict = Depends(verify_token)
) -> User:
    """Get user with production checks"""
    # Get internal user record
    user = await User.find_by_firebase_uid(token["uid"])
    
    if not user:
        # Auto-create user on first login
        user = await User.create(
            firebase_uid=token["uid"],
            email=token.get("email"),
            email_verified=token.get("email_verified", False)
        )
    
    # Production checks
    if user.is_suspended:
        raise HTTPException(403, "Account suspended")
    
    if not user.email_verified and settings.require_email_verification:
        raise HTTPException(403, "Email verification required")
    
    # Update last activity
    await user.update_last_activity()
    
    return user
```

## Production Server Architecture

### Why Gunicorn + Uvicorn Workers

**Production Requirements**:
1. **Process Management**: Gunicorn provides robust process management
2. **Worker Recycling**: Prevents memory leaks with max_requests
3. **Graceful Reloads**: Zero-downtime deployments
4. **Performance**: Uvicorn workers maintain async performance

**Production Configuration**:
```python
# gunicorn.conf.py
import multiprocessing

# Workers
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "uvicorn.workers.UvicornWorker"

# Timeouts
timeout = 300
graceful_timeout = 60
keepalive = 5

# Recycling
max_requests = 1000
max_requests_jitter = 50

# Logging
accesslog = "-"
errorlog = "-"
loglevel = "info"

# Preloading
preload_app = True

# Server mechanics
daemon = False
pidfile = None
worker_tmp_dir = "/dev/shm"
```

## Summary

This comprehensive backend architecture guide provides:

1. **Clear MVC separation** with models handling all database operations
2. **API versioning** using URL path strategy
3. **Consistent response envelopes** for all API responses
4. **Automated documentation** with FastAPI and OpenAPI
5. **Robust configuration management** using Pydantic Settings
6. **Database migrations** with Alembic
7. **Comprehensive testing strategy** including unit, integration, and contract tests
8. **CI/CD pipelines** with Docker and GitHub Actions
9. **Security best practices** including HTTPS, input validation, and monitoring
10. **Performance optimization** with Redis caching and proper scaling
11. **Feature flags** for safe rollouts
12. **OAuth/OIDC** integration examples
13. **Infrastructure as Code** with Terraform

These guidelines ensure a scalable, maintainable, and secure backend that can be easily understood and extended by any development team.

## Notes for Claude Code

- Always follow the MVC architecture guidelines when generating code
- Use the commands in commands.md for common development tasks
- Refer to workflows.md for step-by-step implementation guides
- Check patterns.md for code templates and boilerplate
- Consult errors.md when debugging common issues
- Run tests before suggesting any code changes
- Always use type hints in Python code
- Follow PEP 8 style guidelines
- Write comprehensive docstrings for all functions and classes