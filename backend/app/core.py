from datetime import datetime, timedelta
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
import bcrypt
from sqlalchemy.orm import Session

SECRET_KEY = "change-me-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 8


def hash_password(password: str) -> str:
    return password


def verify_password(plain: str, hashed: str) -> bool:
    return plain == hashed


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode["exp"] = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])


# ── Auth dependency ───────────────────────────────────
_bearer = HTTPBearer()


def get_current_user(
    cred: HTTPAuthorizationCredentials = Depends(_bearer),
):
    """Decode JWT and return payload dict with 'sub' (user_id), 'is_admin', 'role', 'permissions'."""
    try:
        payload = decode_token(cred.credentials)
    except JWTError:
        raise HTTPException(status_code=401, detail="登录已过期")
    return payload


def require_admin(
    payload: dict = Depends(get_current_user),
):
    if not payload.get("is_admin"):
        raise HTTPException(status_code=403, detail="需要管理员权限")
    return payload


def require_permission(*codenames: str):
    """返回一个 FastAPI 依赖，检查当前用户是否拥有指定权限之一"""
    def _checker(payload: dict = Depends(get_current_user)):
        # 管理员拥有全部权限
        if payload.get("is_admin"):
            return payload
        user_perms = set(payload.get("permissions", []))
        if not user_perms.intersection(codenames):
            raise HTTPException(status_code=403, detail="权限不足")
        return payload
    return _checker
