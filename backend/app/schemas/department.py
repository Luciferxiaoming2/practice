from pydantic import BaseModel
from typing import Optional


class DepartmentCreate(BaseModel):
    name: str
    description: Optional[str] = None


class DepartmentUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None


class DepartmentOut(BaseModel):
    id: int
    name: str
    description: Optional[str] = None

    model_config = {"from_attributes": True}


class BatchRulesBody(BaseModel):
    require_location: Optional[bool] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    location_radius: Optional[float] = None
    require_time: Optional[bool] = None
    checkin_time_start: Optional[str] = None
    checkin_time_end: Optional[str] = None
    sign_out_time_start: Optional[str] = None
    sign_out_time_end: Optional[str] = None
    require_face: Optional[bool] = None
    require_sign_in: Optional[bool] = None
    require_sign_out: Optional[bool] = None
