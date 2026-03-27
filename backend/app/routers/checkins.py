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


@router.post("/", response_model=CheckInOut)
def create_checkin(
    body: CheckInCreate,
    db: Session = Depends(get_db),
    payload: dict = Depends(get_current_user),
):
    # user_id must match the authenticated user (admins may submit on behalf)
    caller_id = int(payload["sub"])
    target_id = body.user_id if body.user_id is not None else caller_id
    if not payload.get("is_admin") and target_id != caller_id:
        raise HTTPException(status_code=403, detail="无权为他人打卡")

    user = db.query(User).filter(User.id == target_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    record = CheckIn(
        user_id=target_id,
        lat=body.lat,
        lng=body.lng,
        status=body.status,
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

    # Non-admins can only see their own records
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
