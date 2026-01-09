"""Sync routes for data synchronization."""
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.sync import (
    SyncRequest,
    SyncResponse,
    SyncStatusResponse,
    ConflictResolveRequest,
)
from app.services.sync_service import SyncService
from app.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("", response_model=SyncResponse)
async def sync_data(
    request: SyncRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    执行增量同步

    客户端发送自上次同步以来的变更，服务器接收并返回服务器端变更和冲突列表。
    """
    # 验证用户ID匹配
    if request.user_id != str(current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User ID mismatch",
        )

    sync_service = SyncService(db)
    return await sync_service.handle_sync(request)


@router.post("/resolve")
async def resolve_conflict(
    request: ConflictResolveRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    解决同步冲突

    用户选择保留本地版本或服务器版本。
    """
    success = await SyncService(db).resolve_conflict(
        user_id=str(current_user.id),
        request=request,
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to resolve conflict",
        )

    return {"message": "Conflict resolved successfully"}


@router.get("/status", response_model=SyncStatusResponse)
async def get_sync_status(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    获取同步状态
    """
    sync_service = SyncService(db)
    status_data = await sync_service.get_sync_status(str(current_user.id))

    return SyncStatusResponse(**status_data)


@router.get("/logs")
async def get_sync_logs(
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    获取同步日志
    """
    sync_service = SyncService(db)
    logs = await sync_service.get_sync_logs(str(current_user.id), limit)

    return {
        "logs": [
            {
                "id": log.id,
                "device_id": log.device_id,
                "sync_timestamp": log.sync_timestamp,
                "records_sent": log.records_sent,
                "records_received": log.records_received,
                "conflicts_count": log.conflicts_count,
                "status": log.status,
                "created_at": log.created_at.isoformat(),
            }
            for log in logs
        ]
    }
