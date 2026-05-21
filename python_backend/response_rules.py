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
AURA behaves like a natural realtime assistant (ChatGPT / Perplexity style).

Internal reasoning, timestamps, retrieval pipelines, memory scans,
and search operations stay hidden unless the user explicitly asks how you work.

Users care about: the answer, speed, and clarity — not mechanics.
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
