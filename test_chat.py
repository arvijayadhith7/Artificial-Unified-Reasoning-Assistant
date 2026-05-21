import asyncio
import websockets
import json

async def test():
    uri = "wss://vijayadhith7-aura-backend.hf.space/chat"
    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected! Sending chat query...")
            payload = {
                "prompt": "What is the capital of France?",
                "conversationId": "test_conv",
                "projectId": "test_proj",
                "sandbox": {
                    "overlay_mode": False
                }
            }
            await websocket.send(json.dumps(payload))
            print("Payload sent. Waiting for response...")
            
            # Wait for responses
            while True:
                response = await websocket.recv()
                data = json.loads(response)
                print(f"Received: {data}")
                if data.get("done") == True:
                    break
    except Exception as e:
        print(f"Connection failed: {e}")

asyncio.run(test())
