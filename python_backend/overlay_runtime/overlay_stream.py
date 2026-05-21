import json
from fastapi import WebSocket

class OverlayStreamSender:
    def __init__(self, websocket: WebSocket):
        self.websocket = websocket

    async def send_status(self, content: str):
        await self.websocket.send_text(json.dumps({
            "type": "status",
            "content": content
        }, ensure_ascii=False))

    async def send_chunk(self, content: str):
        await self.websocket.send_text(json.dumps({
            "type": "chunk",
            "content": content
        }, ensure_ascii=False))

    async def send_done(self):
        await self.websocket.send_text(json.dumps({
            "done": True
        }, ensure_ascii=False))

    async def send_context_detected(self, detected_items: list, suggestions: list):
        await self.websocket.send_text(json.dumps({
            "type": "context_detected",
            "detected_items": detected_items,
            "suggestions": suggestions
        }, ensure_ascii=False))

    async def send_error(self, content: str):
        await self.websocket.send_text(json.dumps({
            "type": "error",
            "content": content
        }, ensure_ascii=False))
