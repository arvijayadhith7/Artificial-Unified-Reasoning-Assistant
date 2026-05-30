"""
AURA Universal Overlay Context Engine
Detects active workflow, builds contextual prompts, routes assistant modes.
"""
import os
import re
from typing import Any, Dict, Optional, Tuple

try:
    from response_rules import REALTIME_SEARCH_RESPONSE_RULES, AURA_NATURAL_ASSISTANT_RULES
except ImportError:
    REALTIME_SEARCH_RESPONSE_RULES = ""
    AURA_NATURAL_ASSISTANT_RULES = ""

OVERLAY_CONVERSATION_ID = "aura_overlay"

# Fast overlay SLM — low latency, low token budget (Groq cloud; not bundled on device)
OVERLAY_SLM_MODEL = "llama-3.1-8b-instant"

# Groq multimodal model (replaces decommissioned llama-3.2-11b-vision-preview)
GROQ_VISION_MODEL = os.environ.get("GROQ_VISION_MODEL", "openbmb/minicpm-v-2.6")
GROQ_VISION_MAX_B64_BYTES = 3_500_000  # Groq limit is 4MB for base64 images

ASSISTANT_MODES = ("quick", "tutor", "copilot", "research", "focus")

# App → tutor guideline templates (concise, actionable)
APP_GUIDELINES: Dict[str, str] = {
    "photoshop": "Photoshop tutor: give step-by-step UI actions (layers, masks, curves, selections).",
    "premiere": "Premiere Pro tutor: timeline cuts, transitions, Lumetri, audio sync, export settings.",
    "excel": "Excel tutor: formulas (VLOOKUP, XLOOKUP), pivots, charts — show exact steps.",
    "code": "Coding tutor: explain errors clearly, suggest fixes, no vague advice.",
    "vscode": "VS Code tutor: debug steps, extensions, async patterns, linter fixes.",
    "figma": "Figma tutor: Auto Layout, components, spacing, prototyping.",
    "blender": "Blender tutor: modeling, materials, rendering workflow.",
    "capcut": "Video editing tutor: pacing, transitions, captions, export.",
    "game": "Gaming coach: strategy and mechanics only. NEVER cheat, inject, or automate gameplay.",
    "browser": "Browsing assistant: summarize, explain, research — be concise.",
}


def classify_workflow(active_process: str, window_title: str, accessibility_text: str = "") -> str:
    p = (active_process or "").lower()
    t = (window_title or "").lower()
    a = (accessibility_text or "").lower()
    combined = f"{p} {t} {a}"

    if any(x in combined for x in ["photoshop", "gimp", "lightroom"]):
        return "photoshop"
    if any(x in combined for x in ["premiere", "davinci", "resolve", "capcut", "after effects"]):
        return "premiere" if "premiere" in combined or "after effects" in combined else "capcut"
    if any(x in combined for x in ["excel", "spreadsheet", "sheets"]):
        return "excel"
    if any(x in combined for x in ["code.exe", "vscode", "cursor", "android studio", "intellij", "pycharm"]):
        return "vscode"
    if "figma" in combined:
        return "figma"
    if "blender" in combined:
        return "blender"
    if any(x in combined for x in ["chrome", "firefox", "edge", "brave", "opera", "safari"]):
        return "browser"
    if any(x in combined for x in ["valorant", "fortnite", "csgo", "lol", "gta", "fifa", "minecraft", "steam"]):
        return "game"
    return "general"


def get_app_guideline(workflow: str) -> str:
    return APP_GUIDELINES.get(workflow, "")


OVERLAY_PERSONAS = {
    "warm-narrative": (
        "Sound like a calm, capable coworker: friendly, clear, and confident. "
        "Use plain language. Say 'you' more than 'we'."
    ),
    "ultra-technical": (
        "Be precise and professional. Name tools, menus, and shortcuts when relevant. "
        "Skip filler and small talk."
    ),
    "minimalist-hacker": (
        "Ultra-direct. Short sentences. Commands and fixes first, explanation second."
    ),
}

