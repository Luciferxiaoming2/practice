from sqlalchemy import Boolean, Column, Float, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=False)       # True after first login setup
    is_admin = Column(Boolean, default=False)         # 保留兼容，由 role 推导
    face_enrolled = Column(Boolean, default=False)
    face_embedding = Column(Text, nullable=True)      # JSON: list[float]

    # RBAC 角色
    role_id = Column(Integer, ForeignKey("roles.id"), nullable=True)
    role = relationship("Role", back_populates="users", lazy="joined")

    # Check-in rules
    require_location = Column(Boolean, default=False)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    location_radius = Column(Float, nullable=True)   # metres

    require_time = Column(Boolean, default=False)
    checkin_time_start = Column(String, nullable=True)   # 签到开始 "HH:MM"
    checkin_time_end = Column(String, nullable=True)     # 签到结束 "HH:MM"
    sign_out_time_start = Column(String, nullable=True)  # 签退开始 "HH:MM"
    sign_out_time_end = Column(String, nullable=True)    # 签退结束 "HH:MM"

    require_face = Column(Boolean, default=True)

    require_sign_in = Column(Boolean, default=True)
    require_sign_out = Column(Boolean, default=False)

    # 部门
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=True)
    department = relationship("Department", back_populates="users", lazy="joined")
