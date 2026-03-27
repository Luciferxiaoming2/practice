from pydantic import BaseModel
from typing import Optional


class PermissionOut(BaseModel):
    id: int
    codename: str
    name: str

    model_config = {"from_attributes": True}


class RoleCreate(BaseModel):
    name: str
    description: str = ""
    permission_ids: list[int] = []


class RoleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    permission_ids: Optional[list[int]] = None


class RoleOut(BaseModel):
    id: int
    name: str
    description: str
    is_system: bool
    permissions: list[PermissionOut]

    model_config = {"from_attributes": True}


class RoleBrief(BaseModel):
    """角色简要信息，用于用户列表等场景"""
    id: int
    name: str

    model_config = {"from_attributes": True}