MODE_RULES = {
    "quick": {
        "style": "Answer in 1–3 short sentences. Lead with the answer.",
        "max_tokens": 180,
        "temperature": 0.4,
    },
    "tutor": {
        "style": "Teach with numbered steps (max 5). Reference visible UI labels when you can.",
        "max_tokens": 450,
        "temperature": 0.5,
    },
    "copilot": {
        "style": "Help finish the current task. End with one clear next action.",
        "max_tokens": 380,
        "temperature": 0.55,
    },
    "research": {
        "style": "Answer from live data when provided. One short source line at the end if needed.",
        "max_tokens": 500,
        "temperature": 0.5,
    },
    "focus": {
        "style": "One or two sentences only. No lists unless essential.",
        "max_tokens": 120,
        "temperature": 0.35,
    },
}


def get_overlay_inference_params(sandbox: dict, has_screenshot: bool = False) -> dict:
    mode = sandbox.get("assistant_mode", "copilot")
    cfg = MODE_RULES.get(mode, MODE_RULES["copilot"])
    max_tokens = cfg["max_tokens"]
    if has_screenshot:
        # Increase token limit significantly to prevent truncation due to reasoning tokens
        max_tokens = max(max_tokens, 2048)
    return {
        "max_tokens": max_tokens,
        "temperature": cfg["temperature"],
    }


def build_overlay_user_prompt(prompt: str, has_screenshot: bool, active_app: str, window_title: str) -> str:
    """Wrap user message for overlay — especially screen/vision queries."""
    if not has_screenshot:
        return prompt
    ctx = []
    if window_title:
        ctx.append(f"Active window: {window_title}")
    if active_app:
        ctx.append(f"App: {active_app}")
    context_line = (" | ".join(ctx) + "\n\n") if ctx else ""
    return (
        f"{context_line}"
        "The user shared a screenshot of their screen. Describe what you see in plain language, "
        "then answer their question in a practical way.\n\n"
        f"User question: {prompt}"
    )


def build_overlay_system_prompt(
    sandbox: dict,
    workflow: str,
    active_app: str = "",
    window_title: str = "",
    has_screenshot: bool = False,
) -> str:
    """Dedicated system prompt for overlay — short, human, no essay mode."""
    mode = sandbox.get("assistant_mode", "copilot")
    persona = sandbox.get("persona", "warm-narrative")
    persona_line = OVERLAY_PERSONAS.get(persona, OVERLAY_PERSONAS["warm-narrative"])
    mode_cfg = MODE_RULES.get(mode, MODE_RULES["copilot"])
    guideline = get_app_guideline(workflow)

    lines = [
        "You are AURA Overlay — a realtime assistant floating over the user's desktop.",
        "The user is mid-task and needs fast, usable help without leaving their app.",
        "",
        REALTIME_SEARCH_RESPONSE_RULES.strip() if REALTIME_SEARCH_RESPONSE_RULES else "",
        AURA_NATURAL_ASSISTANT_RULES.strip() if AURA_NATURAL_ASSISTANT_RULES else "",
        "",
        "VOICE & TONE:",
        f"- {persona_line}",
        f"- Mode: {mode}. {mode_cfg['style']}",
        "",
        "FORMAT (important):",
        "- Write for a small overlay panel — keep it scannable.",
        "- Prefer short paragraphs or a tight bullet list (max 5 bullets).",
        "- Use **bold** sparingly (1–3 phrases max). No walls of markdown.",
        "- No H1/H2 headers unless the answer truly needs structure.",
        "- Never open with 'Certainly!', 'Great question!', or 'I'd be happy to help'.",
        "- Never mention being an AI, model, training data, or internal systems.",
        "",
        "BEHAVIOR:",
        "- Answer the question first, then add brief context if useful.",
        "- If you see a screenshot: say what's on screen in 2–4 sentences, then help.",
        "- If something is unclear on screen, say what you can see and ask one short follow-up.",
        "- Give concrete UI steps (menu names, buttons) when guiding software.",
        "- For coding: show the fix or pattern, not a lecture.",
        "- For games: coach only — never cheats, bots, or exploits.",
    ]

    if window_title or active_app:
        lines.append("")
        lines.append("CURRENT CONTEXT:")
        if window_title:
            lines.append(f"- Window: {window_title}")
        if active_app:
            lines.append(f"- Process: {active_app}")
    if guideline:
        lines.append(f"- Focus: {guideline}")
    if sandbox.get("selected_text"):
        lines.append(f"- Selected text: {sandbox['selected_text'][:400]}")
    if has_screenshot:
        lines.append("- A screenshot of the user's screen is attached — use it as ground truth.")

    return "\n".join(lines)


