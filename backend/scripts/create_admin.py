"""交互式创建账号（支持选择角色）"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.database import SessionLocal
from app.models.user import User
from app.models.role import Role
from app.core import hash_password

db = SessionLocal()

# 1. 列出所有角色
roles = db.query(Role).order_by(Role.id).all()
if not roles:
    print("错误：角色表为空，请先启动一次后端以初始化种子数据")
    sys.exit(1)

print("=== 创建新账号 ===\n")

# 2. 输入账号信息
username = input("账号: ").strip()
if not username:
    print("账号不能为空"); sys.exit(1)
if db.query(User).filter(User.username == username).first():
    print(f"账号 '{username}' 已存在"); sys.exit(1)

full_name = input("姓名: ").strip()
if not full_name:
    print("姓名不能为空"); sys.exit(1)

password = input("密码: ").strip()
if not password:
    print("密码不能为空"); sys.exit(1)

# 3. 选择角色
print("\n可选角色:")
for i, role in enumerate(roles):
    perms = ", ".join(p.codename for p in role.permissions)
    print(f"  [{i + 1}] {role.name} — {role.description or '无描述'}  ({len(role.permissions)} 项权限)")

while True:
    choice = input(f"\n选择角色 [1-{len(roles)}]: ").strip()
    if choice.isdigit() and 1 <= int(choice) <= len(roles):
        selected_role = roles[int(choice) - 1]
        break
    print("无效输入，请重新选择")

# 4. 创建用户
is_admin = selected_role.name == "管理员"
user = User(
    username=username,
    full_name=full_name,
    hashed_password=hash_password(password),
    is_active=True,
    is_admin=is_admin,
    role_id=selected_role.id,
)
db.add(user)
db.commit()
db.refresh(user)

print(f"\n账号创建成功:")
print(f"  账号: {username}")
print(f"  密码: {password}")
print(f"  角色: {selected_role.name}")
print(f"  管理员: {'是' if is_admin else '否'}")
db.close()
