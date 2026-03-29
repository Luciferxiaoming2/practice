import math
import logging
import httpx
from fastapi import APIRouter, Body, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date, datetime, time

from app.database import get_db
from app.models.checkin import CheckIn
from app.models.user import User
from app.schemas.checkin import CheckInCreate, CheckInOut
from app.core import get_current_user, require_admin

router = APIRouter(prefix="/checkins", tags=["checkins"])

AMAP_KEY = "7a42d2010d005df07a5438a2d1b59cd7"


def _reverse_geocode(lat: float, lng: float) -> str | None:
    """调用高德逆地理编码 API，将经纬度转为地址"""
    try:
        resp = httpx.get(
            "https://restapi.amap.com/v3/geocode/regeo",
            params={"location": f"{lng},{lat}", "key": AMAP_KEY, "radius": 200},
            timeout=5,
        )
        data = resp.json()
        if data.get("status") == "1" and data.get("regeocode"):
            addr = data["regeocode"].get("formatted_address", "")
            return addr if addr else None
    except Exception:
        pass
    return None


def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """计算两点间距离（米）"""
    R = 6371000
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lng / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _minutes_of(hhmm: str) -> int:
    """将 HH:MM 转为当日分钟数"""
    h, m = hhmm.split(":")
    return int(h) * 60 + int(m)


def _check_status(user: User, lat: Optional[float], lng: Optional[float], checkin_type: str = "sign_in") -> str:
    """根据用户打卡规则自动判定打卡状态"""
    # 位置校验
    if user.require_location:
        if lat is None or lng is None:
            return "location_fail"
        if user.location_lat is not None and user.location_lng is not None and user.location_radius is not None:
            # 自动修正 lat/lng 填反的情况（纬度范围 -90~90，经度范围 -180~180）
            cfg_lat = user.location_lat
            cfg_lng = user.location_lng
            if abs(cfg_lat) > 90 and abs(cfg_lng) <= 90:
                cfg_lat, cfg_lng = cfg_lng, cfg_lat
                logging.getLogger("checkin").warning(
                    f"[location_check] user={user.id} lat/lng appear swapped, auto-corrected"
                )
            dist = _haversine(lat, lng, cfg_lat, cfg_lng)
            logging.getLogger("checkin").info(
                f"[location_check] user={user.id} dist={dist:.1f}m radius={user.location_radius}m "
                f"user_pos=({lat},{lng}) config_pos=({cfg_lat},{cfg_lng})"
            )
            if dist > user.location_radius:
                return "location_fail"

    # 时间校验：签到和签退使用不同的时间窗口，允许提前1小时
    if user.require_time:
        now_str = datetime.now().strftime("%H:%M")
        now_min = _minutes_of(now_str)
        if checkin_type == "sign_out":
            start = user.sign_out_time_start
            end = user.sign_out_time_end
        else:
            start = user.checkin_time_start
            end = user.checkin_time_end
        if start and end:
            s_min = _minutes_of(start)
            e_min = _minutes_of(end)
            early_min = s_min - 60  # 允许提前1小时

            if s_min <= e_min:
                # 正常时间窗
                if now_min < early_min:
                    return "time_early"  # 早到（提前超过1小时）
                elif now_min < s_min:
                    return "ok"  # 提前1小时内，允许
                elif now_min > e_min:
                    return "time_late"   # 迟到
            else:
                # 跨午夜
                if not (now_min >= early_min or now_min <= e_min):
                    if now_min < early_min:
                        return "time_early"
                    else:
                        return "time_late"

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
    status = _check_status(user, body.lat, body.lng, checkin_type=body.type)

    # 逆地理编码获取地址
    address = None
    if body.lat is not None and body.lng is not None:
        address = _reverse_geocode(body.lat, body.lng)

    record = CheckIn(
        user_id=target_id,
        lat=body.lat,
        lng=body.lng,
        address=address,
        status=status,
        type=body.type,
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

    try:
        if date_from:
            d = date.fromisoformat(date_from)
            q = q.filter(CheckIn.timestamp >= datetime.combine(d, time.min))

        if date_to:
            d = date.fromisoformat(date_to)
            q = q.filter(CheckIn.timestamp <= datetime.combine(d, time.max))
    except ValueError:
        raise HTTPException(status_code=400, detail="日期格式错误，请使用 YYYY-MM-DD")

    records = q.order_by(CheckIn.timestamp.desc()).all()

    # 查询用户姓名并附加到结果
    user_ids = {r.user_id for r in records}
    name_map = {u.id: u.full_name for u in db.query(User).filter(User.id.in_(user_ids)).all()} if user_ids else {}

    return [
        CheckInOut(
            id=r.id,
            user_id=r.user_id,
            user_name=name_map.get(r.user_id, ""),
            timestamp=r.timestamp,
            lat=r.lat,
            lng=r.lng,
            address=r.address,
            status=r.status,
            type=getattr(r, 'type', 'sign_in'),
        )
        for r in records
    ]


@router.delete("/{checkin_id}", status_code=204)
def delete_checkin(
    checkin_id: int,
    db: Session = Depends(get_db),
    payload: dict = Depends(require_admin),
):
    record = db.query(CheckIn).filter(CheckIn.id == checkin_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="打卡记录不存在")
    db.delete(record)
    db.commit()


@router.post("/batch-delete", status_code=204)
def batch_delete_checkins(
    ids: list[int] = Body(..., embed=True),
    db: Session = Depends(get_db),
    payload: dict = Depends(require_admin),
):
    """批量删除打卡记录（管理员）"""
    count = db.query(CheckIn).filter(CheckIn.id.in_(ids)).delete(synchronize_session=False)
    db.commit()
    if count == 0:
        raise HTTPException(status_code=404, detail="未找到匹配的记录")
