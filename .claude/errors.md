# Common Errors and Solutions

Comprehensive guide to debugging common issues in the Multimodal Search System.

## Table of Contents
1. [API Errors](#api-errors)
2. [Database Errors](#database-errors)
3. [File Processing Errors](#file-processing-errors)
4. [External Service Errors](#external-service-errors)
5. [Authentication Errors](#authentication-errors)
6. [Performance Issues](#performance-issues)
7. [Development Environment Errors](#development-environment-errors)
8. [Production Deployment Errors](#production-deployment-errors)

## API Errors

### 1. CORS Error - "Access to fetch at 'http://localhost:8000' from origin 'http://localhost:3000' has been blocked"

**Cause**: CORS not properly configured in FastAPI

**Solution**:
```python
# In main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://yourfrontend.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 2. 422 Unprocessable Entity - Request validation failed

**Cause**: Request body doesn't match expected schema

**Diagnosis**:
```bash
# Check the error details in response
{
    "detail": [
        {
            "loc": ["body", "name"],
            "msg": "field required",
            "type": "value_error.missing"
        }
    ]
}
```

**Solution**:
- Ensure all required fields are provided
- Check field types match schema
- Verify date/time formats (ISO 8601)
- Check array/object structures

### 3. 413 Request Entity Too Large

**Cause**: File upload exceeds size limit

**Solution**:
```python
# Increase limit in main.py
app = FastAPI()
app.add_middleware(
    ContentSizeLimitMiddleware,
    max_content_size=104857600  # 100MB
)

# Or in nginx config
client_max_body_size 100M;
```

### 4. 504 Gateway Timeout

**Cause**: Long-running request exceeds timeout

**Solution**:
1. Implement async processing:
```python
# Instead of synchronous processing
@router.post("/process")
async def process_sync(file: UploadFile):
    result = await long_running_task(file)  # This times out
    return result

# Use async with job queue
@router.post("/process")
async def process_async(file: UploadFile):
    job_id = await queue_job(file)
    return {"job_id": job_id, "status": "queued"}
```

2. Increase timeouts:
```yaml
# Cloud Run
spec:
  template:
    spec:
      timeoutSeconds: 300
```

## Database Errors

### 1. Connection Pool Exhausted

**Error**: `asyncpg.exceptions.TooManyConnectionsError: too many connections for role`

**Cause**: Connection pool size too small or connections not being released

**Solution**:
```python
# Increase pool size
pool = await asyncpg.create_pool(
    DATABASE_URL,
    min_size=10,
    max_size=50,  # Increase this
    max_queries=50000,
    max_inactive_connection_lifetime=300
)

# Ensure connections are released
async def get_user(user_id: UUID):
    async with db.acquire() as conn:  # Use context manager
        return await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
    # Connection automatically released
```

### 2. pgvector Extension Not Found

**Error**: `function uploads.embedding <=> unknown does not exist`

**Cause**: pgvector extension not installed

**Solution**:
```bash
# Install extension
sudo apt-get install postgresql-16-pgvector

# Enable in database
psql -d multimodal_search -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Verify installation
psql -d multimodal_search -c "\dx"
```

### 3. Index Scan Too Slow

**Symptoms**: Vector similarity search takes > 1 second

**Diagnosis**:
```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM uploads 
WHERE embedding <=> '[...]'::vector < 0.5 
ORDER BY embedding <=> '[...]'::vector 
LIMIT 20;
```

**Solution**:
```sql
-- Recreate index with better parameters
DROP INDEX IF EXISTS idx_uploads_embedding;

-- For < 1M vectors
CREATE INDEX idx_uploads_embedding ON uploads 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- For > 1M vectors
CREATE INDEX idx_uploads_embedding ON uploads 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 1000);

-- Analyze table after index creation
ANALYZE uploads;
```

### 4. Deadlock Detected

**Error**: `deadlock detected while updating uploads table`

**Cause**: Concurrent transactions updating same rows in different order

**Solution**:
```python
# Use consistent ordering
async def update_batch(upload_ids: List[UUID]):
    # Sort IDs to prevent deadlock
    upload_ids = sorted(upload_ids)
    
    async with db.transaction():
        for upload_id in upload_ids:
            await db.execute(
                "UPDATE uploads SET status = $1 WHERE id = $2",
                'processed', upload_id
            )

# Or use advisory locks
async def safe_update(upload_id: UUID):
    async with db.acquire() as conn:
        # Acquire advisory lock
        await conn.execute("SELECT pg_advisory_lock($1)", hash(str(upload_id)))
        try:
            await conn.execute("UPDATE uploads SET ...", upload_id)
        finally:
            await conn.execute("SELECT pg_advisory_unlock($1)", hash(str(upload_id)))
```

## File Processing Errors

### 1. Gemini API Token Limit Exceeded

**Error**: `Token limit exceeded for model gemini-pro`

**Cause**: File content too large for Gemini Pro

**Solution**:
```python
# Implement content truncation
def prepare_for_gemini(content: str, max_tokens: int = 30000) -> str:
    # Rough estimation: 1 token ≈ 4 characters
    max_chars = max_tokens * 4
    
    if len(content) > max_chars:
        # Take beginning and end for context
        half = max_chars // 2
        return content[:half] + "\n...[truncated]...\n" + content[-half:]
    
    return content

# Or process in chunks
async def process_large_document(content: str):
    chunks = [content[i:i+20000] for i in range(0, len(content), 20000)]
    summaries = []
    
    for chunk in chunks:
        summary = await gemini.analyze(chunk)
        summaries.append(summary)
    
    # Combine summaries
    final_summary = await gemini.summarize(summaries)
    return final_summary
```

### 2. OpenCV Import Error

**Error**: `ImportError: libGL.so.1: cannot open shared object file`

**Cause**: Missing system dependencies for OpenCV

**Solution**:
```dockerfile
# In Dockerfile
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libglib2.0-0

# Or use headless OpenCV
RUN pip install opencv-python-headless
```

### 3. Memory Error During Image Processing

**Error**: `MemoryError: Unable to allocate array`

**Cause**: Loading large images into memory

**Solution**:
```python
import cv2
from PIL import Image

def process_large_image(image_path: str):
    # Don't load full image
    img = Image.open(image_path)
    
    # Check size first
    if img.size[0] * img.size[1] > 100_000_000:  # 100MP
        # Resize before processing
        max_size = (4000, 4000)
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
    
    # Process in chunks if needed
    return process_image_chunks(img)

# Or use streaming approach
def resize_image_streaming(input_path: str, output_path: str, max_size: int = 1920):
    # Use imagemagick via subprocess for large images
    subprocess.run([
        'convert',
        input_path,
        '-resize', f'{max_size}x{max_size}>',
        '-quality', '85',
        output_path
    ])
```

### 4. Corrupt File Upload

**Error**: `UnidentifiedImageError: cannot identify image file`

**Cause**: Incomplete upload or corrupted file

**Solution**:
```python
async def validate_upload(file: UploadFile):
    # Check file integrity
    content = await file.read()
    await file.seek(0)
    
    # Verify file signature (magic bytes)
    signatures = {
        b'\xff\xd8\xff': 'image/jpeg',
        b'\x89PNG': 'image/png',
        b'GIF87a': 'image/gif',
        b'GIF89a': 'image/gif',
        b'%PDF': 'application/pdf'
    }
    
    file_signature = content[:10]
    mime_type = None
    
    for sig, mime in signatures.items():
        if file_signature.startswith(sig):
            mime_type = mime
            break
    
    if not mime_type:
        raise ValueError("Unsupported or corrupted file")
    
    # Verify file can be opened
    try:
        if mime_type.startswith('image/'):
            img = Image.open(io.BytesIO(content))
            img.verify()
    except Exception as e:
        raise ValueError(f"Corrupted file: {e}")
    
    return mime_type
```

## External Service Errors

### 1. Gemini API Quota Exceeded

**Error**: `429 Resource has been exhausted`

**Cause**: API quota limit reached

**Solution**:
```python
# Implement exponential backoff
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(5),
    wait=wait_exponential(multiplier=1, min=4, max=60),
    retry=retry_if_exception_type(QuotaExceededError)
)
async def call_gemini_with_retry(content: str):
    try:
        return await gemini.analyze(content)
    except Exception as e:
        if "429" in str(e) or "quota" in str(e).lower():
            raise QuotaExceededError("Gemini quota exceeded")
        raise

# Implement rate limiting
from asyncio import Semaphore

gemini_semaphore = Semaphore(5)  # Max 5 concurrent requests

async def rate_limited_gemini_call(content: str):
    async with gemini_semaphore:
        await asyncio.sleep(0.1)  # 100ms between requests
        return await gemini.analyze(content)
```

### 2. OpenAI Embedding API Timeout

**Error**: `TimeoutError: Request timed out`

**Cause**: Network issues or API overload

**Solution**:
```python
# Increase timeout and add retry
import httpx
from openai import AsyncOpenAI

client = AsyncOpenAI(
    timeout=httpx.Timeout(60.0, connect=5.0),
    max_retries=3
)

# Batch embeddings for efficiency
async def generate_embeddings_batch(texts: List[str]):
    # OpenAI supports up to 2048 embeddings per request
    batch_size = 100
    all_embeddings = []
    
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        response = await client.embeddings.create(
            model="text-embedding-3-small",
            input=batch
        )
        all_embeddings.extend([e.embedding for e in response.data])
    
    return all_embeddings
```

### 3. Firebase Auth Token Expired

**Error**: `Firebase ID token has expired`

**Cause**: Token lifetime exceeded

**Solution**:
```python
# Implement token refresh on client
async function getAuthHeaders() {
    const user = firebase.auth().currentUser;
    if (!user) throw new Error('Not authenticated');
    
    // Force token refresh if needed
    const token = await user.getIdToken(true);
    return {
        'Authorization': `Bearer ${token}`
    };
}

// Auto-retry with fresh token
async function apiCall(url, options = {}) {
    try {
        const headers = await getAuthHeaders();
        const response = await fetch(url, {
            ...options,
            headers: { ...options.headers, ...headers }
        });
        
        if (response.status === 401) {
            // Token might be expired, retry once
            const newHeaders = await getAuthHeaders();
            return fetch(url, {
                ...options,
                headers: { ...options.headers, ...newHeaders }
            });
        }
        
        return response;
    } catch (error) {
        console.error('API call failed:', error);
        throw error;
    }
}
```

## Authentication Errors

### 1. CORS Preflight Failed for Authentication

**Error**: `CORS error on OPTIONS request`

**Cause**: Preflight request not handled properly

**Solution**:
```python
# Explicitly handle OPTIONS
@router.options("/{full_path:path}")
async def options_handler():
    return Response(
        content="",
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Authorization, Content-Type",
        }
    )
```

### 2. JWT Signature Verification Failed

**Error**: `JWTError: Signature verification failed`

**Cause**: Mismatched secret key or algorithm

**Solution**:
```python
# Ensure consistent configuration
import os
from jose import jwt

# Use environment variable
SECRET_KEY = os.getenv("JWT_SECRET_KEY")
ALGORITHM = "HS256"

def verify_token(token: str):
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]  # Must match encoding algorithm
        )
        return payload
    except JWTError as e:
        logger.error(f"JWT verification failed: {e}")
        # Check if key is correct
        logger.debug(f"Using secret key ending in: ...{SECRET_KEY[-4:]}")
        raise
```

### 3. Firebase Admin SDK Initialization Error

**Error**: `Failed to initialize Firebase Admin SDK`

**Cause**: Missing or invalid service account credentials

**Solution**:
```python
import firebase_admin
from firebase_admin import credentials
import json
import os

def initialize_firebase():
    try:
        # Try environment variable first
        if os.getenv("FIREBASE_CREDENTIALS"):
            cred_dict = json.loads(os.getenv("FIREBASE_CREDENTIALS"))
            cred = credentials.Certificate(cred_dict)
        # Try file path
        elif os.getenv("FIREBASE_ADMIN_SDK_PATH"):
            cred = credentials.Certificate(os.getenv("FIREBASE_ADMIN_SDK_PATH"))
        else:
            raise ValueError("No Firebase credentials found")
        
        firebase_admin.initialize_app(cred)
        
    except Exception as e:
        logger.error(f"Firebase init failed: {e}")
        # Fallback to ADC in Google Cloud
        try:
            firebase_admin.initialize_app()
        except:
            raise RuntimeError("Failed to initialize Firebase Admin SDK")
```

## Performance Issues

### 1. Slow API Response Times

**Symptoms**: API endpoints taking > 2 seconds

**Diagnosis**:
```python
# Add timing middleware
import time
from fastapi import Request

@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    
    if process_time > 1.0:
        logger.warning(
            f"Slow request: {request.url.path} took {process_time:.2f}s"
        )
    
    return response
```

**Solutions**:
1. Add database indexes
2. Implement caching
3. Use connection pooling
4. Optimize queries
5. Add pagination

### 2. Memory Leak in Worker Process

**Symptoms**: Worker memory usage continuously increases

**Diagnosis**:
```python
import tracemalloc
import asyncio

# Start tracing
tracemalloc.start()

async def monitor_memory():
    while True:
        current, peak = tracemalloc.get_traced_memory()
        logger.info(f"Current memory: {current / 1024 / 1024:.1f} MB")
        logger.info(f"Peak memory: {peak / 1024 / 1024:.1f} MB")
        
        # Get top memory users
        snapshot = tracemalloc.take_snapshot()
        top_stats = snapshot.statistics('lineno')
        for stat in top_stats[:5]:
            logger.info(stat)
        
        await asyncio.sleep(300)  # Every 5 minutes
```

**Solution**:
```python
# Common leak sources and fixes

# 1. Unclosed file handles
# Bad
def process_file(path):
    f = open(path, 'rb')
    data = f.read()
    # f.close() missing!
    return data

# Good
def process_file(path):
    with open(path, 'rb') as f:
        return f.read()

# 2. Growing cache without limits
# Bad
cache = {}
def cached_process(key, data):
    cache[key] = expensive_operation(data)
    return cache[key]

# Good
from functools import lru_cache

@lru_cache(maxsize=1000)
def cached_process(key, data):
    return expensive_operation(data)

# 3. Event listeners not cleaned up
# Implement cleanup in worker
async def cleanup():
    # Close connections
    await redis_client.close()
    await db_pool.close()
    
    # Clear caches
    gc.collect()
```

### 3. Redis Connection Pool Exhausted

**Error**: `ConnectionError: Too many connections`

**Solution**:
```python
# Configure connection pool properly
import redis.asyncio as redis

redis_client = redis.Redis(
    host='localhost',
    port=6379,
    decode_responses=True,
    max_connections=50,
    health_check_interval=30,
    socket_keepalive=True,
    socket_keepalive_options={
        1: 1,   # TCP_KEEPIDLE
        2: 2,   # TCP_KEEPINTVL  
        3: 2,   # TCP_KEEPCNT
    }
)

# Use connection pool
async def get_redis() -> redis.Redis:
    return redis_client

# Don't create new clients
# Bad
async def bad_pattern():
    client = redis.Redis(...)  # New connection each time
    await client.get("key")

# Good  
async def good_pattern():
    await redis_client.get("key")  # Reuse pool
```

## Development Environment Errors

### 1. Port Already in Use

**Error**: `[Errno 48] Address already in use`

**Solution**:
```bash
# Find process using port
lsof -i :8000

# Kill process
kill -9 <PID>

# Or use different port
python -m uvicorn main:app --port 8001
```

### 2. Module Import Errors

**Error**: `ModuleNotFoundError: No module named 'backend'`

**Cause**: Python path not set correctly

**Solution**:
```bash
# Add to shell profile
export PYTHONPATH="${PYTHONPATH}:/path/to/project"

# Or in code
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Or use relative imports
from ..models import User  # Instead of: from backend.models import User
```

### 3. Environment Variables Not Loaded

**Error**: `KeyError: 'DATABASE_URL'`

**Solution**:
```python
# Use python-dotenv
from dotenv import load_dotenv
import os

# Load .env file
load_dotenv()

# With fallback values
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://localhost/test")

# Validate required vars
required_vars = ["DATABASE_URL", "REDIS_URL", "SECRET_KEY"]
missing = [var for var in required_vars if not os.getenv(var)]
if missing:
    raise RuntimeError(f"Missing environment variables: {missing}")
```

### 4. SSL Certificate Verification Failed

**Error**: `SSL: CERTIFICATE_VERIFY_FAILED`

**Cause**: Corporate proxy or self-signed certificates

**Development Solution** (NOT for production):
```python
# Disable SSL verification for development
import ssl
import httpx

# For httpx
client = httpx.AsyncClient(verify=False)

# For aiohttp
import aiohttp
conn = aiohttp.TCPConnector(ssl=False)
session = aiohttp.ClientSession(connector=conn)

# Set environment variable
export PYTHONHTTPSVERIFY=0
```

**Production Solution**:
```python
# Add corporate CA certificate
export REQUESTS_CA_BUNDLE=/path/to/ca-bundle.crt
export SSL_CERT_FILE=/path/to/ca-bundle.crt

# Or in code
import certifi
import ssl

ssl_context = ssl.create_default_context(cafile=certifi.where())
# Add your CA
ssl_context.load_verify_locations("/path/to/corporate-ca.crt")
```

## Production Deployment Errors

### 1. Cloud Run Cold Start Timeout

**Error**: `The request failed because the HTTP connection to the instance had an error`

**Cause**: Container takes too long to start

**Solutions**:
1. Minimize startup time:
```python
# Lazy load heavy imports
def get_ml_model():
    global _model
    if _model is None:
        import tensorflow as tf  # Import only when needed
        _model = tf.keras.models.load_model('model.h5')
    return _model

# Preload in background
import asyncio

async def preload_resources():
    # Load models, warm up connections
    await db.execute("SELECT 1")
    await redis_client.ping()

# Don't block startup
asyncio.create_task(preload_resources())
```

2. Configure Cloud Run:
```yaml
apiVersion: serving.knative.dev/v1
kind: Service
spec:
  template:
    metadata:
      annotations:
        run.googleapis.com/startup-cpu-boost: "true"
    spec:
      containerConcurrency: 1000
      timeoutSeconds: 300
```

### 2. Secret Manager Access Denied

**Error**: `403 Permission 'secretmanager.versions.access' denied`

**Solution**:
```bash
# Grant service account access
gcloud secrets add-iam-policy-binding MY_SECRET \
    --member="serviceAccount:my-service@project.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

# Verify permissions
gcloud secrets get-iam-policy MY_SECRET
```

### 3. Cloud SQL Connection Failed

**Error**: `could not connect to server: Connection refused`

**Solutions**:
1. Use Cloud SQL Proxy:
```yaml
# In Cloud Run service
spec:
  template:
    metadata:
      annotations:
        run.googleapis.com/cloudsql-instances: project:region:instance
```

2. Configure connection:
```python
# Use Unix socket in Cloud Run
if os.getenv("CLOUD_RUN_ENV"):
    DATABASE_URL = (
        f"postgresql://{user}:{password}@/"
        f"{database}?host=/cloudsql/{connection_name}"
    )
else:
    DATABASE_URL = f"postgresql://{user}:{password}@{host}/{database}"
```

### 4. Memory Limit Exceeded

**Error**: `Memory limit of 2048M exceeded`

**Diagnosis**:
```python
# Add memory monitoring
import psutil
import os

def log_memory_usage():
    process = psutil.Process(os.getpid())
    memory_info = process.memory_info()
    logger.info(f"Memory usage: {memory_info.rss / 1024 / 1024:.1f} MB")
```

**Solutions**:
1. Stream large files:
```python
# Don't load entire file
# Bad
content = await file.read()

# Good - stream in chunks
async def process_large_file(file: UploadFile):
    chunk_size = 1024 * 1024  # 1MB chunks
    while chunk := await file.read(chunk_size):
        await process_chunk(chunk)
```

2. Increase memory limit:
```yaml
resources:
  limits:
    memory: "4Gi"
    cpu: "2"
```

## Quick Debugging Checklist

When encountering an error:

1. **Check logs**:
   ```bash
   # Local
   tail -f logs/app.log
   
   # Cloud Run
   gcloud logging read "resource.type=cloud_run_revision" --limit 50
   ```

2. **Verify environment**:
   ```python
   # Add debug endpoint
   @router.get("/debug/env")
   async def debug_env(user: User = Depends(get_admin_user)):
       return {
           "python_version": sys.version,
           "environment": os.getenv("ENVIRONMENT"),
           "database_connected": await check_db_connection(),
           "redis_connected": await redis_client.ping(),
           "disk_usage": shutil.disk_usage("/").free / 1024 / 1024 / 1024,
           "memory_usage": psutil.Process().memory_info().rss / 1024 / 1024
       }
   ```

3. **Test minimal case**:
   ```python
   # Isolate the problem
   async def test_specific_issue():
       # Minimal code to reproduce
       try:
           result = await problematic_function()
       except Exception as e:
           logger.error(f"Error details: {e}", exc_info=True)
           import pdb; pdb.post_mortem()
   ```

4. **Check recent changes**:
   ```bash
   # What changed?
   git log --oneline -10
   git diff HEAD~1
   ```

Remember: Always check logs first, reproduce locally if possible, and isolate the problem to the smallest possible code section.