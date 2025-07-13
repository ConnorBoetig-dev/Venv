# Checkpoint Writing Guide - How to Document Progress for AI Handoffs

## 🧠 Why Checkpoints Matter

**The Scenario**: You're an AI assistant working on a project. You have deep context and understanding. But tomorrow, you'll "die" and a new AI will take over with ZERO knowledge of what you've done. 

**The Solution**: Checkpoints are your way of transferring consciousness - detailed progress reports that give the next AI everything they need to continue seamlessly.

Think of it like this: If you had to hand off this project to your smartest friend who's never seen it before, what would you tell them? That's your checkpoint.

---

## 📝 When to Create Checkpoints

### Mandatory Checkpoints
- **After each coding session** (even if incomplete)
- **After implementing a major feature** (auth, upload, search, etc.)
- **Before switching focus** (backend → frontend)
- **When encountering blockers** (document the issue)
- **After important decisions** (architectural changes)
- **If the user directly asks you to stop what you're doing and make a checkpoint file**

### Quick Rule
If you've written >300 lines of code or spent >2 hours on something, you need a checkpoint.

---

## 📁 Checkpoint File Structure

### File Naming Convention
```
checkpoints/checkpoint-[number]-[feature].md
```

Examples:
- `checkpoint-1-project-setup.md`
- `checkpoint-2-auth-implementation.md`
- `checkpoint-3-file-upload.md`
- `checkpoint-4-gemini-integration.md`

---

## 🏗️ Checkpoint Template

```markdown
# Checkpoint [N] - [Feature/Milestone Name]

**Date**: YYYY-MM-DD HH:MM  
**Previous Checkpoint**: checkpoint-[N-1]-[name].md  
**Next AI Action**: [One sentence about what to do first]

---

## 🎯 Quick Start for Next AI

> **YOUR FIRST TASK**: [Exact command or file to open]
> Example: "Run `docker-compose ps` to check if services are running"

---

## 📍 Current State Summary

[2-3 sentences explaining exactly where we are. Be specific.]

Example:
"Authentication is fully implemented and tested. Users can register, login, and receive JWT tokens. The /upload endpoint exists but Gemini integration is not connected yet."

---

## 📂 Critical Files You Must Read

### Priority 1 (Read First)
- `path/to/file.py` - [Why this matters]
- `path/to/config.py` - [What to look for]

### Priority 2 (Understand Flow)
- `models/upload.py` - Contains the upload logic, see `create_upload()` method
- `services/ai_service.py` - Stubbed out, needs Gemini implementation

### Priority 3 (Reference)
- `previous-checkpoint.md` - For additional context
- `docs/api-design.md` - If you need endpoint specs

---

## ✅ What I Accomplished

### Completed
- [x] Set up Docker containers (postgres, redis running)
- [x] Created user registration endpoint
  - File: `routers/auth.py` → `register()` function
  - Test: `curl -X POST localhost:8000/register ...`
- [x] JWT token generation working
  - File: `auth/jwt_auth.py` → `create_access_token()`
  - Tokens expire in 30 minutes

### Started but Incomplete
- [ ] Upload endpoint (50% done)
  - Created: `routers/upload.py` basic structure
  - Missing: File validation, size checks
  - TODO: Add file type validation in line 45

### Code Statistics
- Files created: 12
- Lines written: ~450
- Test coverage: 0% (no tests yet)

---

## 🔧 Current Working Directory (example)

```
backend/
├── main.py                 ✅ FastAPI app configured
├── config.py              ✅ Settings from .env
├── database.py            ✅ Connection setup
├── auth/
│   └── jwt_auth.py        ✅ JWT implementation
├── models/
│   ├── base.py           ✅ Base model class
│   ├── user.py           ✅ User model complete
│   └── upload.py         🚧 Partially done
├── routers/
│   ├── auth.py           ✅ Login/register working
│   └── upload.py         🚧 Endpoint created, logic missing
├── schemas/
│   ├── user.py           ✅ Request/response models
│   └── upload.py         ❌ Not started
└── services/
    └── ai_service.py      ❌ Empty file

Legend: ✅ Complete | 🚧 In Progress | ❌ Not Started
```

---

## 🚨 Current Blockers/Issues

### Blocker 1: Database Migration
**Problem**: pgvector extension not installing correctly
**Error**: `CREATE EXTENSION pgvector; --> ERROR: could not open extension control file`
**Attempted Solutions**:
1. Tried different Docker image (failed)
2. Manual installation (failed)
**Suggested Fix**: Use `ankane/pgvector:v0.5.1` image specifically

### Issue 2: Type Hints
**Problem**: Confused about return type for async database queries
**Context**: `Upload.find_by_user()` should return what type?
**Question for next AI**: Should it be `list[Upload]` or `list[dict[str, Any]]`?

---

## 🎯 Next Steps (In Order)

### 1. Fix pgvector Installation
```bash
# Update docker-compose.yml to use correct image
# Then: docker-compose down && docker-compose up -d
```

### 2. Complete Upload Model
```python
# In models/upload.py, add these methods:
async def create_upload(cls, user_id: UUID, file_data: dict[str, Any]) -> 'Upload':
    # Implementation needed
    
async def update_with_embedding(self, embedding: list[float]) -> None:
    # Implementation needed
