from sqlalchemy import Column, Integer, String, Table, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.database import Base

# 角色-权限 多对多关联表
role_permissions = Table(
    "role_permissions",
    Base.metadata,
    Column("role_id", Integer, ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
    Column("permission_id", Integer, ForeignKey("permissions.id", ondelete="CASCADE"), primary_key=True),
)


class Permission(Base):
    __tablename__ = "permissions"

    id = Column(Integer, primary_key=True, index=True)
    codename = Column(String, unique=True, nullable=False, index=True)  # e.g. "user.create"
    name = Column(String, nullable=False)                                # e.g. "创建用户"

    roles = relationship("Role", secondary=role_permissions, back_populates="permissions")


class Role(Base):
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False, index=True)       # e.g. "管理员"
    description = Column(String, default="")
    is_system = Column(Boolean, default=False)  # 系统内置角色不可删除

    permissions = relationship("Permission", secondary=role_permissions, back_populates="roles", lazy="joined")
    users = relationship("User", back_populates="role")
