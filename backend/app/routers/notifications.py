from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status
from jose import JWTError

from app.core import decode_token
from app.realtime import notification_manager

router = APIRouter(tags=["notifications"])


@router.websocket("/ws/notifications")
async def notifications_socket(websocket: WebSocket):
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Missing token")
        return

    try:
        payload = decode_token(token)
        user_id = int(payload["sub"])
    except (JWTError, KeyError, ValueError):
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
        return

    await notification_manager.connect(user_id, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        await notification_manager.disconnect(user_id, websocket)
