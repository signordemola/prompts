# FastAPI Advanced Patterns

## Preventing N+1 Queries (SQLAlchemy Async)

```python
from sqlalchemy.orm import selectinload

# ❌ N+1: fetches each order's items separately
orders = await session.execute(select(Order))

# ✅ Eager load: single query for orders + items
orders = await session.execute(
    select(Order).options(selectinload(Order.items))
)
```

Use `selectinload` for collections (one-to-many), `joinedload` for single references (many-to-one).

## Alembic Migration Workflow

```bash
# Generate migration from model changes
uv run alembic revision --autogenerate -m "add orders table"

# Apply migrations
uv run alembic upgrade head

# Rollback one step
uv run alembic downgrade -1

# Show current state
uv run alembic current
```

```python
# alembic/env.py — async config
from sqlalchemy.ext.asyncio import create_async_engine

connectable = create_async_engine(DATABASE_URL)

async def run_async_migrations():
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

asyncio.run(run_async_migrations())
```

## Structured Logging (structlog)

```python
import structlog

structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
)

logger = structlog.get_logger()

@router.get("/orders/{order_id}")
async def get_order(order_id: int):
    logger.info("fetching_order", order_id=order_id)
    # ...
```

## Prometheus Metrics

```python
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()
Instrumentator().instrument(app).expose(app, endpoint="/metrics")
```

## Multi-Stage Dockerfile

```dockerfile
# Stage 1: Build
FROM python:3.12-slim AS builder
RUN pip install uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --no-dev --frozen

# Stage 2: Run
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv .venv
COPY app/ app/
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Middleware Stack

```python
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
import time, uuid

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request ID + Timing
class RequestMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        start = time.perf_counter()
        response = await call_next(request)
        duration = time.perf_counter() - start
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time"] = f"{duration:.3f}s"
        return response

app.add_middleware(RequestMiddleware)
```

## Error Handling

```python
from fastapi import HTTPException
from fastapi.responses import JSONResponse

class AppError(Exception):
    def __init__(self, status_code: int, detail: str, code: str):
        self.status_code = status_code
        self.detail = detail
        self.code = code

@app.exception_handler(AppError)
async def app_error_handler(request, exc: AppError):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.code, "detail": exc.detail},
    )
```
