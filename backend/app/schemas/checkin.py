from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class CheckInCreate(BaseModel):
    user_id: Optional[int] = None   # if None, taken from JWT
    lat: Optional[float] = None
    lng: Optional[float] = None
    status: str = "ok"


class CheckInOut(BaseModel):
    id: int
    user_id: int
    timestamp: datetime
    lat: Optional[float]
    lng: Optional[float]
    status: str

    model_config = {"from_attributes": True}
