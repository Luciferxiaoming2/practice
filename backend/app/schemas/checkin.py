from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class CheckInCreate(BaseModel):
    user_id: Optional[int] = None   # if None, taken from JWT
    lat: Optional[float] = None
    lng: Optional[float] = None
    status: str = "ok"
    type: str = "sign_in"


class CheckInOut(BaseModel):
    id: int
    user_id: int
    user_name: Optional[str] = None
    timestamp: datetime
    lat: Optional[float]
    lng: Optional[float]
    address: Optional[str] = None
    status: str
    type: str = "sign_in"

    model_config = {"from_attributes": True}
