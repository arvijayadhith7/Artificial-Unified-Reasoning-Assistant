import os
import time
from duckduckgo_search import DDGS

class ResearchAgent:
    """High-speed Agent plugin for real-time web intelligence using DuckDuckGo."""
    
    def __init__(self):
        # Initializing DDGS for compatibility with main.py research socket
        self.ddgs = DDGS()


    def search_live(self, query: str, max_results: int = 5):
        """Ultra-fast live web search using DuckDuckGo (Primary & Only)."""
        try:
            print(f"NEURAL RESEARCH: Rapid scanning for '{query}'...")
            results = []
            
            with DDGS() as ddgs:
                # 403 Ratelimit Guard: Shorten and sanitize the query
                safe_query = " ".join(query.split()[:6])
                print(f"NEURAL SEARCH: Stealth scanning for '{safe_query}'...")
                
                try:
                    # Optimized Retrieval without the high-latency news fallback
                    ddgs_gen = ddgs.text(safe_query, region='wt-wt', safesearch='moderate', max_results=max_results)
                    for r in ddgs_gen:
                        priority = 1
                        href = r.get('href', '')
                        if any(domain in href for domain in ['github.com', 'wikipedia.org', 'reuters.com', 'espncricinfo.com', 'espn.in', 'official', 'docs.']):
                            priority = 2
                        
                        results.append({
                            'title': r.get('title', 'Source'),
                            'body': r.get('body', ''),
                            'href': href,
                            'priority': priority
                        })
                except Exception as e:
                    print(f"Search Rate Limit Hit: {e}")
                    return "AURA Sync: Neural Search gateway is currently rate-limited. Relying on internal knowledge base for instant response."

            if not results:
                return "AURA Intelligence: Neural data sync delayed. Proceeding with knowledge-base analysis."
                
            # Neural Sort: Deliver the most verified data first
            results.sort(key=lambda x: x['priority'], reverse=True)
            
            formatted = []
            seen_urls = set()
            for r in results:
                if len(formatted) >= max_results: break
                if r['href'] not in seen_urls:
                    formatted.append(f"Source: {r['title']}\nURL: {r['href']}\nSnippet: {r['body']}\n")
                    seen_urls.add(r['href'])


            
            return "\n".join(formatted)
        except Exception as e:
            print(f"Research Speed Error: {e}")
            return f"AURA Neural Link: Research interrupted by speed gateway ({str(e)})."

    def get_cricket_scores(self):
        """Fast helper for live cricket/IPL updates."""
        return self.search_live("IPL match live score today", max_results=3)


