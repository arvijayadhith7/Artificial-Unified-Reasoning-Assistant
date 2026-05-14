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
                # Use text search for general queries (faster and more stable)
                # We use the 'wt-wt' region for global results
                ddgs_gen = ddgs.text(query, region='wt-wt', safesearch='moderate', timelimit=None, max_results=max_results)
                
                for r in ddgs_gen:
                    results.append({
                        'title': r.get('title', 'Unknown Source'),
                        'body': r.get('body', ''),
                        'href': r.get('href', '#')
                    })
            
            if not results:
                # Quick fallback to news if general text returns nothing
                with DDGS() as ddgs:
                    news_gen = ddgs.news(query, region='wt-wt', safesearch='moderate', timelimit='d', max_results=max_results)
                    for r in news_gen:
                        results.append({
                            'title': r.get('title', 'News Source'),
                            'body': r.get('body', ''),
                            'href': r.get('url', '#')
                        })

            if not results:
                return "AURA Intelligence: No rapid data clusters found for this query."
                
            formatted = []
            seen_urls = set()
            for r in results:
                if len(formatted) >= max_results: break
                title = r['title']
                body = r['body']
                href = r['href']
                
                if href not in seen_urls:
                    formatted.append(f"Source: {title}\nURL: {href}\nSnippet: {body}\n")
                    seen_urls.add(href)
            
            return "\n".join(formatted)
        except Exception as e:
            print(f"Research Speed Error: {e}")
            return f"AURA Neural Link: Research interrupted by speed gateway ({str(e)})."

    def get_cricket_scores(self):
        """Fast helper for live cricket/IPL updates."""
        return self.search_live("IPL match live score today", max_results=3)


