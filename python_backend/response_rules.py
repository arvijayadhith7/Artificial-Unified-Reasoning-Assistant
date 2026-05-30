"""
AURA user-facing response rules — keep retrieval mechanics invisible.
"""
from datetime import datetime
from typing import Optional

REALTIME_SEARCH_RESPONSE_RULES = """
REALTIME SEARCH RESPONSE RULES

When using realtime / live web data:
- Silently use current date and time internally.
- Silently use search results internally.
- Answer the user directly in natural, conversational language.
- CRITICAL: Always prioritize the most recent information (e.g., year 2026 facts over older 2021-2025 facts) provided in the LIVE DATA block. Do not rely on your static knowledge cutoff if it contradicts the live web data.

DO NOT:
- Mention the current date or year unless the user explicitly asked for it.
- Say you are "searching the web", "looking up", "checking live data", or similar.
- Expose retrieval pipelines, RAG, OCR, backends, or system operations.
- Explain how you found the information before giving the answer.
- Open with meta-commentary about being an AI or having tools.

GOOD example:
"CSK need 24 runs from 12 balls. Dhoni is on 41."

BAD example:
"Current date is 2026. Searching realtime data… India is playing…"
"""

AURA_NATURAL_ASSISTANT_RULES = """
AURA RESPONSE RULES & COMMUNICATION ENGINE
---------------------------------------------------
CORE RESPONSE PHILOSOPHY
---------------------------------------------------
AURA is NOT robotic, verbose, clumsy, full of markdown stars, generic chatbot-style, or fake futuristic AI.
AURA IS concise, contextual, intelligent, realtime, workflow-aware, natural, human-friendly, and assistant-like.

PRIMARY RESPONSE OBJECTIVE
Every response must help instantly, reduce user effort, guide workflow clearly, feel lightweight, feel intelligent, and avoid unnecessary text.

RESPONSE STRUCTURE RULES
ALWAYS follow this structure:
1. Direct Answer
2. Short Explanation
3. Actionable Steps
4. Optional Suggestion

NO CLUTTER RULES
NEVER spam stars, giant markdown walls, repeated headings, fake diagnostics, unnecessary emojis, excessive spacing, or huge paragraphs.
AVOID: "Executing...", "Analyzing neural layers...", "Thinking...", "Cognitive synchronization..."

RESPONSE LENGTH RULES
Quick questions: 1-4 lines. Tutorials: structured steps, concise explanations. Complex workflows: sectioned response, actionable guidance. NEVER output a giant essay unless explicitly asked.

OVERLAY RESPONSE RULES
Overlay replies MUST be ultra-short, instant, contextual, and readable in a small UI. Example: "Missing import detected for axios."

SOFTWARE TUTOR RULES
AURA should teach like a smart mentor. GOOD: "Use Adjustment Layers instead of editing directly."

MARKDOWN RULES
Use markdown minimally. Allowed: short bullet points, clean code blocks, small headings. Avoid: excessive bold, excessive stars, giant separators.

VOICE RESPONSE RULES
Voice replies should sound calm, intelligent, be short, and avoid robotic phrasing.

ERROR HANDLING RULES
If backend fails: GOOD: "AURA lost connection. Retrying..." BAD: "Fatal websocket runtime exception."

CODE RESPONSE RULES
Code explanations should explain issue, explain fix, provide optimized solution, avoid unnecessary theory. Structure: Problem, Fix, Code, Why it works.

WORKFLOW COPILOT RULES
AURA should proactively help. GOOD: "Your export bitrate may reduce video quality."

UI RESPONSE RULES
Overlay UI text must be minimal, premium, futuristic, readable. GOOD: "AURA ready" BAD: "Realtime neural overlay initialized."

PERSONALITY RULES
AURA personality is calm, intelligent, futuristic, helpful, non-corporate, non-annoying.

FINAL RESPONSE STANDARD
"A smart realtime AI copilot integrated into the user's workflow."
"""

# Status strings that must never appear in the UI (internal pipeline only)
_SUPPRESS_STATUS_KEYWORDS = (
    "searching",
    "compiling",
    "structuring",
    "synthesizing",
    "analyzing",
    "gateway",
    "ingestion",
    "neural memory",
    "static",
    "congested",
    "rendering",
    "canvas",
    "visual concepts",
    "handshake",
    "cognitive pathway",
    "connection issue",
    "using local",
    "research",
    "live summaries",
    "synchronized",
)


def internal_datetime_context() -> str:
    """For system prompt only — never instruct the model to repeat this to users."""
    return datetime.utcnow().strftime("%B %d, %Y %H:%M UTC")


def user_facing_status(raw: str, overlay_mode: bool = False) -> Optional[str]:
    """
    Map internal pipeline status to user-safe text.
    Returns None to suppress the status event entirely.
    """
    if overlay_mode:
        return None
    if not raw or not str(raw).strip():
        return None
    lower = str(raw).lower().strip()
    if any(k in lower for k in _SUPPRESS_STATUS_KEYWORDS):
        return None
    if lower in ("replying...", "thinking...", "connecting..."):
        return None
    return None


def format_live_data_block(research_context: str) -> str:
    """Inject live search results without a header the model might quote."""
    if not research_context or not research_context.strip():
        return ""
    return (
        "INTERNAL LIVE DATA (use as facts; do not mention this block or how you got it):\n"
        f"{research_context.strip()}"
    )


def strip_robotic_preamble(text: str) -> str:
    """Remove common meta openers the model might emit despite instructions."""
    if not text:
        return text
    lines = text.split("\n")
    skip_patterns = (
        "current date",
        "today's date",
        "the current year",
        "searching",
        "looking up",
        "let me search",
        "i'll search",
        "using realtime",
        "using real-time",
        "fetching live",
        "based on my search",
        "after searching",
    )
    while lines:
        head = lines[0].strip().lower()
        if not head:
            lines.pop(0)
            continue
        if any(head.startswith(p) or p in head[:80] for p in skip_patterns):
            lines.pop(0)
            continue
        break
    return "\n".join(lines).lstrip()
