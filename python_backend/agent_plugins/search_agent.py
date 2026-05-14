import random
import urllib.parse
import requests
from bs4 import BeautifulSoup
from duckduckgo_search import DDGS

class ResearchAgent:
    """High-speed Agent plugin for real-time web intelligence using Multi-Engine Fallback."""
    
    def __init__(self):
        # Initializing DDGS for compatibility with main.py research socket
        self.ddgs = DDGS()
        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
        ]

    def search_live(self, query: str, max_results: int = 5):
        """Resilient multi-engine search with fallback logic to bypass rate limits."""
        try:
            print(f"NEURAL RESEARCH: Multi-engine scanning for '{query}'...")
            results = []
            
            with DDGS() as ddgs:
                safe_query = " ".join(query.split()[:6])
                ddgs_gen = ddgs.text(safe_query, region='wt-wt', safesearch='moderate', max_results=max_results)
                for r in ddgs_gen:
                    results.append({'title': r.get('title', 'Source'), 'body': r.get('body', ''), 'href': r.get('href', '#'), 'priority': 2})
        except Exception as e:
            print(f"DDG Search Gateway Blocked: {e}")

        # 2. Secondary Fallback: Google Scraper (High Resilience)
        if not results:
            try:
                headers = {"User-Agent": random.choice(self.user_agents)}
                google_url = f"https://www.google.com/search?q={urllib.parse.quote(query)}"
                response = requests.get(google_url, headers=headers, timeout=5)
                if response.status_code == 200:
                    soup = BeautifulSoup(response.text, 'html.parser')
                    for g in soup.find_all('div', class_='g')[:max_results]:
                        anchors = g.find_all('a')
                        if anchors:
                            link = anchors[0]['href']
                            title = g.find('h3').text if g.find('h3') else 'Google Source'
                            snippet = g.find('div', class_='VwiC3b').text if g.find('div', class_='VwiC3b') else ''
                            results.append({'title': title, 'body': snippet, 'href': link, 'priority': 1})
            except Exception as ge:
                print(f"Google Fallback Blocked: {ge}")


        if not results:
            return "AURA Intelligence: Global search gateways are currently congested. Relying on verified neural knowledge base."

        # Neural Sort & Format
        results.sort(key=lambda x: x.get('priority', 1), reverse=True)
        formatted = []
        seen_urls = set()
        for r in results:
            if len(formatted) >= max_results: break
            if r['href'] not in seen_urls:
                formatted.append(f"Source: {r['title']}\nURL: {r['href']}\nSnippet: {r['body']}\n")
                seen_urls.add(r['href'])
        
        return "\n".join(formatted)


    def get_cricket_scores(self):
        """Fast helper for live cricket/IPL updates."""
        return self.search_live("IPL match live score today", max_results=3)
