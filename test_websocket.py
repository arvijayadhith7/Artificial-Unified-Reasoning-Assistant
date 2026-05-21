import asyncio
import websockets
import json

async def test():
    uri = "wss://vijayadhith7-aura-backend.hf.space/research"
    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected! Sending search request...")
            payload = {
                "prompt": "NVIDIA AI chips",
                "category": "Web"
            }
            await websocket.send(json.dumps(payload))
            print("Payload sent. Waiting for response...")
            
            # Wait for up to 3 responses
            for _ in range(5):
                response = await websocket.recv()
                print(f"Received: {response}")
    except Exception as e:
        print(f"Connection failed: {e}")

asyncio.run(test())
