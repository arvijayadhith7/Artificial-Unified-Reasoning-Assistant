import asyncio
import websockets
import json

async def test():
    uri = "wss://vijayadhith7-aura-backend.hf.space/overlay/chat"
    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected!")
            payload = {
                "event": "analyze",
                "active_app": "test_app",
                "window_title": "test_window",
                "accessibility_text": "Active field: test",
                "screenshot": "",
                "metadata": {
                    "language": "English",
                    "app_name": "test_app",
                    "active_field": {
                        "id": "123",
                        "label": "test",
                        "value": "",
                        "type": "text"
                    }
                }
            }
            await websocket.send(json.dumps(payload))
            print("Payload sent. Waiting for response...")
            
            while True:
                response = await websocket.recv()
                data = json.loads(response)
                print(f"Received: {data}")
                if data.get("done") == True or data.get("type") == "context_detected":
                    break
    except Exception as e:
        print(f"Connection failed: {e}")

asyncio.run(test())
