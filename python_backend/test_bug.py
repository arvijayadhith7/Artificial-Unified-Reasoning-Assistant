import asyncio
import json
import uuid
import os
from main import inference_core

async def run_test():
    prompt = "today ipl match"
    history = []
    sandbox = {"overlay_mode": False}
    
    try:
        async for chunk_type, content in inference_core.generate_stream(prompt, history, sandbox=sandbox):
            print(f"[{chunk_type}] {content}")
    except Exception as e:
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(run_test())
