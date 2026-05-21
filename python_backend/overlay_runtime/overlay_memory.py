import os
import json
import time

MEMORY_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "memory", "chats")

def load_history(conv_id: str) -> list:
    os.makedirs(MEMORY_DIR, exist_ok=True)
    msg_file = os.path.join(MEMORY_DIR, f"{conv_id}.json")
    if os.path.exists(msg_file):
        try:
            with open(msg_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading overlay history: {e}")
    return []

def save_message(conv_id: str, role: str, content: str):
    os.makedirs(MEMORY_DIR, exist_ok=True)
    msg_file = os.path.join(MEMORY_DIR, f"{conv_id}.json")
    messages = load_history(conv_id)
    messages.append({
        "role": role,
        "content": content,
        "timestamp": str(time.time())
    })
    try:
        with open(msg_file, "w", encoding="utf-8") as f:
            json.dump(messages, f, ensure_ascii=False)
    except Exception as e:
        print(f"Error saving overlay message: {e}")
