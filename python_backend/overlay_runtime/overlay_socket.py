import json
from fastapi import WebSocket, WebSocketDisconnect
from overlay_runtime.overlay_memory import load_history, save_message
from overlay_runtime.overlay_context import analyze_screen_context
from overlay_runtime.overlay_router import generate_overlay_stream
from overlay_runtime.overlay_stream import OverlayStreamSender

OVERLAY_CONVERSATION_ID = "aura_overlay"

async def overlay_socket_handler(websocket: WebSocket):
    await websocket.accept()
    print("AURA UNIFIED OVERLAY: WebSocket connection established.")
    
    stream_sender = OverlayStreamSender(websocket)
    
    try:
        while True:
            raw_data = await websocket.receive_text()
            if not raw_data:
                continue
                
            try:
                msg = json.loads(raw_data)
            except json.JSONDecodeError:
                print("AURA UNIFIED OVERLAY: Failed to parse incoming WS message as JSON.")
                await stream_sender.send_error("Invalid JSON payload.")
                continue
                
            event = msg.get("event") or msg.get("type")
            conv_id = msg.get("conversationId") or OVERLAY_CONVERSATION_ID
            
            # Case 1: Screen analysis / SCAN request
            if event == "analyze":
                print("AURA UNIFIED OVERLAY: Processing real-time screen analysis.")
                metadata = msg.get("metadata") or {}
                active_app = msg.get("active_app") or metadata.get("active_app") or ""
                window_title = msg.get("window_title") or metadata.get("window_title") or ""
                accessibility_text = msg.get("accessibility_text") or metadata.get("accessibility_text") or ""
                screenshot = msg.get("screenshot") or msg.get("screenshot_data") or metadata.get("screenshot") or ""
                
                await stream_sender.send_status("Scanning screen...")
                res = await analyze_screen_context(active_app, window_title, accessibility_text, screenshot)
                
                await stream_sender.send_context_detected(
                    detected_items=res.get("detected_items", []),
                    suggestions=res.get("suggestions", [])
                )
                await stream_sender.send_done()
                
            # Case 2: Standard Chat Prompt
            else:
                prompt = msg.get("prompt")
                if not prompt:
                    # Ignore empty heartbeats or keepalive messages
                    continue
                    
                print(f"AURA UNIFIED OVERLAY: Prompt received: '{prompt[:50]}...'")
                
                # Fetch history from memory if not provided by client
                history = msg.get("history")
                if history is None:
                    history = load_history(conv_id)
                
                # Save User Prompt
                save_message(conv_id, "user", prompt)
                
                # Start Stream
                await stream_sender.send_status("Generating response...")
                
                full_reply = ""
                sandbox = msg.get("sandbox") or {}
                # Ensure overlay properties are present
                sandbox["overlay_mode"] = True
                
                # Pass active app metadata if present in msg
                if "active_app" in msg:
                    sandbox["active_app"] = msg["active_app"]
                if "window_title" in msg:
                    sandbox["window_title"] = msg["window_title"]
                if "accessibility_text" in msg:
                    sandbox["accessibility_text"] = msg["accessibility_text"]
                if "screenshot" in msg:
                    sandbox["screenshot"] = msg["screenshot"]
                elif "screenshot_data" in msg:
                    sandbox["screenshot"] = msg["screenshot_data"]
                from main import inference_core
                async for chunk_type, content in inference_core.generate_stream(prompt, history, sandbox=sandbox):
                    if chunk_type == "content":
                        full_reply += content
                        await stream_sender.send_chunk(content)
                    elif chunk_type == "status":
                        await stream_sender.send_status(content)
                        
                # Save Assistant Response
                if full_reply:
                    save_message(conv_id, "assistant", full_reply)
                    
                await stream_sender.send_done()
                
    except WebSocketDisconnect:
        print("AURA UNIFIED OVERLAY: WebSocket client disconnected.")
    except Exception as e:
        print(f"AURA UNIFIED OVERLAY: Connection error: {e}")
        try:
            await stream_sender.send_error(str(e))
            await stream_sender.send_done()
        except:
            pass
