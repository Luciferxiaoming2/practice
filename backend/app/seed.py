"""初始化种子数据：默认权限、角色和部门"""
from sqlalchemy import text, inspect
from sqlalchemy.orm import Session
from app.models.role import Role, Permission
from app.models.user import User
from app.models.department import Department

# 系统预置权限
DEFAULT_PERMISSIONS = [
    ("user.view",       "查看用户"),
    ("user.create",     "创建用户"),
    ("user.edit",       "编辑用户"),
    ("user.delete",     "删除用户"),
    ("role.view",       "查看角色"),
    ("role.create",     "创建角色"),
    ("role.edit",       "编辑角色"),
    ("role.delete",     "删除角色"),
    ("checkin.view",    "查看打卡记录"),
    ("checkin.view_all","查看所有用户打卡记录"),
    ("checkin.manage",  "管理打卡记录"),
    ("system.settings", "系统设置"),
]

# 系统预置角色
DEFAULT_ROLES = {
    "管理员": {
        "description": "拥有系统全部权限",
        "permissions": [p[0] for p in DEFAULT_PERMISSIONS],  # 全部权限
    },
    "普通用户": {
        "description": "基础打卡功能权限",
        "permissions": ["checkin.view"],
    },
}


DEFAULT_DEPARTMENTS = [
    ("管理部", "管理与行政部门"),
    ("技术部", "技术研发部门"),
    ("财务部", "财务与审计部门"),
]


def _migrate_add_role_id(db: Session):
    """为已有数据库添加 role_id 列（SQLite 不支持 ADD COLUMN IF NOT EXISTS）"""
    insp = inspect(db.bind)
    columns = [c["name"] for c in insp.get_columns("users")]
    if "role_id" not in columns:
        db.execute(text("ALTER TABLE users ADD COLUMN role_id INTEGER REFERENCES roles(id)"))
        db.commit()


def _migrate_add_department_id(db: Session):
    """为已有数据库添加 department_id 列"""
    insp = inspect(db.bind)
    columns = [c["name"] for c in insp.get_columns("users")]
    if "department_id" not in columns:
        db.execute(text("ALTER TABLE users ADD COLUMN department_id INTEGER REFERENCES departments(id)"))
        db.commit()


def seed_rbac(db: Session):
    """确保默认权限和角色存在，幂等执行"""
    # 0. 迁移：确保 users 表有 role_id 列
    _migrate_add_role_id(db)

    # 1. 创建权限
    for codename, name in DEFAULT_PERMISSIONS:
        if not db.query(Permission).filter(Permission.codename == codename).first():
            db.add(Permission(codename=codename, name=name))
    db.commit()

    # 2. 创建角色（仅在首次创建时分配权限，避免覆盖管理员手动调整）
    for role_name, config in DEFAULT_ROLES.items():
        role = db.query(Role).filter(Role.name == role_name).first()
        if not role:
            role = Role(name=role_name, description=config["description"], is_system=True)
            perms = db.query(Permission).filter(Permission.codename.in_(config["permissions"])).all()
            role.permissions = perms
            db.add(role)
            db.commit()
            db.refresh(role)

    # 3. 为已有用户分配角色（迁移兼容）
    admin_role = db.query(Role).filter(Role.name == "管理员").first()
    user_role = db.query(Role).filter(Role.name == "普通用户").first()
    if admin_role and user_role:
        for user in db.query(User).filter(User.role_id.is_(None)).all():
            user.role_id = admin_role.id if user.is_admin else user_role.id
        db.commit()

    # 4. 迁移：确保 users 表有 department_id 列
    _migrate_add_department_id(db)

    # 5. 创建默认部门
    for dept_name, dept_desc in DEFAULT_DEPARTMENTS:
        if not db.query(Department).filter(Department.name == dept_name).first():
            db.add(Department(name=dept_name, description=dept_desc))
    db.commit()

    # 6. 为没有部门的用户分配默认部门
    admin_dept = db.query(Department).filter(Department.name == "管理部").first()
    tech_dept = db.query(Department).filter(Department.name == "技术部").first()
    if admin_dept and tech_dept:
        for user in db.query(User).filter(User.department_id.is_(None)).all():
            user.department_id = admin_dept.id if user.is_admin else tech_dept.id
        db.commit()
