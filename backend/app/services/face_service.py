"""
人脸识别服务 — OpenCV Haar Cascade + 直方图特征
- 人脸检测：OpenCV Haar Cascade（内置，无需额外模型）
- 人脸嵌入：LBP 直方图特征（无需下载外部模型）
- 比对方式：余弦相似度，阈值 0.6
"""
import json

import cv2
import numpy as np

# ── 配置 ──
_MATCH_THRESHOLD = 0.6
_FACE_SIZE = (128, 128)

# ── 全局缓存 ──
_face_cascade: cv2.CascadeClassifier | None = None


def _get_cascade() -> cv2.CascadeClassifier:
    global _face_cascade
    if _face_cascade is None:
        cascade_path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
        _face_cascade = cv2.CascadeClassifier(cascade_path)
    return _face_cascade


def _detect_face(img_bgr: np.ndarray) -> np.ndarray | None:
    """检测人脸并返回裁剪后的人脸区域，未检测到返回 None"""
    cascade = _get_cascade()
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    faces = cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(60, 60))
    if len(faces) == 0:
        return None
    # 取最大的人脸
    x, y, w, h = max(faces, key=lambda f: f[2] * f[3])
    # 扩大裁剪区域 20%
    pad = int(max(w, h) * 0.2)
    x1 = max(0, x - pad)
    y1 = max(0, y - pad)
    x2 = min(img_bgr.shape[1], x + w + pad)
    y2 = min(img_bgr.shape[0], y + h + pad)
    return img_bgr[y1:y2, x1:x2]


def _compute_embedding(face_bgr: np.ndarray) -> np.ndarray:
    """
    使用 LBP 直方图作为人脸特征向量。
    将人脸分成 8x8 网格，每块计算 LBP 直方图，拼接成特征向量。
    """
    gray = cv2.cvtColor(face_bgr, cv2.COLOR_BGR2GRAY)
    gray = cv2.resize(gray, _FACE_SIZE)
    # 均衡化提升对比度
    gray = cv2.equalizeHist(gray)

    h, w = gray.shape
    grid = 8
    cell_h, cell_w = h // grid, w // grid
    histograms = []

    for i in range(grid):
        for j in range(grid):
            cell = gray[i * cell_h:(i + 1) * cell_h, j * cell_w:(j + 1) * cell_w]
            # 计算 LBP
            lbp = _lbp(cell)
            hist, _ = np.histogram(lbp, bins=256, range=(0, 256))
            hist = hist.astype(np.float32)
            # 归一化
            norm = np.linalg.norm(hist)
            if norm > 0:
                hist = hist / norm
            histograms.append(hist)

    embedding = np.concatenate(histograms)
    # 全局 L2 归一化
    norm = np.linalg.norm(embedding)
    if norm > 0:
        embedding = embedding / norm
    return embedding


def _lbp(img: np.ndarray) -> np.ndarray:
    """计算 Local Binary Pattern"""
    rows, cols = img.shape
    result = np.zeros((rows - 2, cols - 2), dtype=np.uint8)
    for i in range(1, rows - 1):
        for j in range(1, cols - 1):
            center = img[i, j]
            code = 0
            code |= (1 << 7) if img[i - 1, j - 1] >= center else 0
            code |= (1 << 6) if img[i - 1, j] >= center else 0
            code |= (1 << 5) if img[i - 1, j + 1] >= center else 0
            code |= (1 << 4) if img[i, j + 1] >= center else 0
            code |= (1 << 3) if img[i + 1, j + 1] >= center else 0
            code |= (1 << 2) if img[i + 1, j] >= center else 0
            code |= (1 << 1) if img[i + 1, j - 1] >= center else 0
            code |= (1 << 0) if img[i, j - 1] >= center else 0
            result[i - 1, j - 1] = code
    return result


def _cosine_similarity(emb1: np.ndarray, emb2: np.ndarray) -> float:
    return float(np.dot(emb1, emb2))


# ── 公开接口 ──

def detect_and_encode(image_bytes: bytes) -> tuple[bool, list[float] | None]:
    """
    检测人脸并生成嵌入向量。
    返回 (是否成功, 嵌入向量 | None)
    """
    img_array = np.frombuffer(image_bytes, dtype=np.uint8)
    img_bgr = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    if img_bgr is None:
        return False, None

    face = _detect_face(img_bgr)
    if face is None:
        return False, None

    embedding = _compute_embedding(face)
    return True, embedding.tolist()


def compare_embeddings(emb1: list[float], emb2: list[float]) -> tuple[bool, float]:
    """
    比对两个嵌入向量。
    返回 (是否匹配, 相似度分数 0~1)
    """
    a = np.array(emb1, dtype=np.float32)
    b = np.array(emb2, dtype=np.float32)
    similarity = _cosine_similarity(a, b)
    return similarity >= _MATCH_THRESHOLD, float(similarity)


def embedding_to_json(embedding: list[float]) -> str:
    return json.dumps(embedding)


def embedding_from_json(json_str: str) -> list[float]:
    return json.loads(json_str)
