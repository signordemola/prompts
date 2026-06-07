---
name: fastapi
description: >
  FastAPI production patterns. ACTIVATE when: building a FastAPI backend,
  creating routers/services/repositories, setting up SQLAlchemy async,
  Pydantic v2 schemas, Alembic migrations, background tasks, or testing.
---

# FastAPI Framework Skill

## When to Use
- Building or modifying a FastAPI backend
- Database work with SQLAlchemy 2.0 async
- Pydantic v2 schemas, validation, settings
- Application lifespan (startup/shutdown resources)
- Background tasks (ARQ/Celery)
- Testing FastAPI endpoints

## Project Structure (Domain-Driven)

```
project-root/
├── alembic/                         # Database migrations
│   ├── versions/
│   └── env.py                       # Async engine config
├── app/
│   ├── __init__.py
│   ├── main.py                      # FastAPI app factory
│   ├── core/                        # Global config, security, deps
│   │   ├── config.py                # Pydantic Settings
│   │   ├── database.py              # Engine, session factory
│   │   ├── security.py              # JWT, hashing
│   │   └── deps.py                  # Shared dependencies (get_db, get_current_user)
│   ├── auth/                        # Domain: Authentication
│   │   ├── models.py                # SQLAlchemy models
│   │   ├── schemas.py               # Pydantic v2 request/response
│   │   ├── service.py               # Business logic
│   │   ├── repository.py            # Data access
│   │   └── router.py                # API endpoints
│   ├── users/                       # Domain: Users
│   ├── orders/                      # Domain: Orders
│   └── ...
├── tests/
│   ├── conftest.py                  # Fixtures, async client
│   ├── test_auth.py
│   └── ...
├── pyproject.toml                   # uv/poetry, ruff, pyright config
└── .env
```

**Rule:** One package per domain. Each domain owns its models, schemas, service, repository, and router.

## Database (SQLAlchemy 2.0 Async)

```python
# app/core/database.py
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

DATABASE_URL = "postgresql+asyncpg://user:pass@localhost:5432/db"

engine = create_async_engine(DATABASE_URL, pool_size=20, max_overflow=10)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

# Dependency
async def get_db():
    async with async_session() as session:
        yield session
```

## Pydantic v2 Schemas

```python
from pydantic import BaseModel, EmailStr, field_validator, computed_field
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    name: str

    @field_validator("name")
    @classmethod
    def name_not_empty(cls, v: str) -> str:
        if len(v.strip()) < 2:
            raise ValueError("Name must be at least 2 characters")
        return v.strip()

class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    created_at: datetime

    @computed_field
    @property
    def display_name(self) -> str:
        return self.name.title()

    model_config = {"from_attributes": True}
```

## Lifespan (Startup/Shutdown)

Use `lifespan` to initialise and clean up shared resources:

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    pool = await create_pool()
    app.state.pool = pool
    yield
    await pool.close()

app = FastAPI(lifespan=lifespan)
```

## Background Tasks

Built-in `BackgroundTasks` is fire-and-forget only (email, logging):

```python
from fastapi import BackgroundTasks

@router.post("/bookings")
async def create_booking(data: BookingCreate, bg: BackgroundTasks):
    booking = await service.create(data)
    bg.add_task(send_confirmation_email, booking)
    return booking
```

For heavy or reliable work (retries, persistence), use Celery or ARQ.

## Repository Pattern

```python
# app/users/repository.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from .models import User

class UserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, user_id: int) -> User | None:
        result = await self.session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self.session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def create(self, user: User) -> User:
        self.session.add(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user
```

## Service Layer

```python
# app/users/service.py
from fastapi import HTTPException, status

class UserService:
    def __init__(self, repository: UserRepository):
        self.repository = repository

    async def get_user(self, user_id: int) -> User:
        user = await self.repository.get_by_id(user_id)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return user
```

## Dependency Injection Chain

```python
# app/core/deps.py
from typing import Annotated
from fastapi import Depends

def get_user_repo(db: AsyncSession = Depends(get_db)) -> UserRepository:
    return UserRepository(db)

def get_user_service(repo: UserRepository = Depends(get_user_repo)) -> UserService:
    return UserService(repo)

# Type aliases for clean signatures
UserServiceDep = Annotated[UserService, Depends(get_user_service)]
CurrentUserDep = Annotated[User, Depends(get_current_user)]
```

## Router

```python
# app/users/router.py
from fastapi import APIRouter

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/{user_id}")
async def get_user(user_id: int, service: UserServiceDep) -> UserResponse:
    user = await service.get_user(user_id)
    return UserResponse.model_validate(user)
```

If the function returns ORM objects or dictionaries and you want FastAPI to filter/serialize with a Pydantic model, use `response_model` and annotate the Python return type as `Any` or the actual internal type:

```python
from typing import Any

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, service: UserServiceDep) -> Any:
    return await service.get_user(user_id)
```

## Settings (pydantic-settings)

```python
# app/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import SecretStr

class Settings(BaseSettings):
    database_url: str
    jwt_secret: SecretStr
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 30
    debug: bool = False

    model_config = SettingsConfigDict(env_file=".env", env_prefix="APP_")

settings = Settings()
```

## Auth (JWT)

```python
# app/core/security.py
from jose import jwt, JWTError
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode["exp"] = datetime.utcnow() + timedelta(minutes=settings.jwt_expire_minutes)
    return jwt.encode(to_encode, settings.jwt_secret.get_secret_value(), algorithm=settings.jwt_algorithm)

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    try:
        payload = jwt.decode(token, settings.jwt_secret.get_secret_value(), algorithms=[settings.jwt_algorithm])
        user_id: int = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    # fetch user...
```

## Testing

```python
# tests/conftest.py
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.fixture
async def async_client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client

# tests/test_users.py
@pytest.mark.asyncio
async def test_get_user(async_client: AsyncClient):
    response = await async_client.get("/users/1")
    assert response.status_code == 200
    assert response.json()["name"] == "Jane"

# Mock dependencies
def test_with_mocked_db():
    app.dependency_overrides[get_db] = lambda: mock_session
    # test...
    app.dependency_overrides.clear()
```

## Quality Gate

```bash
uv run ruff check --fix .
uv run ruff format .
uv run python -m compileall -q app
uv run pyright app
```

## References
- `references/fastapi-patterns.md` — N+1 prevention, Alembic workflow, Dockerfile, structlog

## NEVER
- ❌ Mix sync and async code (blocks the event loop)
- ❌ Use `TestClient` for async endpoints (use `httpx.AsyncClient`)
- ❌ Skip `expire_on_commit=False` (lazy-loading errors)
- ❌ Hardcode secrets (use `pydantic-settings` + `SecretStr`)
- ❌ Modify DB schema without Alembic migrations
- ❌ Annotate a route as returning an ORM/internal object and expect FastAPI to infer the public schema; use a Pydantic return type or `response_model`