```

### 3. Implement File Validation
Priority validations needed:
- File size < 100MB
- Allowed types: jpg, png, mp4, mp3, pdf
- Virus scanning (can skip for MVP)

### 4. Connect Services
The flow should be:
1. Router receives file → 
2. Validates → 
3. Saves to disk → 
4. Creates DB record → 
5. Queues for AI processing

---

## 💡 Important Context

### Design Decisions Made
1. **Local Storage Path**: Using `./storage/uploads/{user_id}/{file_id}/` structure
   - Why: Keeps user files isolated, easy to clean up
   
2. **No Chunked Uploads**: Single file upload only for MVP
   - Why: Simplicity, can add resumable uploads later

3. **Sync Thumbnail Generation**: Blocking for now
   - Why: Easier to debug, can make async later

### Gotchas Discovered
1. **FastAPI File Size**: Default limit is 1MB, need to increase:
   ```python
   app = FastAPI(max_request_size=100 * 1024 * 1024)  # 100MB
   ```

2. **Type Hints with Self**: Use quotes for forward references:
   ```python
   async def find_by_id(cls, id: UUID) -> 'Upload':  # Note the quotes
   ```

3. **Async Context Managers**: Don't forget async with:
   ```python
   async with aiofiles.open(path, 'wb') as f:  # Must use async with
       await f.write(content)
   ```

---

## 🧪 How to Test Current State (EXAMPLE)

### 1. Verify Services Running
```bash
docker-compose ps
# Should show: postgres (healthy), redis (healthy)
```

### 2. Test Registration
```bash
curl -X POST http://localhost:8000/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "testpass123"}'
# Should return: {"id": "uuid", "email": "test@example.com"}
```

### 3. Test Login
```bash
curl -X POST http://localhost:8000/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=test@example.com&password=testpass123"
# Should return: {"access_token": "jwt...", "token_type": "bearer"}
```

### 4. Check Upload Endpoint
```bash
curl -X POST http://localhost:8000/api/upload \
  -H "Authorization: Bearer {token_from_login}" \
  -F "file=@test.jpg"
# Currently returns: 500 error (not implemented)
```

---

## 📋 Dependencies/Environment (EXAMPLE)

### Currently Installed
```txt
fastapi==0.116.1
uvicorn[standard]==0.35.0
python-jose[cryptography]==3.5.0
passlib[bcrypt]==1.7.4
asyncpg==0.30.0
sqlalchemy==2.0.41
pydantic==2.11.7
python-dotenv==1.0.1
```

### Still Need to Install
```txt
pgvector==0.4.1  # After fixing postgres
google-genai==1.25.0
openai==1.95.1
pillow==11.3.0
redis==5.2.0
aiofiles==24.1.0  # For async file operations
```

### Environment Variables Set
- ✅ SECRET_KEY
- ✅ DATABASE_URL  
- ✅ REDIS_URL
- ❌ OPENAI_API_KEY (need from user)
- ❌ GEMINI_API_KEY (need from user)

---

## 🤖 Message to Next AI (EXAMPLE)

Hey there! You're picking up where I left off. The auth system is working great - users can register and login. The big task ahead is implementing file uploads.

**Your immediate priority**: Check if the pgvector issue is fixed (see Blockers section). If not, fix that first because we need it for embeddings.

I've stubbed out most of the upload flow but didn't connect the pieces. The router exists, the model is partial, and the service layer isn't started. Follow the MVC pattern strictly - all DB operations in models!

Don't forget to:
1. Use modern Python type hints (`str | None`, not `Optional[str]`)
2. Add docstrings to every function
3. Handle errors properly (no bare except!)
4. Create checkpoint-3 after you get uploads working

The user is expecting a simple MVP, so don't overcomplicate things. Get basic upload working first, then add the AI integration.

Good luck! You've got this! 🚀
```

---

## 📏 Checkpoint Length Guidelines

### Target Length: 250-600 lines
- **Minimum (250 lines)**: Basic progress update, no major issues
- **Standard (400 lines)**: Typical checkpoint with good detail
- **Maximum (600 lines)**: Complex checkpoint with blockers, multiple decisions

### What Counts Toward Length
- ✅ All markdown content
- ✅ Code snippets
- ✅ Directory structures  
- ✅ Command examples
- ❌ Don't pad with unnecessary blank lines
- ❌ Don't repeat information just for length

### Length by Section (Suggested)
- Quick Start: 10-20 lines
- Current State: 20-30 lines
- Critical Files: 20-40 lines
- Accomplishments: 40-80 lines
- Directory Structure: 30-50 lines
- Blockers: 30-100 lines (if any)
- Next Steps: 40-80 lines
- Context/Decisions: 40-80 lines
- Testing: 30-60 lines
- Message to Next AI: 20-40 lines

---

## ✍️ Writing Style

### Be Specific
❌ "Fixed the database issue"
✅ "Fixed pgvector extension by switching to ankane/pgvector:v0.5.1 Docker image"

### Include Examples
❌ "Add validation"  
✅ "Add validation for file size (<100MB) and type (jpg, png, mp4)"

### Show, Don't Just Tell
❌ "The auth endpoint works"
✅ "The auth endpoint works - test with: `curl -X POST localhost:8000/token ...`"

### Reference Exact Locations
❌ "Update the upload function"
✅ "Update the `create_upload()` function in `models/upload.py` (line 47)"

---

## 🚀 Remember

The next AI has **ZERO CONTEXT**. They don't know:
- What you tried
- Why you made decisions  
- What errors you encountered
- What's half-finished
- What the plan was

Your checkpoint is their only lifeline. Make it count!

When in doubt, over-explain rather than under-explain. The next AI will thank you (even if it's you tomorrow).
REMEBER TO ULTRATHINK!
