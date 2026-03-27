from pydantic import BaseModel
from typing import Optional
from app.schemas.role import RoleBrief


class UserCreate(BaseModel):
    username: str
    full_name: str
    password: str
    is_admin: bool = False
    role_id: Optional[int] = None


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    is_active: Optional[bool] = None
    is_admin: Optional[bool] = None
    role_id: Optional[int] = None
    face_enrolled: Optional[bool] = None
    require_location: Optional[bool] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    location_radius: Optional[float] = None
    require_time: Optional[bool] = None
    checkin_time_start: Optional[str] = None
    checkin_time_end: Optional[str] = None
    require_face: Optional[bool] = None


class UserOut(BaseModel):
    id: int
    username: str
    full_name: str
    is_active: bool
    is_admin: bool
    face_enrolled: bool
    role_id: Optional[int]
    role: Optional[RoleBrief] = None
    require_location: bool
    location_lat: Optional[float]
    location_lng: Optional[float]
    location_radius: Optional[float]
    require_time: bool
    checkin_time_start: Optional[str]
    checkin_time_end: Optional[str]
    require_face: bool

    model_config = {"from_attributes": True}


class PasswordReset(BaseModel):
    new_password: str
