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
                # Optimized High-Speed Retrieval with Priority Ranking
                ddgs_gen = ddgs.text(query, region='wt-wt', safesearch='moderate', max_results=max_results)
                for r in ddgs_gen:
                    # Verification Layer: Prioritize authoritative sources
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
                
                if not results:
                    news_gen = ddgs.news(query, region='wt-wt', safesearch='moderate', max_results=max_results)
                    for r in news_gen:
                        results.append({
                            'title': r.get('title', 'News'),
                            'body': r.get('body', ''),
                            'href': r.get('url', '#'),
                            'priority': 1
                        })

            if not results:
                return "AURA Intelligence: No rapid data clusters found. Defaulting to knowledge-base reasoning."
                
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


