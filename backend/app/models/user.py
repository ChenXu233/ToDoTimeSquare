"""User database model."""
from datetime import datetime, timezone

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


def _utc_now():
    """获取当前 UTC 时间"""
    return datetime.now(timezone.utc)


class User(Base):
    """User model for storing account information."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)
    email: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(default=_utc_now, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        default=_utc_now, onupdate=_utc_now, nullable=False
    )

    def __repr__(self) -> str:
        return f"<User(id={self.id}, username='{self.username}', email='{self.email}')>"
