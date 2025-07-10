# Multimodal Search System - Claude Code Context

This is the main context file for the Multimodal Search System project. It provides comprehensive guidance for development, architecture, and best practices.

## Quick Start

1. **Local Development**:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # or `venv\Scripts\activate` on Windows
   pip install -r requirements.txt
   python -m uvicorn main:app --reload
   ```

2. **Database Setup**:
   ```bash
   # Create database and extensions
   psql -U postgres -c "CREATE DATABASE multimodal_search;"
   psql -U postgres -d multimodal_search -f schema.sql
   ```

3. **Environment Variables**: Copy `.env.example` to `.env` and fill in your API keys

## Project Overview

A multimodal AI-powered search system that processes images, videos, audio files, and documents. Users upload files which are analyzed by Gemini Pro to generate summaries, then embedded using OpenAI's text-embedding-3-small for semantic search via pgvector.

## Key Dependencies

```txt
# Core Framework
fastapi==0.115.0
uvicorn[standard]==0.32.0
python-multipart==0.0.12

# Database
asyncpg==0.30.0
pgvector==0.3.6
sqlalchemy==2.0.35

# AI/ML
google-generativeai==0.8.3
openai==1.54.0
pillow==11.0.0
opencv-python==4.10.0

# Cloud Services
google-cloud-storage==2.18.2
firebase-admin==6.6.0
redis==5.2.0

# Utilities
python-dotenv==1.0.1
pydantic==2.9.2
pydantic-settings==2.6.1

# Development
pytest==8.3.3
pytest-asyncio==0.24.0
ruff==0.8.0
mypy==1.13.0
```

## Architecture Decisions (FINAL)

### Core Technology Stack
```yaml
Backend: Python 3.11 + FastAPI
Database: Cloud SQL PostgreSQL 16 + pgvector
Cache/Queue: Redis (Cloud Run)
Storage: Google Cloud Storage
AI Models: 
  - Gemini Pro 1.5 (multimodal analysis)
  - OpenAI text-embedding-3-small (1536 dimensions)
Auth: Firebase JWT
Frontend: Vanilla HTML/CSS/JS
Infrastructure: Terraform + Cloud Run
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

## Development Environment Setup

### Prerequisites
- Python 3.11+
- PostgreSQL 16 with pgvector extension
- Redis 7.0+
- Google Cloud SDK
- Node.js 20+ (for frontend development)

### Initial Setup Steps

1. **Clone Repository**:
   ```bash
   git clone <repository-url>
   cd multimodal-search
   ```

2. **Backend Setup**:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```

3. **Database Setup**:
   ```bash
   # Install pgvector extension
   sudo apt-get install postgresql-16-pgvector
   
   # Create database
   createdb multimodal_search
   
   # Run migrations
   psql -d multimodal_search -f migrations/001_initial_schema.sql
   ```

4. **Configure Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys and configuration
   ```

5. **Verify Setup**:
   ```bash
   # Run tests
   pytest
   
   # Start development server
   python -m uvicorn main:app --reload --port 8000
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

## Backend Architecture Guidelines (MVC Pattern)

### Core Principles

This project follows strict MVC (Model-View-Controller) separation with thin controllers. Every developer must adhere to these patterns to maintain code quality and consistency.

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