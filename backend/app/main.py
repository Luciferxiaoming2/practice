from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.routers import auth, users, checkins


# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="熵析云枢打卡系统 API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001", "http://localhost:3002"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(checkins.router)


@app.get("/")
def root():
    return {"message": "熵析云枢 API 运行中"}
