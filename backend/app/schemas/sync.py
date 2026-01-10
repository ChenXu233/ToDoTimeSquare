"""Pydantic schemas for sync data."""
from datetime import datetime
from typing import Optional, List, Dict, Any

from pydantic import BaseModel, Field


class SyncRecord(BaseModel):
    """同步记录数据模型"""

    id: str = Field(..., description="记录唯一标识")
    entity_type: str = Field(..., description="实体类型: todo | focus_record | habit | habit_log | tag | tag_relation")
    entity_id: str = Field(..., description="实体ID")
    operation: str = Field(..., description="操作类型: create | update | delete")
    data: Optional[Dict[str, Any]] = Field(None, description="实体数据")
    timestamp: int = Field(..., description="变更时间戳（毫秒）")
    version: int = Field(..., description="版本号")

    class Config:
        from_attributes = True


class ConflictInfo(BaseModel):
    """冲突信息"""

    entity_type: str = Field(..., description="实体类型")
    entity_id: str = Field(..., description="实体ID")
    local_version: int = Field(..., description="本地版本号")
    server_version: int = Field(..., description="服务器版本号")
    local_data: Dict[str, Any] = Field(..., description="本地数据")
    server_data: Dict[str, Any] = Field(..., description="服务器数据")
    local_timestamp: int = Field(..., description="本地最后修改时间")
    server_timestamp: int = Field(..., description="服务器最后修改时间")


class SyncRequest(BaseModel):
    """同步请求"""

    client_timestamp: int = Field(..., description="客户端最后同步时间戳")
    records: List[SyncRecord] = Field(default_factory=list, description="客户端变更记录列表")
    user_id: str = Field(..., description="用户ID")
    device_id: str = Field(..., description="设备ID")


class SyncResponse(BaseModel):
    """同步响应"""

    success: bool = Field(..., description="是否成功")
    server_timestamp: int = Field(..., description="服务器当前时间戳")
    client_applied: int = Field(..., description="客户端变更应用数量")
    server_records: List[SyncRecord] = Field(default_factory=list, description="服务器端变更记录")
    conflicts: List[ConflictInfo] = Field(default_factory=list, description="冲突列表")
    message: Optional[str] = Field(None, description="状态消息")


class ConflictResolveRequest(BaseModel):
    """冲突解决请求"""

    entity_type: str = Field(..., description="实体类型")
    entity_id: str = Field(..., description="实体ID")
    keep_local: bool = Field(..., description="是否保留本地版本")
    local_data: Optional[Dict[str, Any]] = Field(None, description="本地数据（保留本地时使用")


class SyncStatusResponse(BaseModel):
    """同步状态响应"""

    last_sync_timestamp: Optional[int] = Field(None, description="最后同步时间戳")
    pending_changes: int = Field(default=0, description="待同步变更数量")
    conflicts_count: int = Field(default=0, description="冲突数量")
    sync_enabled: bool = Field(default=True, description="同步是否启用")


class SyncLog(BaseModel):
    """同步日志"""

    id: int = Field(..., description="日志ID")
    user_id: str = Field(..., description="用户ID")
    device_id: str = Field(..., description="设备ID")
    sync_timestamp: int = Field(..., description="同步时间戳")
    records_sent: int = Field(default=0, description="发送记录数")
    records_received: int = Field(default=0, description="接收记录数")
    conflicts_count: int = Field(default=0, description="冲突数量")
    status: str = Field(default="success", description="状态: success | error")
    created_at: datetime = Field(..., description="创建时间")

    class Config:
        from_attributes = True
