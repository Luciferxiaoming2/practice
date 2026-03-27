"""创建超级管理员账号"""
from app.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.role import Role
from app.core import hash_password
from app.seed import seed_rbac

Base.metadata.create_all(bind=engine)

db = SessionLocal()

# 确保角色存在
seed_rbac(db)

username = "admin"
password = "Admin@123456"

if db.query(User).filter(User.username == username).first():
    print(f"用户 '{username}' 已存在")
else:
    admin_role = db.query(Role).filter(Role.name == "管理员").first()
    user = User(
        username=username,
        full_name="超级管理员",
        hashed_password=hash_password(password),
        is_active=True,
        is_admin=True,
        face_enrolled=False,
        role_id=admin_role.id if admin_role else None,
    )
    db.add(user)
    db.commit()
    print(f"✅ 管理员账号创建成功")
    print(f"   用户名: {username}")
    print(f"   密码:   {password}")

db.close()
