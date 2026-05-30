import os
import re
import time
import math
import random
import asyncio
import httpx
import urllib.parse
from bs4 import BeautifulSoup

# Use modern ddgs package (v9+) — the old duckduckgo_search is deprecated and returns 0 results
try:
    from ddgs import DDGS
except ImportError:
    DDGS = None

class ResearchAgent:
    """Production-Grade Real-Time AI Search Orchestrator for AURA AI.
    
    Primary: DuckDuckGo (via ddgs v9+), DDG HTML scraper, SearXNG, Google scraper.
    Implements: Async retrieval, retries, chunking, and TF-IDF semantic reranking.
    """
    
    def __init__(self):
        # Read API Keys from environment
        self.tavily_key = os.getenv("TAVILY_API_KEY")
        self.exa_key = os.getenv("EXA_API_KEY")
        self.serper_key = os.getenv("SERPER_API_KEY")
        self.brave_key = os.getenv("BRAVE_API_KEY")
        self.serpapi_key = os.getenv("SERPAPI_API_KEY")
        self.firecrawl_key = os.getenv("FIRECRAWL_API_KEY")
        
        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        ]

    # ==========================================
    # 1. SYNCHRONOUS RETRIEVAL (Legacy Support)
    # ==========================================
    def search_live(self, query: str, max_results: int = 5) -> str:
        """Ultra-resilient synchronous search using API providers, DuckDuckGo, static HTML fallback, and scraper fallback to ensure 24/7 service availability.
        """
        print(f"NEURAL RESEARCH GATEWAY (SYNC): Orchestrating search query: '{query}'")
        
        results = []
        clean_query = query.replace('"', '').strip()
        
        # 1. DuckDuckGo Primary API (Tavily completely removed and replaced by DDG)
        if not results:
            results = self._search_ddg_sync(clean_query, max_results)
            
        # 2. DuckDuckGo Static HTML Scraper Fallback (resilient fallback)
        if not results:
            results = self._search_ddg_html_sync(clean_query, max_results)

        # 3. AOL Search Scraper Fallback (Highly resilient in cloud environments)
        if not results:
            results = self._search_aol_sync(clean_query, max_results)

        # 4. Exa API
        if not results and self.exa_key:
            results = self._search_exa_sync(clean_query, max_results)

        # 5. SerpAPI
        if not results and self.serpapi_key:
            results = self._search_serpapi_sync(clean_query, max_results)

        # 6. Firecrawl
        if not results and self.firecrawl_key:
            results = self._search_firecrawl_sync(clean_query, max_results)

        # 7. Serper API
        if not results and self.serper_key:
            results = self._search_serper_sync(clean_query, max_results)

        # 8. Brave API
        if not results and self.brave_key:
            results = self._search_brave_sync(clean_query, max_results)
            
        # 9. SearXNG Fallback (Synchronous)
        if not results:
            results = self._search_searxng_sync(clean_query, max_results)
            
        # 10. Google Scraper Fallback
        if not results:
            results = self._search_google_scrape_sync(clean_query, max_results)
            
        if not results:
            return "NO_DATA: Live search gateways are currently congested. Relying on neural knowledge base."

        # Apply Advanced Context Chunking & TF-IDF Reranking
        compressed_context = self.chunk_and_rerank(query, results, max_results=max_results)
        return compressed_context

    # ==========================================
    # 2. ASYNCHRONOUS RETRIEVAL (Modern Pipeline)
    # ==========================================
    async def search_live_async(self, query: str, max_results: int = 5, search_strategy: str = "multi-tier") -> str:
        """Fully non-blocking asynchronous search with multi-provider cascade."""
        print(f"NEURAL RESEARCH GATEWAY (ASYNC): Scanning network for: '{query}' with strategy: '{search_strategy}'")
        clean_query = query.replace('"', '').strip()
        results = []

        if search_strategy == "local-only":
            return "NO_DATA: Local cache only mode active. Web search disabled."
        
        # If pure-api strategy is specified, only use DuckDuckGo API
        if search_strategy == "pure-api":
            results = await self._search_ddg_async(clean_query, max_results)
            if not results and self.exa_key:
                results = await self._search_exa_async(clean_query, max_results)
            if not results and self.serpapi_key:
                results = await self._search_serpapi_async(clean_query, max_results)
            if not results and self.firecrawl_key:
                results = await self._search_firecrawl_async(clean_query, max_results)
            if not results:
                return "NO_DATA: DuckDuckGo API search returned empty results."
            return self.chunk_and_rerank(query, results, max_results=max_results)

        # Standard Multi-tier strategy (Full resilient cascade)
        # 1. DuckDuckGo API (Primary)
        if not results:
            results = await self._search_ddg_async(clean_query, max_results)

        # 2. DuckDuckGo HTML Scraper Fallback
        if not results:
            results = await self._search_ddg_html_async(clean_query, max_results)

        # 3. AOL Search Scraper Fallback (Highly resilient in cloud environments)
        if not results:
            results = await self._search_aol_async(clean_query, max_results)

        # 4. Exa (if key available)
        if not results and self.exa_key:
            results = await self._search_exa_async(clean_query, max_results)

        # 4. SerpAPI (if key available)
        if not results and self.serpapi_key:
            results = await self._search_serpapi_async(clean_query, max_results)

        # 5. Firecrawl (if key available)
        if not results and self.firecrawl_key:
            results = await self._search_firecrawl_async(clean_query, max_results)

        # 6. Serper (if key available)
        if not results and self.serper_key:
            results = await self._search_serper_async(clean_query, max_results)

        # 7. Brave (if key available)
        if not results and self.brave_key:
            results = await self._search_brave_async(clean_query, max_results)
        
        # 8. SearXNG Public Instance Fallback (works from cloud servers)
        if not results:
            results = await self._search_searxng_async(clean_query, max_results)
            
        # 9. Google Scrape Fallback
        if not results:
            results = await self._search_google_scrape_async(clean_query, max_results)
            
        if not results:
            return "NO_DATA: All search gateways exhausted. Relying on neural knowledge base."

        # Dynamic Enrichment: Crawl top 3 URLs using Splash for richer context
        if results and os.getenv("SPLASH_ENABLED", "true").lower() == "true":
            print(f"NEURAL RESEARCH [SPLASH]: Enriched crawling of top pages active.")
            tasks = []
            top_results = results[:3]
            for r in top_results:
                url = r.get('href', '#')
                if url.startswith('http'):
                    tasks.append(self._scrape_page_with_splash(url))
            
            if tasks:
                scraped_contents = await asyncio.gather(*tasks)
                for idx, content in enumerate(scraped_contents):
                    if content and len(content.strip()) > 100:
                        print(f"Splash successfully crawled: {top_results[idx]['href']} ({len(content)} chars)")
                        # Replace snippet body with the rich full page content
                        top_results[idx]['body'] = content[:5000]

        # Rerank and Compress
        return self.chunk_and_rerank(query, results, max_results=max_results)

    # ==========================================
    # 3. CHUNKING & TF-IDF RERANKING
    # ==========================================
    def chunk_and_rerank(self, query: str, results: list, max_results: int = 5) -> str:
        """Splits search snippets into clean, overlapping passages,
        performs TF-IDF relevance scoring against user query,
        deduplicates content, and returns a high-density consolidated context.
        """
        chunks = []
        seen_urls = {}
        
        # 1. Basic Chunking: split snippets/bodies into 400-char chunks with overlap
        for r in results:
            url = r.get('href', '#')
            title = r.get('title', 'Web Source')
            body = r.get('body', '')
            
            if not body: continue
            
            # Store title mapping for referencing
            seen_urls[url] = title
            
            # Simple sentence/window chunking
            words = body.split()
            chunk_size = 60
            overlap = 15
            
            for i in range(0, len(words), chunk_size - overlap):
                chunk_words = words[i:i + chunk_size]
                if len(chunk_words) < 10: continue # Skip tiny fragments
                chunk_text = " ".join(chunk_words)
                chunks.append({
                    'text': chunk_text,
                    'url': url,
                    'title': title
                })
                
        if not chunks:
            # Fallback if chunking produced nothing
            formatted = []
            seen = set()
            for r in results[:max_results]:
                if r['href'] not in seen:
                    formatted.append(f"Source: {r['title']}\nURL: {r['href']}\nSnippet: {r['body']}\n")
                    seen.add(r['href'])
            return "\n".join(formatted)

        # 2. Pure-Python TF-IDF Relevance Scoring
        def tokenize(text):
            return re.findall(r'\w+', text.lower())

        query_tokens = set(tokenize(query))
        if not query_tokens:
            # Sort by search priority if query is untokenizable
            chunks = chunks[:max_results]
        else:
            # Calculate IDF for terms
            doc_tokens_list = [tokenize(c['text']) for c in chunks]
            idf = {}
            N = len(chunks)
            for token in query_tokens:
                df = sum(1 for doc_tokens in doc_tokens_list if token in doc_tokens)
                # Smooth IDF calculation
                idf[token] = math.log((N - df + 0.5) / (df + 0.5) + 1.0)
                
            # Score chunks
            for i, c in enumerate(chunks):
                doc_tokens = doc_tokens_list[i]
                if not doc_tokens:
                    c['score'] = 0.0
                    continue
                score = 0.0
                doc_len = len(doc_tokens)
                for token in query_tokens:
                    tf = doc_tokens.count(token) / doc_len
                    score += tf * idf.get(token, 0.0)
                c['score'] = score
                
            # Sort by TF-IDF relevance score descending
            chunks.sort(key=lambda x: x.get('score', 0.0), reverse=True)

        # 3. Deduplication & Consolidation (Select top compressed chunks)
        formatted_passages = []
        selected_urls = set()
        
        for c in chunks[:8]: # Grab top 8 relevant chunks max to avoid prompt overflow
            text = c['text']
            url = c['url']
            title = c['title']
            
            # Simple content overlap check
            duplicate = False
            for p in formatted_passages:
                # If 60% of words in this chunk are already present in another selected chunk, skip it
                common = set(tokenize(text)) & set(tokenize(p))
                if len(common) > len(tokenize(text)) * 0.6:
                    duplicate = True
                    break
            
            if not duplicate:
                formatted_passages.append(f"Source: {title}\nURL: {url}\nPassage: {text}\n")
                selected_urls.add(url)
                
        return "\n".join(formatted_passages)

    # ==========================================
    # 4. SYNCHRONOUS PROVIDER INTEGRATIONS
    # ==========================================
    def _search_tavily_sync(self, query: str, max_results: int) -> list:
        try:
            print("NEURAL RESEARCH [TAVILY-SYNC]: Initiating...")
            r = httpx.post(
                "https://api.tavily.com/search",
                json={"api_key": self.tavily_key, "query": query, "search_depth": "basic", "max_results": max_results},
                timeout=8.0
            )
            if r.status_code == 200:
                return [{'title': x.get('title', 'Tavily Source'), 'body': x.get('content', ''), 'href': x.get('url', '#')} for x in r.json().get('results', [])]
        except Exception as e:
            print(f"Tavily Sync Fail: {e}")
        return []

    def _search_exa_sync(self, query: str, max_results: int) -> list:
        try:
            print("NEURAL RESEARCH [EXA-SYNC]: Initiating...")
            headers = {"x-api-key": self.exa_key, "content-type": "application/json"}
            r = httpx.post("https://api.exa.ai/search", json={"query": query, "numResults": max_results, "useAutoprompt": True}, headers=headers, timeout=8.0)
            if r.status_code == 200:
                return [{'title': x.get('title', 'Exa Source'), 'body': x.get('text', x.get('highlights', [''])[0]), 'href': x.get('url', '#')} for x in r.json().get('results', [])]
        except Exception as e:
            print(f"Exa Sync Fail: {e}")
        return []

    def _search_serper_sync(self, query: str, max_results: int) -> list:
        try:
            print("NEURAL RESEARCH [SERPER-SYNC]: Initiating...")
            headers = {"X-API-KEY": self.serper_key, "Content-Type": "application/json"}
            r = httpx.post("https://google.serper.dev/search", json={"q": query, "num": max_results}, headers=headers, timeout=8.0)
            if r.status_code == 200:
                return [{'title': x.get('title', 'Serper Source'), 'body': x.get('snippet', ''), 'href': x.get('link', '#')} for x in r.json().get('organic', [])]
        except Exception as e:
            print(f"Serper Sync Fail: {e}")
        return []

    def _search_brave_sync(self, query: str, max_results: int) -> list:
        try:
            print("NEURAL RESEARCH [BRAVE-SYNC]: Initiating...")
            headers = {"Accept": "application/json", "X-Subscription-Token": self.brave_key}
            r = httpx.get(f"https://api.search.brave.com/res/v1/web/search?q={urllib.parse.quote(query)}&count={max_results}", headers=headers, timeout=8.0)
            if r.status_code == 200:
                return [{'title': x.get('title', 'Brave Source'), 'body': x.get('description', ''), 'href': x.get('url', '#')} for x in r.json().get('web', {}).get('results', [])]
        except Exception as e:
            print(f"Brave Sync Fail: {e}")
        return []

    def _search_ddg_sync(self, query: str, max_results: int) -> list:
        if DDGS is None:
            print("NEURAL RESEARCH [DDG-SYNC]: DDGS library not available. Install with: pip install ddgs")
            return []
        # Retry up to 2 times with fresh DDGS instance
        for attempt in range(2):
            try:
                print(f"NEURAL RESEARCH [DDG-SYNC]: Attempt {attempt + 1}...")
                ddgs = DDGS()
                raw_results = ddgs.text(query, max_results=max_results)
                if raw_results and isinstance(raw_results, list):
                    results = []
                    for r in raw_results:
                        results.append({
                            'title': r.get('title', 'DDG Source'),
                            'body': r.get('body', ''),
                            'href': r.get('href', '#')
                        })
                    if results:
                        print(f"DDG-SYNC Success: {len(results)} results")
                        return results
            except Exception as e:
                print(f"DDG Sync Attempt {attempt + 1} Fail: {e}")
                time.sleep(0.5)
        return []

    def _search_ddg_html_sync(self, query: str, max_results: int) -> list:
        try:
            print("NEURAL RESEARCH [DDG-HTML-SCRAPE]: Initiating...")
            headers = {
                "User-Agent": random.choice(self.user_agents),
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.5"
            }
            url = f"https://html.duckduckgo.com/html/?q={urllib.parse.quote(query)}"
            r = httpx.get(url, headers=headers, timeout=6.0, follow_redirects=True)
            if r.status_code == 200:
                soup = BeautifulSoup(r.text, 'html.parser')
                results = []
                for res_div in soup.find_all('div', class_='result')[:max_results]:
                    title_a = res_div.find('a', class_='result__url')
                    snippet_a = res_div.find('a', class_='result__snippet')
                    if title_a:
                        title = title_a.text.strip()
                        href = title_a['href']
                        # Decode DDG redirection URL if necessary
                        if href.startswith('//duckduckgo.com/y.js'):
                            parsed = urllib.parse.urlparse(href)
                            params = urllib.parse.parse_qs(parsed.query)
                            if 'uddg' in params:
                                href = params['uddg'][0]
                            else:
                                href = "https:" + href
                        elif href.startswith('/'):
                            href = "https://duckduckgo.com" + href
                        
                        body = snippet_a.text.strip() if snippet_a else ""
                        results.append({'title': title, 'body': body, 'href': href})
                print(f"DDG-HTML-SCRAPE Success: Found {len(results)} results.")
                return results
        except Exception as e:
            print(f"DDG HTML Scrape Fail: {e}")
        return []

    def _search_google_scrape_sync(self, query: str, max_results: int) -> list:
        try:
            print("NEURAL RESEARCH [SCRAPE-SYNC]: Initiating...")
            headers = {"User-Agent": random.choice(self.user_agents)}
            google_url = f"https://www.google.com/search?q={urllib.parse.quote(query)}"
            r = httpx.get(google_url, headers=headers, timeout=5.0)
            if r.status_code == 200:
                soup = BeautifulSoup(r.text, 'html.parser')
                results = []
                for g in soup.find_all('div', class_='g')[:max_results]:
                    anchors = g.find_all('a')
                    if anchors:
                        results.append({
                            'title': g.find('h3').text if g.find('h3') else 'Google Source',
                            'body': g.find('div', class_='VwiC3b').text if g.find('div', class_='VwiC3b') else '',
                            'href': anchors[0]['href']
                        })
                return results
        except Exception as e:
            print(f"Google Scrape Sync Fail: {e}")
        return []

    def _search_serpapi_sync(self, query: str, max_results: int) -> list:
        try:
            print("NEURAL RESEARCH [SERPAPI-SYNC]: Initiating...")
            r = httpx.get(
                "https://serpapi.com/search.json",
                params={"q": query, "api_key": self.serpapi_key, "num": max_results},
                timeout=8.0
            )
            if r.status_code == 200:
                results = []
                for x in r.json().get('organic_results', [])[:max_results]:
                    results.append({
                        'title': x.get('title', 'SerpAPI Source'),
                        'body': x.get('snippet', ''),
                        'href': x.get('link', '#')
                    })
                return results
        except Exception as e:
            print(f"SerpAPI Sync Fail: {e}")
        return []

    def _search_firecrawl_sync(self, query: str, max_results: int) -> list:
        try:
            print("NEURAL RESEARCH [FIRECRAWL-SYNC]: Initiating...")
            headers = {
                "Authorization": f"Bearer {self.firecrawl_key}",
                "Content-Type": "application/json"
            }
            r = httpx.post(
                "https://api.firecrawl.dev/v0/search",
                json={"query": query, "pageOptions": {"onlyMainContent": true}},
                headers=headers,
                timeout=12.0
            )
            if r.status_code == 200:
                results = []
                for x in r.json().get('data', [])[:max_results]:
                    results.append({
                        'title': x.get('metadata', {}).get('title', 'Firecrawl Source'),
                        'body': x.get('content', x.get('markdown', '')),
                        'href': x.get('metadata', {}).get('sourceURL', '#')
                    })
                return results
        except Exception as e:
            print(f"Firecrawl Sync Fail: {e}")
        return []

    # ==========================================
    # 5. ASYNCHRONOUS PROVIDER INTEGRATIONS
    # ==========================================
    async def _search_tavily_async(self, query: str, max_results: int) -> list:
        try:
            async with httpx.AsyncClient() as client:
                r = await client.post(
                    "https://api.tavily.com/search",
                    json={"api_key": self.tavily_key, "query": query, "search_depth": "basic", "max_results": max_results},
                    timeout=8.0
                )
                if r.status_code == 200:
                    return [{'title': x.get('title', 'Tavily Source'), 'body': x.get('content', ''), 'href': x.get('url', '#')} for x in r.json().get('results', [])]
        except Exception as e:
            print(f"Tavily Async Fail: {e}")
        return []

    async def _search_exa_async(self, query: str, max_results: int) -> list:
        try:
            headers = {"x-api-key": self.exa_key, "content-type": "application/json"}
            async with httpx.AsyncClient() as client:
                r = await client.post(
                    "https://api.exa.ai/search",
                    json={"query": query, "numResults": max_results, "useAutoprompt": True},
                    headers=headers,
                    timeout=8.0
                )
                if r.status_code == 200:
                    return [{'title': x.get('title', 'Exa Source'), 'body': x.get('text', x.get('highlights', [''])[0]), 'href': x.get('url', '#')} for x in r.json().get('results', [])]
        except Exception as e:
            print(f"Exa Async Fail: {e}")
        return []

    async def _search_serper_async(self, query: str, max_results: int) -> list:
        try:
            headers = {"X-API-KEY": self.serper_key, "Content-Type": "application/json"}
            async with httpx.AsyncClient() as client:
                r = await client.post(
                    "https://google.serper.dev/search",
                    json={"q": query, "num": max_results},
                    headers=headers,
                    timeout=8.0
                )
                if r.status_code == 200:
                    return [{'title': x.get('title', 'Serper Source'), 'body': x.get('snippet', ''), 'href': x.get('link', '#')} for x in r.json().get('organic', [])]
        except Exception as e:
            print(f"Serper Async Fail: {e}")
        return []

    async def _search_brave_async(self, query: str, max_results: int) -> list:
        try:
            headers = {"Accept": "application/json", "X-Subscription-Token": self.brave_key}
            async with httpx.AsyncClient() as client:
                r = await client.get(
                    f"https://api.search.brave.com/res/v1/web/search?q={urllib.parse.quote(query)}&count={max_results}",
                    headers=headers,
                    timeout=8.0
                )
                if r.status_code == 200:
                    return [{'title': x.get('title', 'Brave Source'), 'body': x.get('description', ''), 'href': x.get('url', '#')} for x in r.json().get('web', {}).get('results', [])]
        except Exception as e:
            print(f"Brave Async Fail: {e}")
        return []

    async def _search_ddg_async(self, query: str, max_results: int) -> list:
        # Since duckduckgo_search library performs network calls inside context managers, 
        # we can offload it safely to a worker thread using asyncio.to_thread to prevent blocking the event loop.
        try:
            return await asyncio.to_thread(self._search_ddg_sync, query, max_results)
        except Exception as e:
            print(f"DDG Async Offload Fail: {e}")
        return []

    async def _search_ddg_html_async(self, query: str, max_results: int) -> list:
        try:
            return await asyncio.to_thread(self._search_ddg_html_sync, query, max_results)
        except Exception as e:
            print(f"DDG HTML Async Offload Fail: {e}")
        return []

    async def _search_google_scrape_async(self, query: str, max_results: int) -> list:
        try:
            return await asyncio.to_thread(self._search_google_scrape_sync, query, max_results)
        except Exception as e:
            print(f"Google Scrape Async Offload Fail: {e}")
        return []

    async def _search_serpapi_async(self, query: str, max_results: int) -> list:
        try:
            async with httpx.AsyncClient() as client:
                r = await client.get(
                    "https://serpapi.com/search.json",
                    params={"q": query, "api_key": self.serpapi_key, "num": max_results},
                    timeout=8.0
                )
                if r.status_code == 200:
                    results = []
                    for x in r.json().get('organic_results', [])[:max_results]:
                        results.append({
                            'title': x.get('title', 'SerpAPI Source'),
                            'body': x.get('snippet', ''),
                            'href': x.get('link', '#')
                        })
                    return results
        except Exception as e:
            print(f"SerpAPI Async Fail: {e}")
        return []

    async def _search_firecrawl_async(self, query: str, max_results: int) -> list:
        try:
            headers = {
                "Authorization": f"Bearer {self.firecrawl_key}",
                "Content-Type": "application/json"
            }
            async with httpx.AsyncClient() as client:
                r = await client.post(
                    "https://api.firecrawl.dev/v0/search",
                    json={"query": query, "pageOptions": {"onlyMainContent": true}},
                    headers=headers,
                    timeout=12.0
                )
                if r.status_code == 200:
                    results = []
                    for x in r.json().get('data', [])[:max_results]:
                        results.append({
                            'title': x.get('metadata', {}).get('title', 'Firecrawl Source'),
                            'body': x.get('content', x.get('markdown', '')),
                            'href': x.get('metadata', {}).get('sourceURL', '#')
                        })
                    return results
        except Exception as e:
            print(f"Firecrawl Async Fail: {e}")
        return []

    def _get_active_searxng_instances(self) -> list:
        """Fetch working public SearXNG instances from searx.space dynamically."""
        fallback_instances = [
            "https://priv.au",
            "https://searx.dresden.network",
            "https://paulgo.io",
            "https://search.mdosch.de",
            "https://searx.tsmdt.de",
            "https://sx.catgirl.cloud",
            "https://grep.vim.wtf",
            "https://searx.tiekoetter.com",
            "https://search.url4irl.com",
            "https://www.gruble.de"
        ]
        try:
            print("NEURAL RESEARCH [SEARXNG]: Fetching live instances from searx.space...")
            r = httpx.get("https://searx.space/data/instances.json", timeout=6.0)
            if r.status_code == 200:
                data = r.json()
                instances_dict = data.get("instances", {})
                candidates = []
                for url, info in instances_dict.items():
                    clean_url = url.rstrip('/')
                    http_info = info.get("http", {})
                    if http_info.get("status_code") == 200 and info.get("network_type") == "normal":
                        rt = info.get("timing", {}).get("initial", {}).get("all", {}).get("value", 999.0)
                        uptime = info.get("uptime", {}).get("uptimeDay", 0.0)
                        candidates.append({
                            "url": clean_url,
                            "rt": rt,
                            "uptime": uptime
                        })
                candidates.sort(key=lambda x: (x['rt'], -x['uptime']))
                active_urls = [c['url'] for c in candidates if c['rt'] < 2.0]
                if active_urls:
                    print(f"NEURAL RESEARCH [SEARXNG]: Found {len(active_urls)} active live instances.")
                    combined = list(dict.fromkeys(active_urls + fallback_instances))
                    return combined
        except Exception as e:
            print(f"NEURAL RESEARCH [SEARXNG]: Dynamic instances fetch failed: {e}")
        
        return fallback_instances

    def _search_searxng_sync(self, query: str, max_results: int) -> list:
        """Search via public SearXNG instances synchronously."""
        instances = self._get_active_searxng_instances()
        for base_url in instances[:6]:
            try:
                print(f"NEURAL RESEARCH [SEARXNG-SYNC]: Trying {base_url}...")
                r = httpx.get(
                    f"{base_url}/search",
                    params={"q": query, "format": "json", "categories": "general", "language": "en"},
                    headers={"User-Agent": random.choice(self.user_agents)},
                    timeout=5.0,
                    follow_redirects=True
                )
                if r.status_code == 200:
                    data = r.json()
                    results = []
                    for x in data.get('results', [])[:max_results]:
                        results.append({
                            'title': x.get('title', 'SearXNG Source'),
                            'body': x.get('content', ''),
                            'href': x.get('url', '#')
                        })
                    if results:
                        print(f"SEARXNG-SYNC Success from {base_url}: {len(results)} results")
                        return results
            except Exception as e:
                print(f"SearXNG Sync Fail ({base_url}): {e}")
                continue
        return []

    async def _search_searxng_async(self, query: str, max_results: int) -> list:
        """Search via public SearXNG instances asynchronously by offloading to a worker thread."""
        try:
            return await asyncio.to_thread(self._search_searxng_sync, query, max_results)
        except Exception as e:
            print(f"SearXNG Async Offload Fail: {e}")
        return []

    def _search_aol_sync(self, query: str, max_results: int) -> list:
        """Search via AOL (Yahoo backend) synchronously. Highly resilient in cloud environments."""
        try:
            print(f"NEURAL RESEARCH [AOL-SYNC]: Searching for '{query}'...")
            url = "https://search.aol.com/aol/search"
            headers = {
                "User-Agent": random.choice(self.user_agents),
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.5"
            }
            r = httpx.get(
                url,
                params={"q": query},
                headers=headers,
                timeout=8.0,
                follow_redirects=True
            )
            if r.status_code == 200:
                soup = BeautifulSoup(r.text, 'html.parser')
                results = []
                items = soup.find_all('li')
                for item in items:
                    h3 = item.find('h3', class_='title')
                    if h3:
                        a = h3.find('a')
                        if a:
                            title = a.text.strip()
                            href = a.get('href', '')
                            
                            # Decode AOL redirection click link if needed
                            match = re.search(r'/RU=(.*?)/RK=', href)
                            if match:
                                href = urllib.parse.unquote(match.group(1))
                                
                            # Filter out links to AOL/Yahoo internal searches
                            if "search.aol.com" in href or "search.yahoo.com" in href:
                                continue
                            
                            desc_div = item.find('div', class_='compText') or item.find('span', class_='compText')
                            if not desc_div:
                                desc_div = item.find('p')
                                
                            body = desc_div.text.strip() if desc_div else ""
                            results.append({
                                'title': title,
                                'body': body,
                                'href': href
                            })
                            if len(results) >= max_results:
                                break
                print(f"AOL-SYNC Success: Found {len(results)} results")
                return results
        except Exception as e:
            print(f"AOL Sync Fail: {e}")
        return []

    async def _search_aol_async(self, query: str, max_results: int) -> list:
        """Search via AOL asynchronously by offloading to a worker thread."""
        try:
            return await asyncio.to_thread(self._search_aol_sync, query, max_results)
        except Exception as e:
            print(f"AOL Async Offload Fail: {e}")
        return []

    def _clean_html(self, html_content: str) -> str:
        """Removes script, style, navigation, and other non-content tags from HTML."""
        try:
            soup = BeautifulSoup(html_content, 'html.parser')
            for element in soup(["script", "style", "iframe", "noscript", "header", "footer", "nav"]):
                element.decompose()
            text = soup.get_text(separator=' ')
            lines = (line.strip() for line in text.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            clean_text = '\n'.join(chunk for chunk in chunks if chunk)
            return clean_text
        except Exception:
            return ""

    async def _scrape_page_with_splash(self, url: str) -> str:
        """Scrapes the full rendered HTML of a web page using a Splash server (BSD 3-Clause),
        with an automated direct HTTP client fallback if Splash is offline."""
        splash_enabled = os.getenv("SPLASH_ENABLED", "true").lower() == "true"
        splash_url = os.getenv("SPLASH_URL", "http://localhost:8050/render.html")
        
        # 1. Try Splash Scraper first
        if splash_enabled:
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.get(
                        splash_url,
                        params={"url": url, "timeout": 12, "wait": 1.0},
                        timeout=15.0
                    )
                    if response.status_code == 200:
                        clean_content = self._clean_html(response.text)
                        if clean_content and len(clean_content.strip()) > 100:
                            return clean_content
            except Exception as e:
                print(f"[Splash Scrape Fail] Error crawling {url} via Splash: {e}. Trying direct HTTP fallback...")

        # 2. Direct HTTP Fallback Scraper (non-JS render)
        try:
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.5"
            }
            async with httpx.AsyncClient(follow_redirects=True) as client:
                response = await client.get(url, headers=headers, timeout=10.0)
                if response.status_code == 200:
                    clean_content = self._clean_html(response.text)
                    if clean_content and len(clean_content.strip()) > 100:
                        return clean_content
        except Exception as direct_err:
            print(f"[Direct Scrape Fail] Error crawling {url} directly: {direct_err}")
            
        return ""

