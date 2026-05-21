import os
import json
import re
from typing import Dict, Any

GROQ_VISION_MODEL = "meta-llama/llama-4-scout-17b-16e-instruct"
OVERLAY_SLM_MODEL = "llama-3.1-8b-instant"

def parse_json_robust(text: str) -> Dict[str, Any]:
    text = text.strip()
    # Remove markdown code block wrappers if present
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\n", "", text)
        text = re.sub(r"\n```$", "", text)
    text = text.strip()
    
    try:
        return json.loads(text)
    except Exception:
        # Fallback regex extraction
        match = re.search(r"(\{.*\})", text, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(1))
            except Exception:
                pass
    raise ValueError("Failed to parse JSON response from LLM")

def get_local_fallback_context(active_app: str, window_title: str, accessibility_text: str) -> dict:
    try:
        from overlay_engine import classify_workflow
        workflow = classify_workflow(active_app, window_title, accessibility_text)
    except ImportError:
        workflow = "general"
    
    app_display = (active_app or "Desktop").split(".")[0].capitalize()
    detected = [f"App: {app_display}"]
    if window_title:
        title_clean = window_title.strip()
        if len(title_clean) > 25:
            title_clean = title_clean[:22] + "..."
        detected.append(title_clean)
        
    suggestions = []
    if workflow == "vscode":
        detected.append("VS Code")
        suggestions = [
            {"label": "Explain Code", "prompt": "Analyze the active code block on screen and explain it step-by-step."},
            {"label": "Find Syntax Errors", "prompt": "Check the visible code for syntax errors or anti-patterns."},
            {"label": "Refactor Function", "prompt": "Suggest clean optimization and refactoring for the active function."}
        ]
    elif workflow == "photoshop":
        detected.append("Photoshop")
        suggestions = [
            {"label": "Blending Guide", "prompt": "How do I use layer styles and masks for seamless blending?"},
            {"label": "Selection Tools", "prompt": "Explain which selection tools are best for complex cutouts."},
            {"label": "Color Correction", "prompt": "Suggest step-by-step curves adjustments for a moody photo."}
        ]
    elif workflow == "excel":
        detected.append("Excel")
        suggestions = [
            {"label": "Lookup Formulas", "prompt": "Explain VLOOKUP and XLOOKUP parameters with examples."},
            {"label": "Create Pivot Table", "prompt": "How do I build a dynamic pivot table from raw data?"},
            {"label": "Write Macro", "prompt": "Write a basic VBA script to format new rows automatically."}
        ]
    elif workflow == "browser":
        detected.append("Browser Page")
        suggestions = [
            {"label": "Summarize Article", "prompt": "Provide a high-level summary of the active webpage/article."},
            {"label": "Explain Page", "prompt": "Explain the key concepts of the visible web page in simple terms."},
            {"label": "Extract Actions", "prompt": "Extract the key action items or guides from this page."}
        ]
    else:
        detected.append("AI Copilot")
        suggestions = [
            {"label": "Analyze Screen", "prompt": "Explain what's currently visible on this screen and suggest next steps."},
            {"label": "Summarize Context", "prompt": "Draft a concise summary of the active task on my screen."},
            {"label": "Optimize Layout", "prompt": "How can I improve my workspace structure to boost focus?"}
        ]
        
    return {
        "detected_items": detected,
        "suggestions": suggestions
    }

async def analyze_screen_context(
    active_app: str,
    window_title: str,
    accessibility_text: str,
    screenshot_b64: str = None
) -> dict:
    # Attempt import of client
    try:
        from main import async_groq_client
        client = async_groq_client
    except ImportError:
        client = None

    if not client:
        print("AURA Context Engine: Groq client unavailable. Using fallback.")
        return get_local_fallback_context(active_app, window_title, accessibility_text)

    system_prompt = """You are AURA Context Engine, a system-level real-time screen analysis service.
Your job is to analyze the user's active screen/window context and return a structured JSON response.

Detect:
1. The active application and sub-elements (e.g., active page title, current form fields, code errors, edit tools, etc.).
2. The user's likely intent or current problem based on the visual screen content, accessibility text, or window title.

Generate 3-4 highly action-oriented, contextual suggestions (short chips) that the user can tap to execute a task.
Be exceptionally direct, helpful, and premium. Avoid generic options.
Suggestions must be tailored to what is visible. For example:
- In VS Code with a syntax error: suggestion "Explain error in auth_service.ts"
- In Chrome reading an article: suggestion "Summarize this article"
- In Photoshop editing: suggestion "Blend layers smoothly"
- In a Login form: suggestion "Auto-generate secure password" or "Resolve password error"

Output MUST be a JSON object with this exact schema:
{
  "detected_items": ["tag1", "tag2", "tag3"],
  "suggestions": [
    {"label": "Short Action Button Label", "prompt": "The detailed query that is executed when user clicks this button"}
  ]
}
Do not write any markdown wrappers, preambles, or postambles. Output ONLY valid JSON."""

    try:
        has_img = bool(screenshot_b64)
        model = GROQ_VISION_MODEL if has_img else OVERLAY_SLM_MODEL
        
        user_content = f"Active App: {active_app or 'Unknown'}\nWindow Title: {window_title or 'Unknown'}\nAccessibility Text: {accessibility_text or ''}"
        
        if has_img:
            messages = [
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": user_content},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{screenshot_b64}"
                            }
                        }
                    ]
                }
            ]
        else:
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content}
            ]

        # Call Groq
        response = await client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0.2,
            max_tokens=600,
            response_format={"type": "json_object"} if not has_img else None # Vision doesn't always support json_object mode
        )
        
        raw_text = response.choices[0].message.content
        res = parse_json_robust(raw_text)
        
        # Ensure correct structure
        if "detected_items" in res and "suggestions" in res:
            # Shorten detected items tags for UI display
            res["detected_items"] = [str(x)[:25] for x in res["detected_items"]][:4]
            # Ensure suggestions is list of dicts
            clean_sug = []
            for item in res["suggestions"]:
                if isinstance(item, dict) and "label" in item and "prompt" in item:
                    # Clean length
                    item["label"] = str(item["label"])[:25]
                    clean_sug.append(item)
                elif isinstance(item, str):
                    clean_sug.append({"label": item[:25], "prompt": item})
            res["suggestions"] = clean_sug[:4]
            return res
            
    except Exception as e:
        print(f"AURA Context Engine error: {e}. Using fallback.")
        
    return get_local_fallback_context(active_app, window_title, accessibility_text)
