from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base, SessionLocal
from app.routers import auth, users, checkins, roles, face, department, notifications
from app.seed import seed_rbac


# Create tables
Base.metadata.create_all(bind=engine)

# Seed default RBAC data
_db = SessionLocal()
try:
    seed_rbac(_db)
finally:
    _db.close()

app = FastAPI(title="熵析云枢打卡系统 API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000", "http://localhost:3001", "http://localhost:3002",
        "http://127.0.0.1:3000", "http://127.0.0.1:3001", "http://127.0.0.1:3002",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(checkins.router)
app.include_router(roles.router)
app.include_router(face.router)
app.include_router(department.router)
app.include_router(notifications.router)


@app.get("/")
def root():
    return {"message": "熵析云枢 API 运行中"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
