from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.role import Role
from app.schemas.auth import LoginRequest, Token, RegisterRequest
from app.schemas.user import UserOut
from app.core import verify_password, create_access_token, hash_password

router = APIRouter(prefix="/auth", tags=["auth"])


def _build_token_data(user: User) -> dict:
    """构建 JWT payload，包含角色和权限信息"""
    data = {
        "sub": str(user.id),
        "is_admin": user.is_admin,
        "role": user.role.name if user.role else None,
        "role_id": user.role_id,
        "permissions": [p.codename for p in user.role.permissions] if user.role else [],
    }
    return data


@router.post("/login", response_model=Token)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == body.username).first()
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="账号或密码错误")
    token = create_access_token(_build_token_data(user))
    return {"access_token": token, "token_type": "bearer"}


@router.post("/register", response_model=UserOut, status_code=201)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == body.username).first():
        raise HTTPException(status_code=400, detail="账号已存在")
    # 新注册用户默认分配"普通用户"角色
    default_role = db.query(Role).filter(Role.name == "普通用户").first()
    user = User(
        username=body.username,
        full_name=body.full_name,
        hashed_password=hash_password(body.password),
        is_admin=False,
        role_id=default_role.id if default_role else None,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
