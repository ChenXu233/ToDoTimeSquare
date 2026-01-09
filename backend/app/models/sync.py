"""Sync log database model."""
from datetime import datetime, timezone

from sqlalchemy import String, Integer, DateTime
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


def _utc_now():
    """获取当前 UTC 时间"""
    return datetime.now(timezone.utc)


class SyncLog(Base):
    """Sync log model for recording sync history."""

    __tablename__ = "sync_logs"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    device_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    sync_timestamp: Mapped[int] = mapped_column(Integer, nullable=False)
    records_sent: Mapped[int] = mapped_column(Integer, default=0)
    records_received: Mapped[int] = mapped_column(Integer, default=0)
    conflicts_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(20), default="success")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_utc_now, nullable=False)

    def __repr__(self) -> str:
        return f"<SyncLog(id={self.id}, user_id='{self.user_id}', status='{self.status}')>"
