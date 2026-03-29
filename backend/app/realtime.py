import asyncio
from collections import defaultdict
from datetime import datetime, timezone
from typing import Iterable

from fastapi import WebSocket

RULE_FIELD_LABELS = {
    "require_sign_in": "签到要求",
    "require_sign_out": "签退要求",
    "require_location": "定位规则",
    "location_lat": "定位坐标",
    "location_lng": "定位坐标",
    "location_radius": "定位半径",
    "require_time": "时间规则",
    "checkin_time_start": "签到开始时间",
    "checkin_time_end": "签到结束时间",
    "sign_out_time_start": "签退开始时间",
    "sign_out_time_end": "签退结束时间",
    "require_face": "人脸规则",
}


class NotificationManager:
    def __init__(self) -> None:
        self._connections: dict[int, set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, user_id: int, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._connections[user_id].add(websocket)

    async def disconnect(self, user_id: int, websocket: WebSocket) -> None:
        async with self._lock:
            sockets = self._connections.get(user_id)
            if not sockets:
                return
            sockets.discard(websocket)
            if not sockets:
                self._connections.pop(user_id, None)

    async def send_to_user(self, user_id: int, payload: dict) -> None:
        async with self._lock:
            sockets = list(self._connections.get(user_id, set()))

        stale: list[WebSocket] = []
        for websocket in sockets:
            try:
                await websocket.send_json(payload)
            except Exception:
                stale.append(websocket)

        for websocket in stale:
            await self.disconnect(user_id, websocket)


notification_manager = NotificationManager()


def _format_rule_message(changed_fields: Iterable[str], scope: str) -> str:
    labels: list[str] = []
    for field in changed_fields:
        label = RULE_FIELD_LABELS.get(field)
        if label and label not in labels:
            labels.append(label)

    prefix = "管理员更新了你的打卡规则" if scope == "user" else "管理员更新了你所属部门的打卡规则"
    if not labels:
        return f"{prefix}，请重新确认当前要求。"
    return f"{prefix}：{', '.join(labels)}。"


async def notify_rule_updated(
    user_ids: Iterable[int],
    *,
    actor_id: int,
    changed_fields: Iterable[str],
    scope: str = "user",
    scope_id: int | None = None,
) -> None:
    normalized_fields = list(dict.fromkeys(changed_fields))
    payload = {
        "event": "rule_updated",
        "message": _format_rule_message(normalized_fields, scope),
        "changed_fields": normalized_fields,
        "actor_id": actor_id,
        "scope": scope,
        "scope_id": scope_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    for user_id in set(user_ids):
        await notification_manager.send_to_user(user_id, payload)
