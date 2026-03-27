from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.role import Role, Permission
from app.models.user import User
from app.schemas.role import RoleCreate, RoleOut, RoleUpdate, PermissionOut
from app.core import require_admin

router = APIRouter(prefix="/roles", tags=["roles"])


# ── Permissions ───────────────────────────────────────
@router.get("/permissions", response_model=list[PermissionOut])
def list_permissions(db: Session = Depends(get_db), _=Depends(require_admin)):
    return db.query(Permission).order_by(Permission.codename).all()


# ── Roles CRUD ────────────────────────────────────────
@router.get("/", response_model=list[RoleOut])
def list_roles(db: Session = Depends(get_db), _=Depends(require_admin)):
    return db.query(Role).order_by(Role.id).all()


@router.get("/{role_id}", response_model=RoleOut)
def get_role(role_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    role = db.query(Role).filter(Role.id == role_id).first()
    if not role:
        raise HTTPException(status_code=404, detail="角色不存在")
    return role


@router.post("/", response_model=RoleOut, status_code=201)
def create_role(body: RoleCreate, db: Session = Depends(get_db), _=Depends(require_admin)):
    if db.query(Role).filter(Role.name == body.name).first():
        raise HTTPException(status_code=400, detail="角色名称已存在")
    role = Role(name=body.name, description=body.description)
    if body.permission_ids:
        perms = db.query(Permission).filter(Permission.id.in_(body.permission_ids)).all()
        role.permissions = perms
    db.add(role)
    db.commit()
    db.refresh(role)
    return role


@router.patch("/{role_id}", response_model=RoleOut)
def update_role(role_id: int, body: RoleUpdate, db: Session = Depends(get_db), _=Depends(require_admin)):
    role = db.query(Role).filter(Role.id == role_id).first()
    if not role:
        raise HTTPException(status_code=404, detail="角色不存在")
    if body.name is not None:
        existing = db.query(Role).filter(Role.name == body.name, Role.id != role_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="角色名称已存在")
        role.name = body.name
    if body.description is not None:
        role.description = body.description
    if body.permission_ids is not None:
        perms = db.query(Permission).filter(Permission.id.in_(body.permission_ids)).all()
        role.permissions = perms
    db.commit()
    db.refresh(role)
    return role


@router.delete("/{role_id}")
def delete_role(role_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    role = db.query(Role).filter(Role.id == role_id).first()
    if not role:
        raise HTTPException(status_code=404, detail="角色不存在")
    if role.is_system:
        raise HTTPException(status_code=400, detail="系统内置角色不可删除")
    # 将该角色下的用户角色置空
    db.query(User).filter(User.role_id == role_id).update({"role_id": None})
    db.delete(role)
    db.commit()
    return {"detail": "角色已删除"}


# ── 角色成员管理 ──────────────────────────────────────
@router.get("/{role_id}/users")
def list_role_users(role_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    role = db.query(Role).filter(Role.id == role_id).first()
    if not role:
        raise HTTPException(status_code=404, detail="角色不存在")
    users = db.query(User).filter(User.role_id == role_id).all()
    return [{"id": u.id, "username": u.username, "full_name": u.full_name} for u in users]
