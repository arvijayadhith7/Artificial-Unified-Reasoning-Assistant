import os
from groq import Groq as GroqClient
from groq import AsyncGroq

class RefinerAgent:
    """Agent plugin for high-fidelity neural polishing and fine-tuning of AI responses.
    
    Supports both synchronous and asynchronous completion streaming.
    """
    
    def __init__(self, groq_client=None):
        self.groq = groq_client or GroqClient(api_key=os.environ.get("GROQ_API_KEY"))
        # Automatically set up an async Groq client for asynchronous streams
        key = os.environ.get("GROQ_API_KEY")
        self.async_groq = AsyncGroq(api_key=key) if key else None

    def refine_stream(self, draft_text, context="General strategic advice.", research_data=""):
        """Stream a refined version of the draft text synchronously."""
        refine_prompt = self._build_prompt(draft_text, context, research_data=research_data)
        try:
            response = self.groq.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": refine_prompt}],
                temperature=0.3,
                max_tokens=2048,
                stream=True
            )
            for chunk in response:
                if chunk.choices and chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content
        except Exception as e:
            print(f"Refinement Stream Error: {e}")
            yield draft_text  # Fallback to draft if refinement fails

    async def refine_stream_async(self, draft_text, context="General strategic advice.", research_data=""):
        """Stream a refined version of the draft text asynchronously."""
        refine_prompt = self._build_prompt(draft_text, context, research_data=research_data)
        client = self.async_groq or AsyncGroq(api_key=os.environ.get("GROQ_API_KEY"))
        try:
            response = await client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": refine_prompt}],
                temperature=0.3,
                max_tokens=2048,
                stream=True
            )
            async for chunk in response:
                if chunk.choices and chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content
        except Exception as e:
            print(f"Refinement Async Stream Error: {e}")
            yield draft_text  # Fallback to draft if refinement fails

    def _build_prompt(self, draft_text, context, research_data=""):
        research_block = ""
        if research_data:
            research_block = f"""
LIVE RESEARCH DATA (VERIFIED, REAL-TIME — TRUST THIS DATA COMPLETELY):
{research_data[:3000]}
"""
        return f"""You are a world-class editor. Polish the following draft into a clean, highly conversational response.

CONTEXT: {context}
{research_block}
DRAFT: {draft_text}

STRICT EDITING RULES:
1. Speak naturally like a warm, calm, friendly, and highly intelligent human assistant.
2. NEVER use robotic, technical, or sci-fi headings like "DIRECT ANALYSIS", "OPTIMIZED SOLUTION", "NEURAL IMPROVEMENTS", or "COGNITIVE TRACE".
3. NEVER use machine jargon or fake AI words like "vectors", "clusters", "latency reduction", "emotional intelligence clusters", "context mapping", or "neural processing."
4. Start with a direct answer to the user's question. Be clean, concise, and modern.
5. If the draft contains simple casual conversation, keep the polished response extremely simple, warm, and friendly (e.g. "Hey! 👋").
6. Use natural markdown: bold text for emphasis and clean bullet points for scannability.
7. DO NOT mention that you are refining, editing, or thinking. Just return the clean, polished final answer.
8. CRITICAL: NEVER say "I am a large language model", "my training data is up to", "I don't have access to real-time data", or "my knowledge cutoff is". You DO have live data — it is provided above as LIVE RESEARCH DATA. USE IT.
9. NEVER mention the current date/year or say you are searching the web. Answer directly and naturally.
9. CRITICAL: ALL facts, scores, names, dates, and statistics from the DRAFT must be preserved exactly. Do NOT replace real-time data with your own training knowledge. The draft contains verified live information — trust it completely.
10. If the draft references live scores, news, or current events, present them confidently as current facts.

POLISHED RESPONSE:"""
