"""
Backend API integration tests.
Run: cd backend && python -m pytest ../test/test_api.py -v
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.database import Base, engine

client = TestClient(app)


@pytest.fixture(autouse=True)
def reset_db():
    """Recreate tables before each test."""
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


# ── helpers ─────────────────────────────────────────────

def create_admin():
    """Create an admin user and return (user, token)."""
    res = client.post("/auth/login", json={"username": "admin", "password": "admin123"})
    # First create without auth (bootstrap)
    # We need to temporarily create user directly
    from app.database import SessionLocal
    from app.models.user import User
    from app.core import hash_password
    db = SessionLocal()
    user = User(username="admin", full_name="管理员", hashed_password=hash_password("admin123"), is_admin=True, is_active=True)
    db.add(user)
    db.commit()
    db.refresh(user)
    db.close()

    res = client.post("/auth/login", json={"username": "admin", "password": "admin123"})
    assert res.status_code == 200
    token = res.json()["access_token"]
    return user, token


def auth_header(token: str):
    return {"Authorization": f"Bearer {token}"}


# ── Auth ────────────────────────────────────────────────

class TestAuth:
    def test_login_success(self):
        _, token = create_admin()
        assert token

    def test_login_wrong_password(self):
        create_admin()
        res = client.post("/auth/login", json={"username": "admin", "password": "wrong"})
        assert res.status_code == 401

    def test_login_nonexistent_user(self):
        res = client.post("/auth/login", json={"username": "ghost", "password": "123"})
        assert res.status_code == 401


# ── Users ───────────────────────────────────────────────

class TestUsers:
    def test_create_user(self):
        _, token = create_admin()
        res = client.post("/users/", json={
            "username": "worker1",
            "full_name": "员工一",
            "password": "123456",
        }, headers=auth_header(token))
        assert res.status_code == 200
        data = res.json()
        assert data["username"] == "worker1"
        assert data["is_active"] is False

    def test_create_duplicate_user(self):
        _, token = create_admin()
        body = {"username": "dup", "full_name": "重复", "password": "123456"}
        client.post("/users/", json=body, headers=auth_header(token))
        res = client.post("/users/", json=body, headers=auth_header(token))
        assert res.status_code == 400

    def test_list_users(self):
        _, token = create_admin()
        res = client.get("/users/", headers=auth_header(token))
        assert res.status_code == 200
        assert isinstance(res.json(), list)

    def test_get_user(self):
        user, token = create_admin()
        res = client.get(f"/users/{user.id}", headers=auth_header(token))
        assert res.status_code == 200
        assert res.json()["username"] == "admin"

    def test_update_user_rules(self):
        _, token = create_admin()
        # create a worker
        res = client.post("/users/", json={
            "username": "w", "full_name": "W", "password": "123456",
        }, headers=auth_header(token))
        uid = res.json()["id"]

        res = client.patch(f"/users/{uid}", json={
            "require_location": True,
            "location_lat": 31.23,
            "location_lng": 121.47,
            "location_radius": 200,
            "require_time": True,
            "checkin_time_start": "09:00",
            "checkin_time_end": "18:00",
        }, headers=auth_header(token))
        assert res.status_code == 200
        data = res.json()
        assert data["require_location"] is True
        assert data["location_radius"] == 200

    def test_reset_password(self):
        user, token = create_admin()
        res = client.post(f"/users/{user.id}/reset-password", json={
            "new_password": "newpass",
        }, headers=auth_header(token))
        assert res.status_code == 200

        # login with new password
        res = client.post("/auth/login", json={"username": "admin", "password": "newpass"})
        assert res.status_code == 200

    def test_reset_face(self):
        _, token = create_admin()
        res = client.post("/users/", json={
            "username": "face_user", "full_name": "F", "password": "123456",
        }, headers=auth_header(token))
        uid = res.json()["id"]

        # mark face enrolled
        client.patch(f"/users/{uid}", json={"face_enrolled": True, "is_active": True}, headers=auth_header(token))

        res = client.post(f"/users/{uid}/reset-face", headers=auth_header(token))
        assert res.status_code == 200

        res = client.get(f"/users/{uid}", headers=auth_header(token))
        assert res.json()["face_enrolled"] is False
        assert res.json()["is_active"] is False

    def test_no_auth_returns_403(self):
        res = client.get("/users/")
        assert res.status_code == 403


# ── Checkins ────────────────────────────────────────────

class TestCheckins:
    def test_create_checkin(self):
        user, token = create_admin()
        res = client.post("/checkins/", json={
            "user_id": user.id,
            "lat": 31.23,
            "lng": 121.47,
            "status": "ok",
        })
        assert res.status_code == 200
        data = res.json()
        assert data["user_id"] == user.id
        assert data["status"] == "ok"
        assert data["timestamp"] is not None

    def test_create_checkin_invalid_user(self):
        res = client.post("/checkins/", json={
            "user_id": 9999,
            "status": "ok",
        })
        assert res.status_code == 404

    def test_list_checkins(self):
        user, token = create_admin()
        # create a few records
        for _ in range(3):
            client.post("/checkins/", json={"user_id": user.id, "status": "ok"})

        res = client.get("/checkins/")
        assert res.status_code == 200
        assert len(res.json()) == 3

    def test_filter_by_user(self):
        user, token = create_admin()
        client.post("/checkins/", json={"user_id": user.id, "status": "ok"})

        res = client.get("/checkins/", params={"user_id": user.id})
        assert res.status_code == 200
        assert len(res.json()) >= 1

        res = client.get("/checkins/", params={"user_id": 9999})
        assert res.status_code == 200
        assert len(res.json()) == 0

    def test_filter_by_date(self):
        user, _ = create_admin()
        client.post("/checkins/", json={"user_id": user.id, "status": "ok"})

        from datetime import date
        today = date.today().isoformat()
        res = client.get("/checkins/", params={"date_from": today, "date_to": today})
        assert res.status_code == 200
        assert len(res.json()) >= 1

        res = client.get("/checkins/", params={"date_from": "2099-01-01"})
        assert res.status_code == 200
        assert len(res.json()) == 0

    def test_checkin_without_location(self):
        user, _ = create_admin()
        res = client.post("/checkins/", json={
            "user_id": user.id,
            "status": "ok",
        })
        assert res.status_code == 200
        data = res.json()
        assert data["lat"] is None
        assert data["lng"] is None
