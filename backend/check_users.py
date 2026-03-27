from app.database import SessionLocal
from app.models.user import User
from app.models.role import Role

db = SessionLocal()
users = db.query(User).all()
print(f"用户数量: {len(users)}")
for u in users:
    role = db.query(Role).filter(Role.id == u.role_id).first()
    print(f"  id={u.id} username={u.username} is_admin={u.is_admin} role={role.name if role else None} active={u.is_active}")
db.close()
