"""Pydantic schemas for token data."""
from pydantic import BaseModel


class Token(BaseModel):
    """Token response schema."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Token payload data."""

    user_id: int
    exp: Optional[int] = None


class TokenRefresh(BaseModel):
    """Token refresh request schema."""

    refresh_token: str


class Message(BaseModel):
    """Generic message response schema."""

    message: str
