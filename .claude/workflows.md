# Development Workflows

Step-by-step guides for common development tasks in the Multimodal Search System.

## Table of Contents
1. [Adding a New File Type Processor](#adding-a-new-file-type-processor)
2. [Creating a New API Endpoint](#creating-a-new-api-endpoint)
3. [Implementing a New Search Feature](#implementing-a-new-search-feature)
4. [Debugging Processing Failures](#debugging-processing-failures)
5. [Performance Optimization](#performance-optimization)
6. [Adding a New External Service](#adding-a-new-external-service)
7. [Database Schema Changes](#database-schema-changes)
8. [Deploying to Production](#deploying-to-production)

## Adding a New File Type Processor

### Steps to add support for a new file type (e.g., 3D models)

1. **Update Database Schema**
   ```sql
   -- Add new file type to enum
   ALTER TYPE file_type_enum ADD VALUE '3d_model';
   
   -- Add specific metadata fields if needed
   ALTER TABLE uploads 
   ADD COLUMN vertices_count INTEGER,
   ADD COLUMN polygons_count INTEGER;
   ```

2. **Create Processor Module**
   ```bash
   touch backend/processors/model_3d_processor.py
   ```

3. **Implement Processor Class**
   - Create new processor in `processors/model_3d_processor.py`
   - Inherit from `BaseProcessor`
   - Implement required methods:
     - `validate_file()`
     - `extract_metadata()`
     - `generate_thumbnail()`
     - `prepare_for_ai()`

4. **Register in Processor Factory**
   ```python
   # In processors/factory.py
   from processors.model_3d_processor import Model3DProcessor
   
   PROCESSORS = {
       'image': ImageProcessor,
       'video': VideoProcessor,
       'audio': AudioProcessor,
       'document': DocumentProcessor,
       '3d_model': Model3DProcessor,  # Add this line
   }
   ```

5. **Update File Validator**
   ```python
   # In services/file_validator.py
   ALLOWED_EXTENSIONS = {
       '3d_model': ['.obj', '.fbx', '.gltf', '.glb', '.stl']
   }
   
   MIME_TYPES = {
       '3d_model': ['model/gltf+json', 'model/obj', 'application/octet-stream']
   }
   ```

6. **Add Frontend Support**
   - Update file input accept attribute
   - Add icon for 3D model files
   - Update preview logic

7. **Write Tests**
   ```bash
   # Create test file
   touch tests/unit/test_model_3d_processor.py
   
   # Run tests
   pytest tests/unit/test_model_3d_processor.py
   ```

8. **Update Documentation**
   - Add to API documentation
   - Update README with supported formats
   - Add example in API playground

## Creating a New API Endpoint

### Example: Add endpoint to get file processing statistics

1. **Define Schema**
   ```bash
   # Create schema file
   touch backend/schemas/stats_schema.py
   ```
   
   ```python
   # In schemas/stats_schema.py
   from pydantic import BaseModel
   from typing import Dict
   
   class StatsResponse(BaseModel):
       total_uploads: int
       uploads_by_type: Dict[str, int]
       total_storage_bytes: int
       average_processing_time_ms: float
   ```

2. **Create Model Method**
   ```python
   # In models/upload.py
   @classmethod
   async def get_user_stats(cls, user_id: UUID) -> dict:
       """Get processing statistics for a user"""
       query = """
           SELECT 
               COUNT(*) as total_uploads,
               COUNT(*) FILTER (WHERE file_type = 'image') as images,
               COUNT(*) FILTER (WHERE file_type = 'video') as videos,
               SUM(file_size) as total_storage_bytes,
               AVG(EXTRACT(EPOCH FROM (processing_completed_at - processing_started_at)) * 1000) as avg_processing_ms
           FROM uploads
           WHERE user_id = $1 AND processing_status = 'completed'
       """
       result = await db.fetchrow(query, user_id)
       return dict(result)
   ```

3. **Create Router Endpoint**
   ```python
   # In routers/stats_router.py
   from fastapi import APIRouter, Depends
   from schemas.stats_schema import StatsResponse
   from auth.dependencies import get_current_user
   
   router = APIRouter(prefix="/api/stats", tags=["statistics"])
   
   @router.get("/me", response_model=StatsResponse)
   async def get_my_stats(user: User = Depends(get_current_user)):
       """Get current user's upload statistics"""
       stats = await Upload.get_user_stats(user.id)
       
       return StatsResponse(
           total_uploads=stats['total_uploads'],
           uploads_by_type={
               'image': stats['images'],
               'video': stats['videos']
           },
           total_storage_bytes=stats['total_storage_bytes'] or 0,
           average_processing_time_ms=stats['avg_processing_ms'] or 0
       )
   ```

4. **Register Router**
   ```python
   # In main.py
   from routers import stats_router
   
   app.include_router(stats_router.router)
   ```

5. **Add Tests**
   ```python
   # In tests/integration/test_stats_api.py
   async def test_get_user_stats(test_client, auth_headers):
       response = await test_client.get("/api/stats/me", headers=auth_headers)
       assert response.status_code == 200
       data = response.json()
       assert "total_uploads" in data
       assert "uploads_by_type" in data
   ```

6. **Update API Documentation**
   - Add endpoint to OpenAPI spec
   - Include example responses
   - Document authentication requirements

## Implementing a New Search Feature

### Example: Add semantic similarity search with filters

1. **Update Search Schema**
   ```python
   # In schemas/search_schema.py
   class AdvancedSearchRequest(BaseModel):
       query: str
       file_types: Optional[List[str]] = None
       date_from: Optional[datetime] = None
       date_to: Optional[datetime] = None
       min_size_mb: Optional[float] = None
       max_size_mb: Optional[float] = None
       limit: int = Field(20, ge=1, le=100)
   ```

2. **Create Search Service**
   ```python
   # In services/search_service.py
   class AdvancedSearchService:
       @staticmethod
       async def search_with_filters(
           user_id: UUID,
           request: AdvancedSearchRequest
       ) -> List[SearchResult]:
           # Generate embedding for query
           embedding = await EmbeddingService.generate(request.query)
           
           # Build dynamic query with filters
           query = SearchQueryBuilder() \
               .with_user(user_id) \
               .with_embedding(embedding) \
               .with_file_types(request.file_types) \
               .with_date_range(request.date_from, request.date_to) \
               .with_size_range(request.min_size_mb, request.max_size_mb) \
               .limit(request.limit) \
               .build()
           
           # Execute search
           results = await db.fetch(query)
           return [SearchResult.from_db(r) for r in results]
   ```

3. **Implement Query Builder**
   ```python
   # In services/search_query_builder.py
   class SearchQueryBuilder:
       def __init__(self):
           self.conditions = ["user_id = $1"]
           self.params = []
           self.param_count = 1
       
       def with_embedding(self, embedding: List[float]):
           self.params.append(embedding)
           self.param_count += 1
           # Order by similarity will be added at build()
           return self
       
       def build(self) -> Tuple[str, List]:
           query = f"""
               SELECT *, 
                      1 - (embedding <=> ${self.param_count}) as similarity
               FROM uploads
               WHERE {' AND '.join(self.conditions)}
               ORDER BY similarity DESC
               LIMIT $2
           """
           return query, self.params
   ```

4. **Add Caching Layer**
   ```python
   # In services/cache_service.py
   @cache_result(ttl=300)  # 5 minutes
   async def cached_search(
       user_id: UUID,
       query_hash: str
   ) -> List[SearchResult]:
       return await AdvancedSearchService.search_with_filters(...)
   ```

5. **Create API Endpoint**
   ```python
   # In routers/search_router.py
   @router.post("/advanced", response_model=SearchResponse)
   async def advanced_search(
       request: AdvancedSearchRequest,
       user: User = Depends(get_current_user)
   ):
       # Generate cache key
       cache_key = hashlib.md5(
           f"{user.id}:{request.json()}".encode()
       ).hexdigest()
       
       # Try cache first
       cached = await redis.get(f"search:{cache_key}")
       if cached:
           return SearchResponse.parse_raw(cached)
       
       # Perform search
       results = await AdvancedSearchService.search_with_filters(
           user.id, request
       )
       
       # Cache results
       response = SearchResponse(results=results)
       await redis.setex(
           f"search:{cache_key}", 
           300, 
           response.json()
       )
       
       return response
   ```

6. **Add Frontend Support**
   - Create advanced search form
   - Add filter UI components
   - Update search results display

## Debugging Processing Failures

### Systematic approach to debug failed file processing

1. **Check Job Status**
   ```bash
   # Get job details from Redis
   redis-cli GET job:status:JOB_UUID
   
   # Check if job is in failed queue
   redis-cli LRANGE queue:uploads:failed 0 -1
   ```

2. **Examine Database Record**
   ```sql
   -- Get upload details
   SELECT * FROM uploads WHERE id = 'UPLOAD_UUID';
   
   -- Check processing job record
   SELECT * FROM processing_jobs WHERE upload_id = 'UPLOAD_UUID';
   ```

3. **Review Logs**
   ```bash
   # Search for upload ID in logs
   grep UPLOAD_UUID logs/worker.log
   
   # Check for errors around timestamp
   grep -A 10 -B 10 "ERROR" logs/worker.log | grep -A 20 -B 20 "TIMESTAMP"
   ```

4. **Test File Processing Locally**
   ```python
   # Create debug script: debug_upload.py
   import asyncio
   from processors.factory import ProcessorFactory
   
   async def debug_process(file_path: str, file_type: str):
       processor = ProcessorFactory.get_processor(file_type)
       
       # Test each step
       print("1. Validating file...")
       is_valid = await processor.validate_file(file_path)
       print(f"   Valid: {is_valid}")
       
       print("2. Extracting metadata...")
       metadata = await processor.extract_metadata(file_path)
       print(f"   Metadata: {metadata}")
       
       print("3. Generating thumbnail...")
       thumbnail = await processor.generate_thumbnail(file_path)
       print(f"   Thumbnail generated: {thumbnail is not None}")
       
       print("4. Preparing for AI...")
       ai_input = await processor.prepare_for_ai(file_path)
       print(f"   AI input size: {len(ai_input)} bytes")
   
   # Run: python debug_upload.py
   asyncio.run(debug_process("path/to/file.jpg", "image"))
   ```

5. **Check External Services**
   ```python
   # Test Gemini API
   curl -X POST https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent \
     -H "x-goog-api-key: YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
   
   # Test OpenAI API
   curl https://api.openai.com/v1/embeddings \
     -H "Authorization: Bearer YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"input": "Test", "model": "text-embedding-3-small"}'
   ```

6. **Common Issues Checklist**
   - [ ] File size within limits?
   - [ ] File format supported?
   - [ ] API quotas available?
   - [ ] Network connectivity OK?
   - [ ] Sufficient disk space?
   - [ ] Redis connection alive?
   - [ ] Database connection pool not exhausted?

7. **Manual Retry**
   ```python
   # Retry single upload
   from worker import process_upload
   asyncio.run(process_upload("UPLOAD_UUID"))
   
   # Move from failed to pending queue
   redis-cli LMOVE queue:uploads:failed queue:uploads:pending RIGHT LEFT
   ```

## Performance Optimization

### Steps to optimize slow search queries

1. **Identify Slow Queries**
   ```sql
   -- Enable query logging
   ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1s
   SELECT pg_reload_conf();
   
   -- Check slow queries
   SELECT query, mean_exec_time, calls 
   FROM pg_stat_statements 
   ORDER BY mean_exec_time DESC 
   LIMIT 10;
   ```

2. **Analyze Query Plans**
   ```sql
   EXPLAIN ANALYZE
   SELECT * FROM uploads
   WHERE user_id = 'USER_UUID'
   AND embedding <=> '[...]'::vector < 0.5
   ORDER BY embedding <=> '[...]'::vector
   LIMIT 20;
   ```

3. **Optimize pgvector Index**
   ```sql
   -- Check current index
   SELECT indexname, indexdef 
   FROM pg_indexes 
   WHERE tablename = 'uploads';
   
   -- Rebuild with better parameters
   DROP INDEX idx_uploads_embedding;
   CREATE INDEX idx_uploads_embedding 
   ON uploads 
   USING ivfflat (embedding vector_cosine_ops) 
   WITH (lists = 200); -- Increase lists for better recall
   ```

4. **Implement Query Caching**
   ```python
   # In services/cache_service.py
   class QueryCache:
       def __init__(self, redis_client):
           self.redis = redis_client
       
       async def get_or_compute(
           self,
           key: str,
           compute_func: Callable,
           ttl: int = 300
       ):
           # Check cache
           cached = await self.redis.get(key)
           if cached:
               return json.loads(cached)
           
           # Compute and cache
           result = await compute_func()
           await self.redis.setex(
               key, ttl, json.dumps(result)
           )
           return result
   ```

5. **Batch Operations**
   ```python
   # Instead of individual queries
   for upload_id in upload_ids:
       result = await get_upload(upload_id)
   
   # Use batch query
   results = await get_uploads_batch(upload_ids)
   ```

6. **Add Connection Pooling**
   ```python
   # In database/connection.py
   async def create_pool():
       return await asyncpg.create_pool(
           DATABASE_URL,
           min_size=10,
           max_size=50,
           max_queries=50000,
           max_inactive_connection_lifetime=300,
           command_timeout=60
       )
   ```

7. **Monitor Performance**
   ```python
   # Add metrics
   from prometheus_client import Histogram
   
   search_duration = Histogram(
       'search_duration_seconds',
       'Time spent processing search request',
       buckets=[.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5]
   )
   
   @search_duration.time()
   async def search_endpoint():
       # Your search logic
   ```

## Adding a New External Service

### Example: Integrate with AWS Rekognition for additional image analysis

1. **Add Dependencies**
   ```bash
   # Update requirements.txt
   echo "boto3==1.35.0" >> requirements.txt
   pip install boto3
   ```

2. **Create Service Interface**
   ```python
   # In services/interfaces/image_analysis.py
   from abc import ABC, abstractmethod
   
   class ImageAnalysisService(ABC):
       @abstractmethod
       async def analyze_image(self, image_path: str) -> dict:
           pass
       
       @abstractmethod
       async def detect_objects(self, image_path: str) -> List[str]:
           pass
   ```

3. **Implement Service**
   ```python
   # In services/aws_rekognition.py
   import boto3
   from services.interfaces.image_analysis import ImageAnalysisService
   
   class RekognitionService(ImageAnalysisService):
       def __init__(self):
           self.client = boto3.client(
               'rekognition',
               region_name='us-east-1'
           )
       
       async def analyze_image(self, image_path: str) -> dict:
           with open(image_path, 'rb') as image_file:
               response = self.client.detect_labels(
                   Image={'Bytes': image_file.read()},
                   MaxLabels=10,
                   MinConfidence=70
               )
           
           return {
               'labels': [
                   {'name': label['Name'], 'confidence': label['Confidence']}
                   for label in response['Labels']
               ]
           }
   ```

4. **Add to Configuration**
   ```python
   # In config.py
   class Settings(BaseSettings):
       # Existing settings...
       
       # AWS settings
       aws_access_key_id: Optional[str] = None
       aws_secret_access_key: Optional[str] = None
       enable_rekognition: bool = False
   ```

5. **Integrate with Processor**
   ```python
   # In processors/image_processor.py
   async def process(self, file_path: str) -> ProcessingResult:
       # Existing processing...
       
       # Additional analysis if enabled
       if settings.enable_rekognition:
           rekognition_data = await self.rekognition.analyze_image(file_path)
           metadata['aws_labels'] = rekognition_data['labels']
       
       return ProcessingResult(
           metadata=metadata,
           thumbnail_path=thumbnail_path,
           ai_input=ai_input
       )
   ```

6. **Add Circuit Breaker**
   ```python
   # In services/circuit_breaker.py
   class CircuitBreaker:
       def __init__(self, failure_threshold=5, recovery_timeout=60):
           self.failure_threshold = failure_threshold
           self.recovery_timeout = recovery_timeout
           self.failure_count = 0
           self.last_failure_time = None
           self.state = 'closed'  # closed, open, half-open
       
       async def call(self, func, *args, **kwargs):
           if self.state == 'open':
               if time.time() - self.last_failure_time > self.recovery_timeout:
                   self.state = 'half-open'
               else:
                   raise ServiceUnavailableError("Circuit breaker is open")
           
           try:
               result = await func(*args, **kwargs)
               if self.state == 'half-open':
                   self.state = 'closed'
                   self.failure_count = 0
               return result
           except Exception as e:
               self.failure_count += 1
               self.last_failure_time = time.time()
               
               if self.failure_count >= self.failure_threshold:
                   self.state = 'open'
               
               raise e
   ```

7. **Write Tests**
   ```python
   # In tests/unit/test_rekognition_service.py
   @pytest.mark.asyncio
   async def test_rekognition_analyze(mocker):
       # Mock boto3 client
       mock_client = mocker.patch('boto3.client')
       mock_client.return_value.detect_labels.return_value = {
           'Labels': [
               {'Name': 'Dog', 'Confidence': 98.5},
               {'Name': 'Pet', 'Confidence': 95.2}
           ]
       }
       
       service = RekognitionService()
       result = await service.analyze_image('test.jpg')
       
       assert len(result['labels']) == 2
       assert result['labels'][0]['name'] == 'Dog'
   ```

## Database Schema Changes

### Safe process for modifying database schema

1. **Create Migration File**
   ```bash
   # Create new migration
   touch migrations/002_add_user_preferences.sql
   ```

2. **Write Forward Migration**
   ```sql
   -- migrations/002_add_user_preferences.sql
   BEGIN;
   
   -- Create new table
   CREATE TABLE user_preferences (
       user_id UUID PRIMARY KEY,
       email_notifications BOOLEAN DEFAULT true,
       default_search_limit INTEGER DEFAULT 20,
       ui_theme VARCHAR(20) DEFAULT 'light',
       created_at TIMESTAMP DEFAULT NOW(),
       updated_at TIMESTAMP DEFAULT NOW()
   );
   
   -- Add index
   CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);
   
   -- Add trigger for updated_at
   CREATE TRIGGER update_user_preferences_updated_at
   BEFORE UPDATE ON user_preferences
   FOR EACH ROW
   EXECUTE FUNCTION update_updated_at_column();
   
   COMMIT;
   ```

3. **Write Rollback Migration**
   ```sql
   -- migrations/002_add_user_preferences_rollback.sql
   BEGIN;
   
   DROP TABLE IF EXISTS user_preferences;
   
   COMMIT;
   ```

4. **Test Migration Locally**
   ```bash
   # Backup current database
   pg_dump multimodal_search > backup_before_migration.sql
   
   # Apply migration
   psql -d multimodal_search -f migrations/002_add_user_preferences.sql
   
   # Test rollback
   psql -d multimodal_search -f migrations/002_add_user_preferences_rollback.sql
   
   # Re-apply if successful
   psql -d multimodal_search -f migrations/002_add_user_preferences.sql
   ```

5. **Update Models**
   ```python
   # In models/user_preferences.py
   class UserPreferences(BaseModel):
       user_id: UUID
       email_notifications: bool = True
       default_search_limit: int = 20
       ui_theme: str = 'light'
       created_at: datetime
       updated_at: datetime
       
       @classmethod
       async def get_or_create(cls, user_id: UUID) -> 'UserPreferences':
           # Try to get existing
           result = await db.fetchrow(
               "SELECT * FROM user_preferences WHERE user_id = $1",
               user_id
           )
           
           if result:
               return cls(**result)
           
           # Create new
           await db.execute(
               """
               INSERT INTO user_preferences (user_id) 
               VALUES ($1)
               """,
               user_id
           )
           
           return cls(user_id=user_id)
   ```

6. **Deploy Migration**
   ```bash
   # On production
   # 1. Announce maintenance window
   # 2. Backup production database
   pg_dump $PROD_DATABASE_URL > prod_backup_$(date +%Y%m%d_%H%M%S).sql
   
   # 3. Apply migration
   psql $PROD_DATABASE_URL -f migrations/002_add_user_preferences.sql
   
   # 4. Verify
   psql $PROD_DATABASE_URL -c "\\d user_preferences"
   ```

## Deploying to Production

### Complete deployment checklist

1. **Pre-deployment Checks**
   - [ ] All tests passing locally
   - [ ] Code review completed
   - [ ] Documentation updated
   - [ ] Environment variables documented
   - [ ] Database migrations tested

2. **Build and Test Docker Image**
   ```bash
   # Build image
   docker build -t multimodal-search:$(git rev-parse --short HEAD) .
   
   # Test locally
   docker run --env-file .env.test multimodal-search:$(git rev-parse --short HEAD)
   
   # Run smoke tests
   ./scripts/smoke_tests.sh
   ```

3. **Tag and Push to Registry**
   ```bash
   # Tag for GCR
   docker tag multimodal-search:$(git rev-parse --short HEAD) \
     gcr.io/$PROJECT_ID/multimodal-search:$(git rev-parse --short HEAD)
   
   docker tag multimodal-search:$(git rev-parse --short HEAD) \
     gcr.io/$PROJECT_ID/multimodal-search:latest
   
   # Push to registry
   docker push gcr.io/$PROJECT_ID/multimodal-search:$(git rev-parse --short HEAD)
   docker push gcr.io/$PROJECT_ID/multimodal-search:latest
   ```

4. **Deploy to Staging**
   ```bash
   # Update staging
   gcloud run deploy multimodal-search-staging \
     --image gcr.io/$PROJECT_ID/multimodal-search:$(git rev-parse --short HEAD) \
     --region us-central1 \
     --platform managed
   
   # Run integration tests against staging
   ENVIRONMENT=staging pytest tests/integration/
   ```

5. **Database Migrations**
   ```bash
   # Apply pending migrations
   ./scripts/run_migrations.sh staging
   
   # Verify migrations
   psql $STAGING_DATABASE_URL -c "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;"
   ```

6. **Deploy to Production**
   ```bash
   # Blue-green deployment
   # 1. Deploy to new revision without traffic
   gcloud run deploy multimodal-search \
     --image gcr.io/$PROJECT_ID/multimodal-search:$(git rev-parse --short HEAD) \
     --region us-central1 \
     --platform managed \
     --no-traffic \
     --revision-suffix $(date +%Y%m%d-%H%M%S)
   
   # 2. Run health checks
   NEW_REVISION_URL=$(gcloud run revisions describe multimodal-search-$(date +%Y%m%d-%H%M%S) --region us-central1 --format 'value(status.url)')
   curl $NEW_REVISION_URL/health
   
   # 3. Gradually shift traffic
   gcloud run services update-traffic multimodal-search \
     --region us-central1 \
     --to-revisions multimodal-search-$(date +%Y%m%d-%H%M%S)=10
   
   # 4. Monitor metrics
   # 5. Increase traffic if healthy
   gcloud run services update-traffic multimodal-search \
     --region us-central1 \
     --to-revisions multimodal-search-$(date +%Y%m%d-%H%M%S)=50
   
   # 6. Complete rollout
   gcloud run services update-traffic multimodal-search \
     --region us-central1 \
     --to-revisions multimodal-search-$(date +%Y%m%d-%H%M%S)=100
   ```

7. **Post-deployment**
   ```bash
   # Verify deployment
   ./scripts/post_deploy_checks.sh
   
   # Update monitoring dashboards
   # Check error rates
   # Monitor performance metrics
   
   # Tag release in git
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin v1.2.0
   ```

8. **Rollback Procedure**
   ```bash
   # If issues detected, rollback quickly
   gcloud run services update-traffic multimodal-search \
     --region us-central1 \
     --to-revisions PREVIOUS_REVISION=100
   
   # Investigate issues
   gcloud logging read "resource.type=cloud_run_revision AND resource.labels.revision_name=multimodal-search-TIMESTAMP" --limit 100
   ```

## Quick Reference

### Common Patterns

**Async Context Manager**
```python
async with db.transaction():
    await model1.save()
    await model2.save()
    # Commits on success, rollbacks on error
```

**Retry with Backoff**
```python
@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
async def flaky_operation():
    # Your code here
```

**Background Task**
```python
background_tasks.add_task(
    process_thumbnail,
    upload_id=upload.id,
    priority="low"
)
```

**Rate Limiting Check**
```python
if await rate_limiter.is_allowed(user_id, "upload", limit=100):
    # Process upload
else:
    raise HTTPException(429, "Rate limit exceeded")
```