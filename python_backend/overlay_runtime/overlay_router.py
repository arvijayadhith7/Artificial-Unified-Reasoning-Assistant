import os
from typing import AsyncGenerator, List, Dict, Any
from overlay_engine import (
    build_overlay_system_prompt,
    build_overlay_user_prompt,
    get_overlay_inference_params,
    get_overlay_model,
    classify_workflow,
    merge_sandbox_defaults
)

async def generate_overlay_stream(
    prompt: str,
    history: List[Dict[str, Any]],
    sandbox: Dict[str, Any] = None
) -> AsyncGenerator[tuple, None]:
    # Lazy load client from main to avoid circular imports
    try:
        from main import async_groq_client
        client = async_groq_client
    except ImportError:
        client = None

    if not client:
        yield ("content", "AURA Error: Connection issue. Missing GROQ_API_KEY.")
        return

    sandbox = merge_sandbox_defaults(sandbox)
    sandbox["overlay_mode"] = True
    assistant_mode = sandbox.get("assistant_mode", "copilot")
    
    active_app = sandbox.get("active_app") or "Unknown"
    window_title = sandbox.get("window_title") or ""
    accessibility_text = sandbox.get("accessibility_text") or ""
    screenshot_b64 = sandbox.get("screenshot") or sandbox.get("screenshot_data")
    
    # Strip data:image prefix if present
    base64_image_content = None
    if screenshot_b64 and screenshot_b64.startswith("data:image"):
        try:
            base64_image_content = screenshot_b64.split(",")[1]
        except Exception:
            pass
    elif screenshot_b64:
        base64_image_content = screenshot_b64

    workflow = classify_workflow(active_app, window_title, accessibility_text)
    has_screenshot = bool(base64_image_content)
    
    system_prompt = build_overlay_system_prompt(
        sandbox, workflow, active_app, window_title, has_screenshot
    )
    overlay_params = get_overlay_inference_params(sandbox, has_screenshot)
    chosen_model = get_overlay_model(has_screenshot, assistant_mode)
    
    # Build User message
    user_text = build_overlay_user_prompt(prompt, has_screenshot, active_app, window_title)
    
    if base64_image_content:
        user_message = {
            "role": "user",
            "content": [
                {"type": "text", "text": user_text},
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{base64_image_content}"
                    }
                }
            ]
        }
    else:
        user_message = {"role": "user", "content": user_text}
        
    # Format/sanitize history
    sanitized_history = []
    last_role = None
    for msg in history:
        role = "assistant" if msg.get("role") in ["model", "assistant"] else "user"
        content = msg.get("content", "")
        if role == last_role:
            continue
        sanitized_history.append({"role": role, "content": content})
        last_role = role
        
    if len(sanitized_history) > 10:
        sanitized_history = sanitized_history[-10:]
        
    messages = [
        {"role": "system", "content": system_prompt}
    ] + sanitized_history + [user_message]
    
    try:
        response_stream = await client.chat.completions.create(
            model=chosen_model,
            messages=messages,
            temperature=overlay_params.get("temperature", 0.7),
            max_tokens=overlay_params.get("max_tokens", 500),
            stream=True
        )
        
        async for chunk in response_stream:
            if chunk.choices and chunk.choices[0].delta.content:
                yield ("content", chunk.choices[0].delta.content)
    except Exception as e:
        print(f"Overlay Router Stream Error: {e}")
        yield ("content", f"\nI encountered an issue generating a response: {str(e)}")
