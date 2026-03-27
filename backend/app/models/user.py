from sqlalchemy import Boolean, Column, Float, Integer, String
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=False)       # True after first login setup
    is_admin = Column(Boolean, default=False)
    face_enrolled = Column(Boolean, default=False)

    # Check-in rules
    require_location = Column(Boolean, default=False)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    location_radius = Column(Float, nullable=True)   # metres

    require_time = Column(Boolean, default=False)
    checkin_time_start = Column(String, nullable=True)  # "HH:MM"
    checkin_time_end = Column(String, nullable=True)    # "HH:MM"

    require_face = Column(Boolean, default=True)
