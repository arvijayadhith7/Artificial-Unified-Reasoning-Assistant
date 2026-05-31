import asyncio
import websockets

async def test_ws():
    uri = "wss://vijayadhith7-aura-backend.hf.space/overlay/chat"
    try:
        print(f"Connecting to {uri}...")
        async with websockets.connect(uri) as ws:
            print("Connected successfully!")
            await ws.send('{"type": "ping"}')
            print("Sent ping.")
            # Wait for any response briefly
            res = await asyncio.wait_for(ws.recv(), timeout=2.0)
            print(f"Received: {res}")
    except Exception as e:
        print(f"Connection failed: {e}")

asyncio.run(test_ws())
