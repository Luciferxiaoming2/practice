from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.checkin import CheckIn
from app.models.role import Role
from app.schemas.user import UserCreate, UserOut, UserUpdate, PasswordReset
from app.core import hash_password, get_current_user, require_admin

router = APIRouter(prefix="/users", tags=["users"])


def _sync_is_admin(user: User, db: Session):
    """根据角色同步 is_admin 标志（兼容旧逻辑）"""
    if user.role_id and not user.role:
        # relationship 未加载时手动查询
        user.role = db.query(Role).filter(Role.id == user.role_id).first()
    if user.role:
        # 内置"管理员"角色视为管理员
        user.is_admin = user.role.name == "管理员"
    else:
        user.is_admin = False


@router.get("/", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db), payload: dict = Depends(get_current_user)):
    if payload.get("is_admin"):
        return db.query(User).all()
    caller_id = int(payload["sub"])
    return db.query(User).filter(User.id == caller_id).all()


@router.post("/", response_model=UserOut)
def create_user(body: UserCreate, db: Session = Depends(get_db), _=Depends(require_admin)):
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="账号已存在")
    # 确定角色
    role_id = body.role_id
    if role_id is not None:
        # 显式指定了 role_id，验证存在
        if not db.query(Role).filter(Role.id == role_id).first():
            raise HTTPException(status_code=400, detail="角色不存在")
    else:
        # 兼容旧接口：根据 is_admin 分配角色
        role_name = "管理员" if body.is_admin else "普通用户"
        role = db.query(Role).filter(Role.name == role_name).first()
        role_id = role.id if role else None
    
    # 验证部门是否存在
    if body.department_id is not None:
        from app.models.department import Department
        dept = db.query(Department).filter(Department.id == body.department_id).first()
        if not dept:
            raise HTTPException(status_code=400, detail="部门不存在")
    
    user = User(
        username=body.username,
        full_name=body.full_name,
        hashed_password=hash_password(body.password),
        role_id=role_id,
        department_id=body.department_id,
    )
    _sync_is_admin(user, db)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/{user_id}", response_model=UserOut)
def get_user(user_id: int, db: Session = Depends(get_db), payload: dict = Depends(get_current_user)):
    caller_id = int(payload["sub"])
    if not payload.get("is_admin") and caller_id != user_id:
        raise HTTPException(status_code=403, detail="无权查看他人信息")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return user


@router.patch("/{user_id}", response_model=UserOut)
def update_user(user_id: int, body: UserUpdate, db: Session = Depends(get_db), payload: dict = Depends(get_current_user)):
    caller_id = int(payload["sub"])
    if not payload.get("is_admin") and caller_id != user_id:
        raise HTTPException(status_code=403, detail="无权修改他人信息")
    # 非管理员不可修改角色相关字段
    if not payload.get("is_admin"):
        if body.is_admin is not None or body.role_id is not None:
            raise HTTPException(status_code=403, detail="无权修改角色")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    update_data = body.model_dump(exclude_unset=True)
    # 如果设置了 role_id，验证角色存在（允许 None 表示移除角色）
    if "role_id" in update_data and update_data["role_id"] is not None:
        role = db.query(Role).filter(Role.id == update_data["role_id"]).first()
        if not role:
            raise HTTPException(status_code=400, detail="角色不存在")

    for field, value in update_data.items():
        setattr(user, field, value)

    # 同步 is_admin
    _sync_is_admin(user, db)
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