def overlay_system_addon(sandbox: dict, workflow: str) -> str:
    """Legacy hook — overlay now uses build_overlay_system_prompt instead."""
    return ""


def merge_sandbox_defaults(sandbox: Optional[dict]) -> dict:
    s = dict(sandbox or {})
    s.setdefault("platform", "web")
    s.setdefault("overlay_mode", False)
    s.setdefault("assistant_mode", "copilot")
    s.setdefault("incognito", False)
    s.setdefault("persona", "warm-narrative")
    s.setdefault("search_strategy", "multi-tier")
    s.setdefault("ocr", True)
    # Android legacy key
    if not s.get("screenshot") and s.get("screenshot_data"):
        s["screenshot"] = s["screenshot_data"]
    return s


def get_overlay_model(has_screenshot: bool, assistant_mode: str = "copilot") -> str:
    """Dedicated overlay model router — never uses main-chat 70B unless research mode."""
    if has_screenshot:
        return GROQ_VISION_MODEL
    if assistant_mode == "research":
        return "llama-3.3-70b-versatile"
    return OVERLAY_SLM_MODEL


def get_windows_active_window() -> Tuple[str, str]:
    """Returns (window_title, process_name). Windows only."""
    try:
        import ctypes
        import subprocess

        hwnd = ctypes.windll.user32.GetForegroundWindow()
        length = ctypes.windll.user32.GetWindowTextLengthW(hwnd)
        title_buf = ctypes.create_unicode_buffer(length + 1)
        ctypes.windll.user32.GetWindowTextW(hwnd, title_buf, length + 1)
        title = title_buf.value or ""

        pid = ctypes.c_ulong()
        ctypes.windll.user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        cmd = f'tasklist /FI "PID eq {pid.value}" /FO CSV /NH'
        output = subprocess.check_output(cmd, shell=True, timeout=1.0).decode("utf-8", errors="ignore")
        parts = output.strip().split(",")
        process = parts[0].strip('"') if parts else ""
        return title, process
    except Exception:
        return "", ""


def compress_screenshot_base64(pil_image) -> str:
    """Resize and compress a PIL image to fit Groq's base64 size limit."""
    import io
    import base64
    from PIL import Image

    img = pil_image.convert("RGB")
    max_dim = 1280
    w, h = img.size
    if max(w, h) > max_dim:
        ratio = max_dim / max(w, h)
        img = img.resize((int(w * ratio), int(h * ratio)), Image.Resampling.LANCZOS)

    for quality in (70, 55, 45, 35):
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=quality, optimize=True)
        raw = buf.getvalue()
        if len(raw) <= GROQ_VISION_MAX_B64_BYTES:
            return base64.b64encode(raw).decode("utf-8")

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=30, optimize=True)
    return base64.b64encode(buf.getvalue()).decode("utf-8")


def build_context_snapshot(platform: str = "windows") -> Dict[str, Any]:
    title, process = ("", "")
    if platform in ("windows", "web") and os.name == "nt":
        title, process = get_windows_active_window()

    workflow = classify_workflow(process, title)
    return {
        "active_app": process or "Unknown",
        "window_title": title,
        "workflow": workflow,
        "platform": platform,
        "guideline": get_app_guideline(workflow),
    }
