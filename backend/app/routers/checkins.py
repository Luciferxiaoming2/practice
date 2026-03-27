import math
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date, datetime, time

from app.database import get_db
from app.models.checkin import CheckIn
from app.models.user import User
from app.schemas.checkin import CheckInCreate, CheckInOut
from app.core import get_current_user, require_admin

router = APIRouter(prefix="/checkins", tags=["checkins"])


def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """计算两点间距离（米）"""
    R = 6371000
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lng / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _check_status(user: User, lat: Optional[float], lng: Optional[float]) -> str:
    """根据用户打卡规则自动判定打卡状态"""
    # 位置校验
    if user.require_location:
        if lat is None or lng is None:
            return "location_fail"
        if user.location_lat is not None and user.location_lng is not None and user.location_radius is not None:
            dist = _haversine(lat, lng, user.location_lat, user.location_lng)
            if dist > user.location_radius:
                return "location_fail"

    # 时间校验
    if user.require_time:
        now = datetime.now().strftime("%H:%M")
        start = user.checkin_time_start
        end = user.checkin_time_end
        if start and end:
            if start <= end:
                # 正常时间窗：如 08:00 ~ 18:00
                if not (start <= now <= end):
                    return "time_fail"
            else:
                # 跨午夜时间窗：如 22:00 ~ 06:00
                if not (now >= start or now <= end):
                    return "time_fail"

    return "ok"


@router.post("/", response_model=CheckInOut)
def create_checkin(
    body: CheckInCreate,
    db: Session = Depends(get_db),
    payload: dict = Depends(get_current_user),
):
    caller_id = int(payload["sub"])
    target_id = body.user_id if body.user_id is not None else caller_id
    if not payload.get("is_admin") and target_id != caller_id:
        raise HTTPException(status_code=403, detail="无权为他人打卡")

    user = db.query(User).filter(User.id == target_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    # 自动判定打卡状态（客户端传的 status 作为参考，服务端重新校验）
    status = _check_status(user, body.lat, body.lng)

    record = CheckIn(
        user_id=target_id,
        lat=body.lat,
        lng=body.lng,
        status=status,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.get("/", response_model=list[CheckInOut])
def list_checkins(
    user_id: Optional[int] = Query(None),
    date_from: Optional[str] = Query(None, description="YYYY-MM-DD"),
    date_to: Optional[str] = Query(None, description="YYYY-MM-DD"),
    db: Session = Depends(get_db),
    payload: dict = Depends(get_current_user),
):
    q = db.query(CheckIn)

    caller_id = int(payload["sub"])
    if not payload.get("is_admin"):
        q = q.filter(CheckIn.user_id == caller_id)
    elif user_id is not None:
        q = q.filter(CheckIn.user_id == user_id)

    if date_from:
        d = date.fromisoformat(date_from)
        q = q.filter(CheckIn.timestamp >= datetime.combine(d, time.min))

    if date_to:
        d = date.fromisoformat(date_to)
        q = q.filter(CheckIn.timestamp <= datetime.combine(d, time.max))

    return q.order_by(CheckIn.timestamp.desc()).all()
