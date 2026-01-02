"""FastAPI application main entry point."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db
from app.routers import auth, users


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    # Startup
    await init_db()
    yield
    # Shutdown


# Create FastAPI application
app = FastAPI(
    title="Todo Time Square Auth API",
    description="User authentication API for Todo Time Square",
    version="1.0.0",
    lifespan=lifespan,
)

# Configure CORS for local testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for local testing
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(users.router)


@app.get("/", tags=["health"])
async def root():
    """Health check endpoint."""
    return {"status": "ok", "message": "Todo Time Square Auth API"}


@app.get("/health", tags=["health"])
async def health_check():
    """Detailed health check endpoint."""
    return {
        "status": "healthy",
        "api_version": "1.0.0",
        "jwt_algorithm": settings.algorithm,
        "token_expire_minutes": settings.access_token_expire_minutes,
    }
