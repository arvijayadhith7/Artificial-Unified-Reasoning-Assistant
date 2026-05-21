import asyncio
import subprocess
import time
import websockets
import json
import sys

async def run_client():
    uri = "ws://127.0.0.1:7860/chat"
    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected! Sending image generation request...")
            payload = {
                "prompt": "generate image of a futuristic flying car",
                "conversationId": "test_image_conv",
                "projectId": "test_proj",
                "sandbox": {
                    "overlay_mode": False
                }
            }
            await websocket.send(json.dumps(payload))
            print("Payload sent. Waiting for response...")
            
            while True:
                response = await websocket.recv()
                data = json.loads(response)
                print(f"Received: {data}")
                if data.get("done") == True:
                    break
    except Exception as e:
        print(f"Client error: {e}")

def main():
    print("Starting AURA backend server locally...")
    server_process = subprocess.Popen(
        [sys.executable, "main.py"],
        cwd="python_backend",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # Wait a moment for server to start
    time.sleep(3.0)
    
    try:
        asyncio.run(run_client())
    finally:
        print("Terminating backend server...")
        server_process.terminate()
        stdout, stderr = server_process.communicate()
        print("--- SERVER STDOUT ---")
        print(stdout.decode('utf-8', errors='ignore'))
        print("--- SERVER STDERR ---")
        print(stderr.decode('utf-8', errors='ignore'))
        print("Server terminated.")

if __name__ == "__main__":
    main()
