from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.checkin import CheckIn
from app.schemas.user import UserCreate, UserOut, UserUpdate, PasswordReset
from app.core import hash_password, get_current_user, require_admin

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db), _=Depends(get_current_user)):
    return db.query(User).all()


@router.post("/", response_model=UserOut)
def create_user(body: UserCreate, db: Session = Depends(get_db), _=Depends(require_admin)):
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="账号已存在")
    user = User(
        username=body.username,
        full_name=body.full_name,
        hashed_password=hash_password(body.password),
        is_admin=body.is_admin,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/{user_id}", response_model=UserOut)
def get_user(user_id: int, db: Session = Depends(get_db), _=Depends(get_current_user)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return user


@router.patch("/{user_id}", response_model=UserOut)
def update_user(user_id: int, body: UserUpdate, db: Session = Depends(get_db), payload: dict = Depends(get_current_user)):
    caller_id = int(payload["sub"])
    if not payload.get("is_admin") and caller_id != user_id:
        raise HTTPException(status_code=403, detail="无权修改他人信息")
    # 非管理员不可修改角色字段
    if not payload.get("is_admin") and body.is_admin is not None:
        raise HTTPException(status_code=403, detail="无权修改角色")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return user


@router.delete("/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db), payload: dict = Depends(require_admin)):
    caller_id = int(payload["sub"])
    if user_id == caller_id:
        raise HTTPException(status_code=400, detail="不能删除自己的账户")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    db.query(CheckIn).filter(CheckIn.user_id == user_id).delete()
    db.delete(user)
    db.commit()
    return {"detail": "用户已删除"}


@router.post("/{user_id}/reset-password")
def reset_password(user_id: int, body: PasswordReset, db: Session = Depends(get_db), payload: dict = Depends(get_current_user)):
    caller_id = int(payload["sub"])
    if not payload.get("is_admin") and caller_id != user_id:
        raise HTTPException(status_code=403, detail="无权重置他人密码")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    user.hashed_password = hash_password(body.new_password)
    db.commit()
    return {"detail": "密码已重置"}


@router.post("/{user_id}/reset-face")
def reset_face(user_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    user.face_enrolled = False
    user.is_active = False
    db.commit()
    return {"detail": "人脸数据已重置，账户需重新激活"}
