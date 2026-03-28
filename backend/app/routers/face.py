"""人脸录入 & 验证 API"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.core import get_current_user
from app.services.face_service import (
    detect_and_encode,
    compare_embeddings,
    embedding_to_json,
    embedding_from_json,
)

router = APIRouter(prefix="/face", tags=["face"])


@router.post("/enroll")
async def enroll_face(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    payload: dict = Depends(get_current_user),
):
    """录入人脸：上传照片 → 检测人脸 → 生成嵌入 → 存入数据库"""
    user_id = int(payload["sub"])
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(404, "用户不存在")

    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(400, "图片为空")

    success, embedding = detect_and_encode(image_bytes)
    if not success or embedding is None:
        raise HTTPException(400, "未检测到人脸，请确保光线充足且面部清晰")

    user.face_embedding = embedding_to_json(embedding)
    user.face_enrolled = True
    db.commit()

    return {"success": True, "message": "人脸录入成功"}


@router.post("/verify")
async def verify_face(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    payload: dict = Depends(get_current_user),
):
    """验证人脸：上传照片 → 与已存嵌入比对"""
    user_id = int(payload["sub"])
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(404, "用户不存在")

    if not user.face_enrolled or not user.face_embedding:
        raise HTTPException(400, "该用户尚未录入人脸")

    image_bytes = await file.read()
    if len(image_bytes) == 0:
        raise HTTPException(400, "图片为空")

    success, new_embedding = detect_and_encode(image_bytes)
    if not success or new_embedding is None:
        raise HTTPException(400, "未检测到人脸，请正对摄像头重试")

    stored_embedding = embedding_from_json(user.face_embedding)
    matched, similarity = compare_embeddings(stored_embedding, new_embedding)

    return {
        "matched": matched,
        "similarity": round(similarity, 4),
        "message": "验证通过" if matched else "人脸不匹配",
    }
