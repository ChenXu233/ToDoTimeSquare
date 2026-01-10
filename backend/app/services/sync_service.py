"""Sync service for handling incremental synchronization."""
import json
import logging
from datetime import datetime, timezone
from typing import List, Dict, Any

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.entities import SyncEntity
from app.models.sync import SyncLog
from app.schemas.sync import SyncRequest, SyncResponse, SyncRecord, ConflictInfo, ConflictResolveRequest

logger = logging.getLogger(__name__)


def _ensure_aware(dt: datetime) -> datetime:
    """确保 datetime 是 aware（带时区），如果是 naive 则假定为 UTC"""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def _utc_now():
    """获取当前 UTC 时间"""
    return datetime.now(timezone.utc)


class SyncService:
    """Service for handling data synchronization between client and server."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def handle_sync(self, request: SyncRequest) -> SyncResponse:
        """
        处理同步请求

        流程：
        1. 应用客户端的变更（存储到 sync_entities 表）
        2. 查询自上次同步以来的服务器端变更
        3. 检测冲突
        4. 返回结果
        """
        server_timestamp = int(_utc_now().timestamp() * 1000)

        try:
            # 1. 应用客户端变更
            client_applied = await self._apply_client_records(request.user_id, request.records)

            # 2. 查询服务器端变更（返回给客户端）
            server_records = await self._get_server_changes(request.user_id, request.client_timestamp)

            # 3. 检测冲突（检查是否有同一实体被双方修改）
            conflicts = await self._detect_conflicts(request.user_id, request.records, request.client_timestamp)

            # 4. 记录同步日志
            await self._log_sync(
                user_id=request.user_id,
                device_id=request.device_id,
                sync_timestamp=server_timestamp,
                records_sent=len(request.records),
                records_received=len(server_records),
                conflicts_count=len(conflicts),
                status="success" if len(conflicts) == 0 else "partial",
            )

            return SyncResponse(
                success=True,
                server_timestamp=server_timestamp,
                client_applied=client_applied,
                server_records=server_records,
                conflicts=conflicts,
                message=None,
            )

        except Exception as e:
            logger.error(f"Sync error: {e}", exc_info=True)
            await self._log_sync(
                user_id=request.user_id,
                device_id=request.device_id,
                sync_timestamp=server_timestamp,
                records_sent=len(request.records),
                records_received=0,
                conflicts_count=0,
                status="error",
            )

            return SyncResponse(
                success=False,
                server_timestamp=server_timestamp,
                client_applied=0,
                server_records=[],
                conflicts=[],
                message=f"Sync failed: {str(e)}",
            )

    async def resolve_conflict(
        self, user_id: str, request: ConflictResolveRequest
    ) -> bool:
        """解决冲突"""
        try:
            # 获取现有实体
            result = await self.db.execute(
                select(SyncEntity).where(
                    and_(
                        SyncEntity.user_id == user_id,
                        SyncEntity.entity_type == request.entity_type,
                        SyncEntity.entity_id == request.entity_id,
                    )
                )
            )
            entity = result.scalar_one_or_none()

            if request.keep_local and request.local_data:
                # 保留本地版本：更新服务器
                if entity:
                    entity.data = json.dumps(request.local_data)
                    entity.version += 1
                    entity.is_deleted = False
                else:
                    # 新建
                    entity = SyncEntity(
                        user_id=user_id,
                        entity_type=request.entity_type,
                        entity_id=request.entity_id,
                        data=json.dumps(request.local_data),
                        version=1,
                        is_deleted=False,
                    )
                    self.db.add(entity)
            else:
                # 保留服务器版本：标记为删除，让客户端用服务器数据覆盖本地
                if entity:
                    entity.is_deleted = True
                    entity.updated_at = _utc_now()

            await self.db.commit()
            return True

        except Exception as e:
            logger.error(f"Resolve conflict error: {e}", exc_info=True)
            await self.db.rollback()
            return False

    async def _apply_client_records(
        self, user_id: str, records: List[SyncRecord]
    ) -> int:
        """应用客户端变更记录 - 存储到数据库"""
        applied_count = 0

        for record in records:
            try:
                # 获取现有实体
                result = await self.db.execute(
                    select(SyncEntity).where(
                        and_(
                            SyncEntity.user_id == user_id,
                            SyncEntity.entity_type == record.entity_type,
                            SyncEntity.entity_id == record.entity_id,
                        )
                    )
                )
                existing = result.scalar_one_or_none()

                if record.operation == "create":
                    if existing:
                        # 已存在则更新
                        existing.data = json.dumps(record.data) if record.data else "{}"
                        existing.version = record.version
                        existing.is_deleted = False
                    else:
                        # 新建
                        entity = SyncEntity(
                            user_id=user_id,
                            entity_type=record.entity_type,
                            entity_id=record.entity_id,
                            data=json.dumps(record.data) if record.data else "{}",
                            version=record.version,
                            is_deleted=False,
                        )
                        self.db.add(entity)

                elif record.operation == "update":
                    if existing:
                        existing.data = json.dumps(record.data) if record.data else "{}"
                        existing.version = record.version
                        existing.is_deleted = False
                    else:
                        # 可能是离线创建的，直接新建
                        entity = SyncEntity(
                            user_id=user_id,
                            entity_type=record.entity_type,
                            entity_id=record.entity_id,
                            data=json.dumps(record.data) if record.data else "{}",
                            version=record.version,
                            is_deleted=False,
                        )
                        self.db.add(entity)

                elif record.operation == "delete":
                    if existing:
                        existing.is_deleted = True
                    # 如果不存在，说明已经删了，不用处理

                await self.db.commit()
                applied_count += 1

            except Exception as e:
                logger.error(f"Failed to apply record {record.id}: {e}")
                await self.db.rollback()

        return applied_count

    async def _get_server_changes(
        self, user_id: str, since_timestamp: int
    ) -> List[SyncRecord]:
        """获取服务器端自上次同步以来的变更"""
        records = []
        server_time = int(_utc_now().timestamp() * 1000)

        since_dt = datetime.fromtimestamp(since_timestamp / 1000, tz=timezone.utc)

        # 查询自上次同步以来的变更
        result = await self.db.execute(
            select(SyncEntity).where(
                and_(
                    SyncEntity.user_id == user_id,
                    SyncEntity.updated_at > since_dt,
                )
            )
        )
        entities = result.scalars().all()

        for entity in entities:
            if entity.is_deleted:
                operation = "delete"
                data = {}
            else:
                operation = "update"
                data = json.loads(entity.data) if entity.data else {}

            records.append(SyncRecord(
                id=f"{entity.entity_type}_{entity.entity_id}",
                entity_type=entity.entity_type,
                entity_id=entity.entity_id,
                operation=operation,
                data=data,
                timestamp=int(entity.updated_at.timestamp() * 1000) if entity.updated_at else server_time,
                version=entity.version,
            ))

        return records

    async def _detect_conflicts(
        self,
        user_id: str,
        client_records: List[SyncRecord],
        client_timestamp: int,
    ) -> List[ConflictInfo]:
        """检测冲突

        冲突定义：客户端和服务器都修改了同一实体
        """
        conflicts = []
        since_dt = datetime.fromtimestamp(client_timestamp / 1000, tz=timezone.utc)

        for record in client_records:
            if record.operation == "create":
                continue  # 新建不算冲突

            # 查询服务器上同一实体的状态
            result = await self.db.execute(
                select(SyncEntity).where(
                    and_(
                        SyncEntity.user_id == user_id,
                        SyncEntity.entity_type == record.entity_type,
                        SyncEntity.entity_id == record.entity_id,
                    )
                )
            )
            server_entity = result.scalar_one_or_none()

            if server_entity:
                # 服务器上存在该实体
                if server_entity.is_deleted and record.operation == "update":
                    # 服务器已删除，客户端有更新 -> 冲突
                    conflicts.append(ConflictInfo(
                        entity_type=record.entity_type,
                        entity_id=record.entity_id,
                        local_version=record.version,
                        server_version=server_entity.version,
                        local_data=record.data or {},
                        server_data={},
                        local_timestamp=record.timestamp,
                        server_timestamp=int(server_entity.updated_at.timestamp() * 1000) if server_entity.updated_at else 0,
                    ))
                elif (not server_entity.is_deleted and
                      record.operation == "update" and
                      _ensure_aware(server_entity.updated_at) > since_dt and
                      record.timestamp > int(server_entity.updated_at.timestamp() * 1000)):
                    # 双方都有更新，时间都晚于上次同步 -> 冲突
                    server_data = json.loads(server_entity.data) if server_entity.data else {}
                    if record.data != server_data:
                        conflicts.append(ConflictInfo(
                            entity_type=record.entity_type,
                            entity_id=record.entity_id,
                            local_version=record.version,
                            server_version=server_entity.version,
                            local_data=record.data or {},
                            server_data=server_data,
                            local_timestamp=record.timestamp,
                            server_timestamp=int(server_entity.updated_at.timestamp() * 1000),
                        ))

        return conflicts

    async def _log_sync(
        self,
        user_id: str,
        device_id: str,
        sync_timestamp: int,
        records_sent: int,
        records_received: int,
        conflicts_count: int,
        status: str,
    ) -> None:
        """记录同步日志"""
        try:
            sync_log = SyncLog(
                user_id=user_id,
                device_id=device_id,
                sync_timestamp=sync_timestamp,
                records_sent=records_sent,
                records_received=records_received,
                conflicts_count=conflicts_count,
                status=status,
            )
            self.db.add(sync_log)
            await self.db.commit()
        except Exception as e:
            logger.error(f"Failed to log sync: {e}")
            await self.db.rollback()

    async def get_sync_status(self, user_id: str) -> Dict[str, Any]:
        """获取同步状态"""
        result = await self.db.execute(
            select(SyncLog)
            .where(SyncLog.user_id == user_id)
            .order_by(SyncLog.created_at.desc())
            .limit(1)
        )
        last_sync_log = result.scalar_one_or_none()

        count_result = await self.db.execute(
            select(SyncEntity).where(
                and_(SyncEntity.user_id == user_id, SyncEntity.is_deleted == False)
            )
        )
        entity_count = len(count_result.scalars().all())

        return {
            "last_sync_timestamp": last_sync_log.sync_timestamp if last_sync_log else None,
            "pending_changes": 0,
            "conflicts_count": 0,
            "sync_enabled": True,
            "entity_count": entity_count,
        }

    async def get_sync_logs(
        self, user_id: str, limit: int = 20
    ) -> List[SyncLog]:
        """获取同步日志"""
        result = await self.db.execute(
            select(SyncLog)
            .where(SyncLog.user_id == user_id)
            .order_by(SyncLog.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())
