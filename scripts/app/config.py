"""Application configuration settings."""
import os
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # JWT Settings
    secret_key: str = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 15  # 15 minutes
    refresh_token_expire_days: int = 7  # 7 days

    # Database Settings
    database_path: Path = Path(__file__).parent.parent.parent / "todo_time_square.db"

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
