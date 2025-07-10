# Code Patterns and Templates

Reusable code patterns and templates for the Multimodal Search System. Copy and adapt these templates for consistent code structure.

## Table of Contents
1. [Model Templates](#model-templates)
2. [Service Templates](#service-templates)
3. [API Endpoint Templates](#api-endpoint-templates)
4. [Schema Templates](#schema-templates)
5. [Test Templates](#test-templates)
6. [Processor Templates](#processor-templates)
7. [Error Handling Patterns](#error-handling-patterns)
8. [Database Patterns](#database-patterns)
9. [Caching Patterns](#caching-patterns)
10. [Authentication Patterns](#authentication-patterns)

## Model Templates

### Base Model Class
```python
# models/base.py
from typing import TypeVar, Type, List, Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel as PydanticBaseModel

T = TypeVar('T', bound='BaseModel')

class BaseModel(PydanticBaseModel):
    """Base model class with common database operations"""
    
    class Config:
        orm_mode = True
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            UUID: lambda v: str(v)
        }
    
    @classmethod
    async def find_by_id(cls: Type[T], id: UUID) -> Optional[T]:
        """Find record by ID"""
        query = f"SELECT * FROM {cls.table_name()} WHERE id = $1"
        result = await db.fetchrow(query, id)
        return cls(**result) if result else None
    
    @classmethod
    async def find_all(cls: Type[T], limit: int = 100, offset: int = 0) -> List[T]:
        """Find all records with pagination"""
        query = f"""
            SELECT * FROM {cls.table_name()} 
            ORDER BY created_at DESC 
            LIMIT $1 OFFSET $2
        """
        results = await db.fetch(query, limit, offset)
        return [cls(**row) for row in results]
    
    @classmethod
    async def count(cls: Type[T]) -> int:
        """Count total records"""
        query = f"SELECT COUNT(*) FROM {cls.table_name()}"
        result = await db.fetchval(query)
        return result
    
    async def save(self) -> None:
        """Save or update record"""
        if hasattr(self, 'id') and self.id:
            await self._update()
        else:
            await self._insert()
    
    async def delete(self) -> None:
        """Delete record"""
        query = f"DELETE FROM {self.table_name()} WHERE id = $1"
        await db.execute(query, self.id)
    
    @classmethod
    def table_name(cls) -> str:
        """Get table name from class name"""
        return cls.__name__.lower() + 's'
```

### Domain Model Template
```python
# models/your_model.py
from typing import Optional, List
from uuid import UUID, uuid4
from datetime import datetime
from models.base import BaseModel
from database import db

class YourModel(BaseModel):
    """Your model description"""
    
    # Fields
    id: UUID
    name: str
    description: Optional[str] = None
    status: str = 'active'
    metadata: dict = {}
    created_at: datetime
    updated_at: datetime
    
    # Custom class methods
    @classmethod
    async def create(cls, name: str, description: Optional[str] = None) -> 'YourModel':
        """Create a new record"""
        model_id = uuid4()
        now = datetime.utcnow()
        
        query = """
            INSERT INTO your_models (id, name, description, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
        """
        
        result = await db.fetchrow(
            query, model_id, name, description, now, now
        )
        
        return cls(**result)
    
    @classmethod
    async def find_by_name(cls, name: str) -> Optional['YourModel']:
        """Find by name"""
        query = "SELECT * FROM your_models WHERE name = $1"
        result = await db.fetchrow(query, name)
        return cls(**result) if result else None
    
    @classmethod
    async def find_active(cls, limit: int = 100) -> List['YourModel']:
        """Find all active records"""
        query = """
            SELECT * FROM your_models 
            WHERE status = 'active' 
            ORDER BY created_at DESC 
            LIMIT $1
        """
        results = await db.fetch(query, limit)
        return [cls(**row) for row in results]
    
    # Instance methods
    async def update_status(self, new_status: str) -> None:
        """Update status"""
        self.status = new_status
        self.updated_at = datetime.utcnow()
        
        query = """
            UPDATE your_models 
            SET status = $1, updated_at = $2 
            WHERE id = $3
        """
        await db.execute(query, self.status, self.updated_at, self.id)
    
    async def add_metadata(self, key: str, value: any) -> None:
        """Add metadata"""
        self.metadata[key] = value
        
        query = """
            UPDATE your_models 
            SET metadata = metadata || $1::jsonb,
                updated_at = $2
            WHERE id = $3
        """
        await db.execute(
            query, 
            {key: value}, 
            datetime.utcnow(), 
            self.id
        )
```

## Service Templates

### Base Service Class
```python
# services/base.py
from typing import TypeVar, Generic
from abc import ABC, abstractmethod

T = TypeVar('T')

class BaseService(ABC, Generic[T]):
    """Base service class with common patterns"""
    
    def __init__(self):
        self._initialize()
    
    @abstractmethod
    def _initialize(self) -> None:
        """Initialize service dependencies"""
        pass
    
    async def __aenter__(self):
        """Async context manager entry"""
        await self._startup()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        await self._shutdown()
    
    async def _startup(self) -> None:
        """Service startup logic"""
        pass
    
    async def _shutdown(self) -> None:
        """Service cleanup logic"""
        pass
```

### Business Logic Service Template
```python
# services/your_service.py
from typing import List, Optional
from uuid import UUID
from services.base import BaseService
from models.your_model import YourModel
from schemas.your_schema import YourCreateRequest, YourUpdateRequest
from exceptions import ValidationError, NotFoundError

class YourService(BaseService[YourModel]):
    """Service for handling your business logic"""
    
    def _initialize(self) -> None:
        """Initialize service dependencies"""
        self.cache_ttl = 300  # 5 minutes
        self.max_batch_size = 100
    
    async def create_item(
        self, 
        request: YourCreateRequest, 
        user_id: UUID
    ) -> YourModel:
        """Create a new item with validation"""
        # Validate request
        await self._validate_create_request(request, user_id)
        
        # Create in database
        item = await YourModel.create(
            name=request.name,
            description=request.description,
            owner_id=user_id
        )
        
        # Post-creation tasks
        await self._after_create(item)
        
        return item
    
    async def update_item(
        self,
        item_id: UUID,
        request: YourUpdateRequest,
        user_id: UUID
    ) -> YourModel:
        """Update existing item"""
        # Get and verify ownership
        item = await self._get_item_with_permission(item_id, user_id)
        
        # Update fields
        if request.name is not None:
            item.name = request.name
        if request.description is not None:
            item.description = request.description
        
        # Save changes
        await item.save()
        
        # Invalidate cache
        await self._invalidate_cache(item_id)
        
        return item
    
    async def batch_process(
        self,
        item_ids: List[UUID],
        operation: str,
        user_id: UUID
    ) -> List[YourModel]:
        """Process multiple items in batch"""
        if len(item_ids) > self.max_batch_size:
            raise ValidationError(
                f"Batch size exceeds maximum of {self.max_batch_size}"
            )
        
        results = []
        
        # Process in transaction
        async with db.transaction():
            for item_id in item_ids:
                item = await self._process_single(item_id, operation, user_id)
                results.append(item)
        
        return results
    
    # Private methods
    async def _validate_create_request(
        self, 
        request: YourCreateRequest,
        user_id: UUID
    ) -> None:
        """Validate creation request"""
        # Check for duplicates
        existing = await YourModel.find_by_name(request.name)
        if existing:
            raise ValidationError(f"Item with name '{request.name}' already exists")
        
        # Check user quota
        user_count = await YourModel.count_by_user(user_id)
        if user_count >= 1000:
            raise ValidationError("User quota exceeded")
    
    async def _get_item_with_permission(
        self,
        item_id: UUID,
        user_id: UUID
    ) -> YourModel:
        """Get item and verify user has permission"""
        item = await YourModel.find_by_id(item_id)
        if not item:
            raise NotFoundError(f"Item {item_id} not found")
        
        if item.owner_id != user_id:
            raise PermissionError("You don't have permission to access this item")
        
        return item
    
    async def _after_create(self, item: YourModel) -> None:
        """Post-creation tasks"""
        # Send notification
        await NotificationService.send(
            f"New item created: {item.name}",
            item.owner_id
        )
        
        # Log event
        await EventLogger.log('item_created', item.id)
    
    async def _invalidate_cache(self, item_id: UUID) -> None:
        """Invalidate related cache entries"""
        await cache.delete(f"item:{item_id}")
        await cache.delete(f"user_items:{item.owner_id}")
```

## API Endpoint Templates

### Router Template
```python
# routers/your_router.py
from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query, Path, Body
from fastapi.responses import JSONResponse

from auth.dependencies import get_current_user
from models.user import User
from schemas.your_schema import (
    YourCreateRequest,
    YourUpdateRequest,
    YourResponse,
    YourListResponse,
    YourBatchRequest
)
from services.your_service import YourService

router = APIRouter(
    prefix="/api/your-endpoint",
    tags=["your-feature"],
    responses={
        404: {"description": "Not found"},
        403: {"description": "Forbidden"},
        400: {"description": "Bad request"}
    }
)

# Initialize service
service = YourService()

@router.post(
    "/",
    response_model=YourResponse,
    status_code=201,
    summary="Create a new item",
    description="Create a new item with the provided data"
)
async def create_item(
    request: YourCreateRequest = Body(..., example={
        "name": "Example Item",
        "description": "This is an example"
    }),
    user: User = Depends(get_current_user)
) -> YourResponse:
    """Create a new item"""
    try:
        item = await service.create_item(request, user.id)
        return YourResponse.from_model(item)
    except ValidationError as e:
        raise HTTPException(400, str(e))
    except Exception as e:
        logger.error(f"Error creating item: {e}")
        raise HTTPException(500, "Internal server error")

@router.get(
    "/",
    response_model=YourListResponse,
    summary="List items",
    description="Get a paginated list of items"
)
async def list_items(
    limit: int = Query(20, ge=1, le=100, description="Number of items to return"),
    offset: int = Query(0, ge=0, description="Number of items to skip"),
    search: Optional[str] = Query(None, description="Search term"),
    status: Optional[str] = Query(None, description="Filter by status"),
    sort_by: str = Query("created_at", description="Sort field"),
    sort_order: str = Query("desc", regex="^(asc|desc)$"),
    user: User = Depends(get_current_user)
) -> YourListResponse:
    """List items with filtering and pagination"""
    items = await service.list_items(
        user_id=user.id,
        limit=limit,
        offset=offset,
        search=search,
        status=status,
        sort_by=sort_by,
        sort_order=sort_order
    )
    
    total = await service.count_items(user_id=user.id, search=search, status=status)
    
    return YourListResponse(
        items=[YourResponse.from_model(item) for item in items],
        total=total,
        limit=limit,
        offset=offset,
        has_more=(offset + limit) < total
    )

@router.get(
    "/{item_id}",
    response_model=YourResponse,
    summary="Get item by ID",
    description="Retrieve a specific item by its ID"
)
async def get_item(
    item_id: UUID = Path(..., description="Item ID"),
    user: User = Depends(get_current_user)
) -> YourResponse:
    """Get single item"""
    try:
        item = await service.get_item(item_id, user.id)
        return YourResponse.from_model(item)
    except NotFoundError:
        raise HTTPException(404, "Item not found")
    except PermissionError:
        raise HTTPException(403, "Access denied")

@router.put(
    "/{item_id}",
    response_model=YourResponse,
    summary="Update item",
    description="Update an existing item"
)
async def update_item(
    item_id: UUID = Path(..., description="Item ID"),
    request: YourUpdateRequest = Body(...),
    user: User = Depends(get_current_user)
) -> YourResponse:
    """Update item"""
    try:
        item = await service.update_item(item_id, request, user.id)
        return YourResponse.from_model(item)
    except NotFoundError:
        raise HTTPException(404, "Item not found")
    except ValidationError as e:
        raise HTTPException(400, str(e))
    except PermissionError:
        raise HTTPException(403, "Access denied")

@router.delete(
    "/{item_id}",
    status_code=204,
    summary="Delete item",
    description="Delete an item permanently"
)
async def delete_item(
    item_id: UUID = Path(..., description="Item ID"),
    user: User = Depends(get_current_user)
) -> None:
    """Delete item"""
    try:
        await service.delete_item(item_id, user.id)
    except NotFoundError:
        raise HTTPException(404, "Item not found")
    except PermissionError:
        raise HTTPException(403, "Access denied")

@router.post(
    "/batch",
    response_model=List[YourResponse],
    summary="Batch operation",
    description="Perform operations on multiple items"
)
async def batch_operation(
    request: YourBatchRequest = Body(...),
    user: User = Depends(get_current_user)
) -> List[YourResponse]:
    """Batch process items"""
    try:
        items = await service.batch_process(
            item_ids=request.item_ids,
            operation=request.operation,
            user_id=user.id
        )
        return [YourResponse.from_model(item) for item in items]
    except ValidationError as e:
        raise HTTPException(400, str(e))

# WebSocket endpoint
@router.websocket("/ws/{item_id}")
async def item_updates(
    websocket: WebSocket,
    item_id: UUID,
    token: str = Query(...)
):
    """WebSocket for real-time item updates"""
    # Verify token
    user = await verify_websocket_token(token)
    if not user:
        await websocket.close(code=1008, reason="Unauthorized")
        return
    
    await websocket.accept()
    
    try:
        # Subscribe to updates
        async for update in service.subscribe_to_updates(item_id, user.id):
            await websocket.send_json(update)
    except WebSocketDisconnect:
        await service.unsubscribe_from_updates(item_id, user.id)
```

## Schema Templates

### Request/Response Schema Template
```python
# schemas/your_schema.py
from typing import Optional, List, Any, Dict
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, Field, validator, root_validator
from enum import Enum

class StatusEnum(str, Enum):
    """Status enumeration"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    PENDING = "pending"
    ARCHIVED = "archived"

class YourBaseSchema(BaseModel):
    """Base schema with common fields"""
    name: str = Field(..., min_length=1, max_length=255, description="Item name")
    description: Optional[str] = Field(None, max_length=1000, description="Item description")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")
    
    class Config:
        schema_extra = {
            "example": {
                "name": "Example Item",
                "description": "This is an example description",
                "metadata": {"key": "value"}
            }
        }

class YourCreateRequest(YourBaseSchema):
    """Request schema for creating items"""
    tags: List[str] = Field(default_factory=list, max_items=10)
    priority: int = Field(5, ge=1, le=10, description="Priority level")
    
    @validator('tags', each_item=True)
    def validate_tag(cls, tag):
        if not tag.isalnum():
            raise ValueError("Tags must be alphanumeric")
        return tag.lower()
    
    @root_validator
    def validate_request(cls, values):
        # Custom validation logic
        if values.get('priority') > 8 and not values.get('description'):
            raise ValueError("High priority items must have a description")
        return values

class YourUpdateRequest(BaseModel):
    """Request schema for updating items"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    status: Optional[StatusEnum] = None
    tags: Optional[List[str]] = Field(None, max_items=10)
    metadata: Optional[Dict[str, Any]] = None
    
    class Config:
        schema_extra = {
            "example": {
                "name": "Updated Name",
                "status": "active"
            }
        }

class YourResponse(YourBaseSchema):
    """Response schema for items"""
    id: UUID = Field(..., description="Unique identifier")
    status: StatusEnum = Field(..., description="Current status")
    owner_id: UUID = Field(..., description="Owner user ID")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    
    # Computed fields
    age_days: int = Field(..., description="Age in days")
    is_active: bool = Field(..., description="Whether item is active")
    
    @classmethod
    def from_model(cls, model: 'YourModel') -> 'YourResponse':
        """Create response from model instance"""
        age_days = (datetime.utcnow() - model.created_at).days
        
        return cls(
            id=model.id,
            name=model.name,
            description=model.description,
            status=model.status,
            metadata=model.metadata,
            owner_id=model.owner_id,
            created_at=model.created_at,
            updated_at=model.updated_at,
            age_days=age_days,
            is_active=model.status == StatusEnum.ACTIVE
        )
    
    class Config:
        orm_mode = True
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            UUID: lambda v: str(v)
        }

class YourListResponse(BaseModel):
    """Response schema for paginated lists"""
    items: List[YourResponse] = Field(..., description="List of items")
    total: int = Field(..., ge=0, description="Total number of items")
    limit: int = Field(..., ge=1, description="Number of items per page")
    offset: int = Field(..., ge=0, description="Number of items skipped")
    has_more: bool = Field(..., description="Whether more items exist")
    
    class Config:
        schema_extra = {
            "example": {
                "items": [...],
                "total": 100,
                "limit": 20,
                "offset": 0,
                "has_more": True
            }
        }

class YourBatchRequest(BaseModel):
    """Request schema for batch operations"""
    item_ids: List[UUID] = Field(..., min_items=1, max_items=100)
    operation: str = Field(..., regex="^(activate|archive|delete)$")
    options: Dict[str, Any] = Field(default_factory=dict)
    
    @validator('item_ids')
    def validate_unique_ids(cls, ids):
        if len(ids) != len(set(ids)):
            raise ValueError("Duplicate IDs not allowed")
        return ids

# Error response schemas
class ErrorDetail(BaseModel):
    """Error detail schema"""
    field: Optional[str] = None
    message: str
    code: Optional[str] = None

class ErrorResponse(BaseModel):
    """Standard error response"""
    error: str
    details: Optional[List[ErrorDetail]] = None
    request_id: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
```

## Test Templates

### Unit Test Template
```python
# tests/unit/test_your_model.py
import pytest
from uuid import uuid4
from datetime import datetime
from models.your_model import YourModel

class TestYourModel:
    """Test cases for YourModel"""
    
    @pytest.fixture
    def sample_data(self):
        """Sample data for testing"""
        return {
            'name': 'Test Item',
            'description': 'Test Description',
            'owner_id': uuid4()
        }
    
    @pytest.mark.asyncio
    async def test_create_model(self, db_session, sample_data):
        """Test creating a new model"""
        # Create model
        model = await YourModel.create(**sample_data)
        
        # Assertions
        assert model.id is not None
        assert model.name == sample_data['name']
        assert model.description == sample_data['description']
        assert model.status == 'active'
        assert isinstance(model.created_at, datetime)
    
    @pytest.mark.asyncio
    async def test_find_by_id(self, db_session, sample_data):
        """Test finding model by ID"""
        # Create model
        created = await YourModel.create(**sample_data)
        
        # Find by ID
        found = await YourModel.find_by_id(created.id)
        
        # Assertions
        assert found is not None
        assert found.id == created.id
        assert found.name == created.name
    
    @pytest.mark.asyncio
    async def test_find_by_id_not_found(self, db_session):
        """Test finding non-existent model"""
        result = await YourModel.find_by_id(uuid4())
        assert result is None
    
    @pytest.mark.asyncio
    async def test_update_model(self, db_session, sample_data):
        """Test updating model"""
        # Create model
        model = await YourModel.create(**sample_data)
        
        # Update
        await model.update_status('inactive')
        
        # Verify
        updated = await YourModel.find_by_id(model.id)
        assert updated.status == 'inactive'
        assert updated.updated_at > model.created_at
    
    @pytest.mark.asyncio
    async def test_delete_model(self, db_session, sample_data):
        """Test deleting model"""
        # Create model
        model = await YourModel.create(**sample_data)
        
        # Delete
        await model.delete()
        
        # Verify
        found = await YourModel.find_by_id(model.id)
        assert found is None
    
    @pytest.mark.asyncio
    async def test_validation_error(self, db_session):
        """Test model validation"""
        with pytest.raises(ValidationError) as exc_info:
            await YourModel.create(name='', description='Test')
        
        assert 'name cannot be empty' in str(exc_info.value)
```

### Integration Test Template
```python
# tests/integration/test_your_api.py
import pytest
from uuid import uuid4
from httpx import AsyncClient
from fastapi import status

class TestYourAPI:
    """Integration tests for Your API endpoints"""
    
    @pytest.fixture
    def create_payload(self):
        """Sample creation payload"""
        return {
            'name': 'Test Item',
            'description': 'Test Description',
            'tags': ['test', 'example'],
            'priority': 5
        }
    
    @pytest.mark.asyncio
    async def test_create_item_success(
        self, 
        test_client: AsyncClient,
        auth_headers: dict,
        create_payload: dict
    ):
        """Test successful item creation"""
        response = await test_client.post(
            "/api/your-endpoint/",
            json=create_payload,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        
        assert data['name'] == create_payload['name']
        assert data['description'] == create_payload['description']
        assert 'id' in data
        assert 'created_at' in data
    
    @pytest.mark.asyncio
    async def test_create_item_validation_error(
        self,
        test_client: AsyncClient,
        auth_headers: dict
    ):
        """Test creation with invalid data"""
        invalid_payload = {
            'name': '',  # Empty name
            'priority': 15  # Out of range
        }
        
        response = await test_client.post(
            "/api/your-endpoint/",
            json=invalid_payload,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        error = response.json()
        assert 'error' in error
    
    @pytest.mark.asyncio
    async def test_get_item_success(
        self,
        test_client: AsyncClient,
        auth_headers: dict,
        created_item_id: UUID
    ):
        """Test getting item by ID"""
        response = await test_client.get(
            f"/api/your-endpoint/{created_item_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data['id'] == str(created_item_id)
    
    @pytest.mark.asyncio
    async def test_get_item_not_found(
        self,
        test_client: AsyncClient,
        auth_headers: dict
    ):
        """Test getting non-existent item"""
        fake_id = uuid4()
        response = await test_client.get(
            f"/api/your-endpoint/{fake_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    @pytest.mark.asyncio
    async def test_list_items_pagination(
        self,
        test_client: AsyncClient,
        auth_headers: dict
    ):
        """Test listing items with pagination"""
        response = await test_client.get(
            "/api/your-endpoint/?limit=10&offset=0",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert 'items' in data
        assert 'total' in data
        assert 'has_more' in data
        assert len(data['items']) <= 10
    
    @pytest.mark.asyncio
    async def test_unauthorized_access(self, test_client: AsyncClient):
        """Test accessing without authentication"""
        response = await test_client.get("/api/your-endpoint/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
```

## Processor Templates

### File Processor Template
```python
# processors/your_processor.py
from typing import Dict, Any, Optional
from pathlib import Path
import asyncio
from processors.base import BaseProcessor
from exceptions import ProcessingError

class YourFileProcessor(BaseProcessor):
    """Processor for handling specific file type"""
    
    # Supported formats
    SUPPORTED_FORMATS = ['.ext1', '.ext2', '.ext3']
    MIME_TYPES = ['application/your-type', 'application/x-your-type']
    
    # Processing limits
    MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB
    PROCESSING_TIMEOUT = 300  # 5 minutes
    
    async def validate_file(self, file_path: Path) -> bool:
        """Validate if file can be processed"""
        # Check file exists
        if not file_path.exists():
            raise ProcessingError("File does not exist")
        
        # Check file size
        file_size = file_path.stat().st_size
        if file_size > self.MAX_FILE_SIZE:
            raise ProcessingError(f"File too large: {file_size} bytes")
        
        # Check format
        if file_path.suffix.lower() not in self.SUPPORTED_FORMATS:
            raise ProcessingError(f"Unsupported format: {file_path.suffix}")
        
        # Check file integrity
        try:
            await self._check_file_integrity(file_path)
        except Exception as e:
            raise ProcessingError(f"File integrity check failed: {e}")
        
        return True
    
    async def extract_metadata(self, file_path: Path) -> Dict[str, Any]:
        """Extract metadata from file"""
        metadata = {
            'file_name': file_path.name,
            'file_size': file_path.stat().st_size,
            'format': file_path.suffix.lower()
        }
        
        try:
            # Extract specific metadata
            specific_metadata = await self._extract_specific_metadata(file_path)
            metadata.update(specific_metadata)
        except Exception as e:
            logger.warning(f"Failed to extract metadata: {e}")
        
        return metadata
    
    async def generate_thumbnail(
        self, 
        file_path: Path,
        output_path: Optional[Path] = None
    ) -> Path:
        """Generate thumbnail for file"""
        if output_path is None:
            output_path = file_path.with_suffix('.thumbnail.jpg')
        
        try:
            # Generate thumbnail
            await self._create_thumbnail(file_path, output_path)
            
            # Optimize thumbnail
            await self._optimize_thumbnail(output_path)
            
            return output_path
        except Exception as e:
            raise ProcessingError(f"Thumbnail generation failed: {e}")
    
    async def prepare_for_ai(self, file_path: Path) -> bytes:
        """Prepare file for AI analysis"""
        try:
            # Extract relevant content
            content = await self._extract_content(file_path)
            
            # Convert to format suitable for AI
            ai_input = await self._convert_for_ai(content)
            
            # Validate size for AI limits
            if len(ai_input) > self.AI_INPUT_LIMIT:
                ai_input = await self._reduce_ai_input(ai_input)
            
            return ai_input
        except Exception as e:
            raise ProcessingError(f"AI preparation failed: {e}")
    
    async def process(
        self,
        file_path: Path,
        upload_id: str,
        options: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """Main processing pipeline"""
        options = options or {}
        
        try:
            # Set timeout for processing
            async with asyncio.timeout(self.PROCESSING_TIMEOUT):
                # Step 1: Validate
                await self.validate_file(file_path)
                
                # Step 2: Extract metadata
                metadata = await self.extract_metadata(file_path)
                
                # Step 3: Generate thumbnail
                thumbnail_path = await self.generate_thumbnail(file_path)
                
                # Step 4: Prepare for AI
                ai_input = await self.prepare_for_ai(file_path)
                
                # Step 5: Additional processing
                if options.get('extract_text'):
                    metadata['extracted_text'] = await self._extract_text(file_path)
                
                return {
                    'metadata': metadata,
                    'thumbnail_path': str(thumbnail_path),
                    'ai_input': ai_input,
                    'processed_at': datetime.utcnow()
                }
        
        except asyncio.TimeoutError:
            raise ProcessingError(f"Processing timeout after {self.PROCESSING_TIMEOUT}s")
        except Exception as e:
            logger.error(f"Processing failed for {upload_id}: {e}")
            raise
    
    # Private helper methods
    async def _check_file_integrity(self, file_path: Path) -> None:
        """Check file integrity"""
        # Implementation specific to file type
        pass
    
    async def _extract_specific_metadata(self, file_path: Path) -> Dict[str, Any]:
        """Extract file-type specific metadata"""
        # Implementation specific to file type
        return {}
    
    async def _create_thumbnail(self, input_path: Path, output_path: Path) -> None:
        """Create thumbnail"""
        # Implementation specific to file type
        pass
    
    async def _optimize_thumbnail(self, thumbnail_path: Path) -> None:
        """Optimize thumbnail file"""
        # Compress, resize, etc.
        pass
    
    async def _extract_content(self, file_path: Path) -> Any:
        """Extract content from file"""
        # Implementation specific to file type
        pass
    
    async def _convert_for_ai(self, content: Any) -> bytes:
        """Convert content for AI processing"""
        # Implementation specific to file type
        pass
```

## Error Handling Patterns

### Custom Exception Classes
```python
# exceptions.py
from typing import Optional, Dict, Any
from uuid import UUID

class BaseError(Exception):
    """Base exception class"""
    
    def __init__(
        self,
        message: str,
        code: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        self.message = message
        self.code = code or self.__class__.__name__
        self.details = details or {}
        super().__init__(self.message)
    
    def to_dict(self) -> dict:
        """Convert exception to dictionary"""
        return {
            'error': self.message,
            'code': self.code,
            'details': self.details
        }

class ValidationError(BaseError):
    """Raised when validation fails"""
    pass

class NotFoundError(BaseError):
    """Raised when resource not found"""
    
    def __init__(self, resource_type: str, resource_id: Any):
        super().__init__(
            f"{resource_type} not found",
            details={'resource_type': resource_type, 'resource_id': str(resource_id)}
        )

class PermissionError(BaseError):
    """Raised when user lacks permission"""
    pass

class ProcessingError(BaseError):
    """Raised when processing fails"""
    
    def __init__(self, message: str, retry_able: bool = True):
        super().__init__(message)
        self.retry_able = retry_able

class QuotaExceededError(BaseError):
    """Raised when quota is exceeded"""
    
    def __init__(self, resource: str, limit: int, current: int):
        super().__init__(
            f"Quota exceeded for {resource}",
            details={'resource': resource, 'limit': limit, 'current': current}
        )

class ExternalServiceError(BaseError):
    """Raised when external service fails"""
    
    def __init__(self, service: str, message: str, status_code: Optional[int] = None):
        super().__init__(
            f"{service} error: {message}",
            details={'service': service, 'status_code': status_code}
        )
```

### Error Handler Middleware
```python
# middleware/error_handler.py
from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException
import traceback
import logging

logger = logging.getLogger(__name__)

async def error_handler_middleware(request: Request, call_next):
    """Global error handler middleware"""
    try:
        response = await call_next(request)
        return response
    except Exception as e:
        return await handle_error(e, request)

async def handle_error(error: Exception, request: Request) -> JSONResponse:
    """Handle different types of errors"""
    
    # Handle custom errors
    if isinstance(error, BaseError):
        return JSONResponse(
            status_code=get_status_code(error),
            content=error.to_dict()
        )
    
    # Handle FastAPI validation errors
    if isinstance(error, RequestValidationError):
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                'error': 'Validation error',
                'details': error.errors()
            }
        )
    
    # Handle HTTP exceptions
    if isinstance(error, HTTPException):
        return JSONResponse(
            status_code=error.status_code,
            content={'error': error.detail}
        )
    
    # Handle unexpected errors
    logger.error(
        f"Unexpected error: {error}",
        exc_info=True,
        extra={
            'request_id': request.state.request_id,
            'path': request.url.path,
            'method': request.method
        }
    )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            'error': 'Internal server error',
            'request_id': request.state.request_id
        }
    )

def get_status_code(error: BaseError) -> int:
    """Map errors to HTTP status codes"""
    error_map = {
        ValidationError: status.HTTP_400_BAD_REQUEST,
        NotFoundError: status.HTTP_404_NOT_FOUND,
        PermissionError: status.HTTP_403_FORBIDDEN,
        QuotaExceededError: status.HTTP_429_TOO_MANY_REQUESTS,
        ExternalServiceError: status.HTTP_502_BAD_GATEWAY,
        ProcessingError: status.HTTP_422_UNPROCESSABLE_ENTITY
    }
    
    return error_map.get(type(error), status.HTTP_500_INTERNAL_SERVER_ERROR)
```

## Database Patterns

### Transaction Management
```python
# database/transactions.py
from contextlib import asynccontextmanager
from typing import AsyncGenerator
import asyncpg

class TransactionManager:
    """Database transaction manager"""
    
    def __init__(self, db_pool: asyncpg.Pool):
        self.pool = db_pool
    
    @asynccontextmanager
    async def transaction(self) -> AsyncGenerator[asyncpg.Connection, None]:
        """Execute in transaction"""
        async with self.pool.acquire() as conn:
            async with conn.transaction():
                yield conn
    
    @asynccontextmanager
    async def savepoint(
        self, 
        conn: asyncpg.Connection,
        name: str
    ) -> AsyncGenerator[None, None]:
        """Create savepoint in transaction"""
        await conn.execute(f'SAVEPOINT {name}')
        try:
            yield
        except Exception:
            await conn.execute(f'ROLLBACK TO SAVEPOINT {name}')
            raise
        else:
            await conn.execute(f'RELEASE SAVEPOINT {name}')

# Usage example
async def complex_operation(user_id: UUID, items: List[dict]):
    async with transaction_manager.transaction() as conn:
        # Create user record
        user = await conn.fetchrow(
            "INSERT INTO users (id, name) VALUES ($1, $2) RETURNING *",
            user_id, items[0]['user_name']
        )
        
        # Process items with savepoints
        for i, item in enumerate(items):
            async with transaction_manager.savepoint(conn, f'item_{i}'):
                try:
                    await conn.execute(
                        "INSERT INTO items (user_id, name) VALUES ($1, $2)",
                        user_id, item['name']
                    )
                except Exception as e:
                    logger.warning(f"Failed to insert item {i}: {e}")
                    # Savepoint will rollback this item only
```

### Query Builder Pattern
```python
# database/query_builder.py
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field

@dataclass
class QueryBuilder:
    """SQL query builder"""
    
    table: str
    select_fields: List[str] = field(default_factory=lambda: ['*'])
    where_conditions: List[str] = field(default_factory=list)
    join_clauses: List[str] = field(default_factory=list)
    order_by: Optional[str] = None
    limit_value: Optional[int] = None
    offset_value: Optional[int] = None
    params: List[Any] = field(default_factory=list)
    _param_counter: int = field(default=0, init=False)
    
    def select(self, *fields: str) -> 'QueryBuilder':
        """Set fields to select"""
        self.select_fields = list(fields)
        return self
    
    def where(self, condition: str, *values: Any) -> 'QueryBuilder':
        """Add WHERE condition"""
        placeholders = []
        for value in values:
            self._param_counter += 1
            placeholders.append(f'${self._param_counter}')
            self.params.append(value)
        
        formatted_condition = condition.format(*placeholders)
        self.where_conditions.append(formatted_condition)
        return self
    
    def join(self, join_type: str, table: str, on: str) -> 'QueryBuilder':
        """Add JOIN clause"""
        self.join_clauses.append(f"{join_type} JOIN {table} ON {on}")
        return self
    
    def order_by(self, field: str, direction: str = 'ASC') -> 'QueryBuilder':
        """Set ORDER BY clause"""
        self.order_by = f"{field} {direction}"
        return self
    
    def limit(self, value: int) -> 'QueryBuilder':
        """Set LIMIT"""
        self.limit_value = value
        return self
    
    def offset(self, value: int) -> 'QueryBuilder':
        """Set OFFSET"""
        self.offset_value = value
        return self
    
    def build(self) -> tuple[str, List[Any]]:
        """Build final query"""
        parts = [
            f"SELECT {', '.join(self.select_fields)}",
            f"FROM {self.table}"
        ]
        
        parts.extend(self.join_clauses)
        
        if self.where_conditions:
            parts.append(f"WHERE {' AND '.join(self.where_conditions)}")
        
        if self.order_by:
            parts.append(f"ORDER BY {self.order_by}")
        
        if self.limit_value:
            parts.append(f"LIMIT {self.limit_value}")
        
        if self.offset_value:
            parts.append(f"OFFSET {self.offset_value}")
        
        query = ' '.join(parts)
        return query, self.params

# Usage example
query, params = (
    QueryBuilder('uploads')
    .select('id', 'filename', 'created_at')
    .join('INNER', 'users', 'uploads.user_id = users.id')
    .where('uploads.status = {}', 'completed')
    .where('uploads.created_at > {}', datetime(2025, 1, 1))
    .order_by('created_at', 'DESC')
    .limit(10)
    .build()
)
```

## Caching Patterns

### Cache Decorator
```python
# cache/decorators.py
import hashlib
import json
from functools import wraps
from typing import Optional, Callable, Any
import redis.asyncio as redis

class CacheManager:
    """Redis cache manager"""
    
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
    
    def cache_result(
        self,
        key_prefix: str,
        ttl: int = 300,
        key_func: Optional[Callable] = None
    ):
        """Decorator to cache function results"""
        def decorator(func):
            @wraps(func)
            async def wrapper(*args, **kwargs):
                # Generate cache key
                if key_func:
                    cache_key = f"{key_prefix}:{key_func(*args, **kwargs)}"
                else:
                    # Default key generation
                    key_data = f"{args}:{kwargs}"
                    key_hash = hashlib.md5(key_data.encode()).hexdigest()
                    cache_key = f"{key_prefix}:{key_hash}"
                
                # Try to get from cache
                cached = await self.redis.get(cache_key)
                if cached:
                    return json.loads(cached)
                
                # Execute function
                result = await func(*args, **kwargs)
                
                # Cache result
                await self.redis.setex(
                    cache_key,
                    ttl,
                    json.dumps(result, default=str)
                )
                
                return result
            
            # Add cache management methods
            wrapper.invalidate = lambda *args, **kwargs: self._invalidate(
                key_prefix, key_func, *args, **kwargs
            )
            
            return wrapper
        return decorator
    
    async def _invalidate(
        self,
        key_prefix: str,
        key_func: Optional[Callable],
        *args,
        **kwargs
    ):
        """Invalidate cached result"""
        if key_func:
            cache_key = f"{key_prefix}:{key_func(*args, **kwargs)}"
            await self.redis.delete(cache_key)
        else:
            # Invalidate all keys with prefix
            async for key in self.redis.scan_iter(f"{key_prefix}:*"):
                await self.redis.delete(key)

# Usage example
cache_manager = CacheManager(redis_client)

@cache_manager.cache_result(
    "user_stats",
    ttl=600,
    key_func=lambda user_id: str(user_id)
)
async def get_user_statistics(user_id: UUID) -> dict:
    # Expensive operation
    return await calculate_statistics(user_id)

# Invalidate cache
await get_user_statistics.invalidate(user_id)
```

### Cache Aside Pattern
```python
# cache/patterns.py
class CacheAsidePattern:
    """Implementation of cache-aside pattern"""
    
    def __init__(self, cache: redis.Redis, db):
        self.cache = cache
        self.db = db
    
    async def get(
        self,
        key: str,
        fetch_func: Callable,
        ttl: int = 300,
        refresh_on_miss: bool = True
    ) -> Any:
        """Get with cache-aside pattern"""
        # Try cache first
        cached = await self.cache.get(key)
        if cached:
            return json.loads(cached)
        
        if not refresh_on_miss:
            return None
        
        # Fetch from source
        data = await fetch_func()
        
        # Update cache
        if data is not None:
            await self.cache.setex(
                key,
                ttl,
                json.dumps(data, default=str)
            )
        
        return data
    
    async def set(self, key: str, value: Any, ttl: int = 300):
        """Set value in cache"""
        await self.cache.setex(
            key,
            ttl,
            json.dumps(value, default=str)
        )
    
    async def delete(self, key: str):
        """Delete from cache"""
        await self.cache.delete(key)
    
    async def refresh(self, key: str, fetch_func: Callable, ttl: int = 300):
        """Force refresh cache"""
        data = await fetch_func()
        await self.set(key, data, ttl)
        return data
```

## Authentication Patterns

### JWT Authentication
```python
# auth/jwt_handler.py
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

class JWTHandler:
    """JWT authentication handler"""
    
    def __init__(
        self,
        secret_key: str,
        algorithm: str = "HS256",
        access_token_expire_minutes: int = 30,
        refresh_token_expire_days: int = 7
    ):
        self.secret_key = secret_key
        self.algorithm = algorithm
        self.access_token_expire = timedelta(minutes=access_token_expire_minutes)
        self.refresh_token_expire = timedelta(days=refresh_token_expire_days)
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        self.security = HTTPBearer()
    
    def create_access_token(
        self,
        subject: str,
        additional_claims: Dict[str, Any] = None
    ) -> str:
        """Create access token"""
        claims = {
            "sub": subject,
            "exp": datetime.utcnow() + self.access_token_expire,
            "iat": datetime.utcnow(),
            "type": "access"
        }
        
        if additional_claims:
            claims.update(additional_claims)
        
        return jwt.encode(claims, self.secret_key, algorithm=self.algorithm)
    
    def create_refresh_token(self, subject: str) -> str:
        """Create refresh token"""
        claims = {
            "sub": subject,
            "exp": datetime.utcnow() + self.refresh_token_expire,
            "iat": datetime.utcnow(),
            "type": "refresh"
        }
        
        return jwt.encode(claims, self.secret_key, algorithm=self.algorithm)
    
    def decode_token(self, token: str) -> Dict[str, Any]:
        """Decode and validate token"""
        try:
            payload = jwt.decode(
                token,
                self.secret_key,
                algorithms=[self.algorithm]
            )
            return payload
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify password"""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def hash_password(self, password: str) -> str:
        """Hash password"""
        return self.pwd_context.hash(password)
    
    async def get_current_user(
        self,
        credentials: HTTPAuthorizationCredentials = Depends(security)
    ) -> str:
        """Get current user from token"""
        token = credentials.credentials
        payload = self.decode_token(token)
        
        if payload.get("type") != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        return payload.get("sub")

# Usage in dependency
jwt_handler = JWTHandler(secret_key=settings.secret_key)

async def get_current_user(
    token: str = Depends(jwt_handler.get_current_user)
) -> User:
    user = await User.find_by_id(UUID(token))
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    return user
```

### API Key Authentication
```python
# auth/api_key.py
from fastapi import Security, HTTPException, status
from fastapi.security import APIKeyHeader
import secrets

class APIKeyAuth:
    """API Key authentication"""
    
    def __init__(self, header_name: str = "X-API-Key"):
        self.header_name = header_name
        self.api_key_header = APIKeyHeader(name=header_name)
    
    async def verify_api_key(
        self,
        api_key: str = Security(api_key_header)
    ) -> str:
        """Verify API key"""
        # Look up API key in database
        key_record = await APIKey.find_by_key(api_key)
        
        if not key_record or not key_record.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid API key"
            )
        
        # Update last used
        await key_record.update_last_used()
        
        return key_record.user_id
    
    @staticmethod
    def generate_api_key() -> str:
        """Generate new API key"""
        return f"sk_{secrets.token_urlsafe(32)}"

# Usage
api_key_auth = APIKeyAuth()

@router.get("/protected")
async def protected_endpoint(
    user_id: str = Depends(api_key_auth.verify_api_key)
):
    return {"user_id": user_id}
```

## Notes

- Always follow the project's coding standards
- Add comprehensive error handling
- Include logging for debugging
- Write tests for all new code
- Document complex logic
- Consider performance implications
- Use type hints consistently
- Follow security best practices