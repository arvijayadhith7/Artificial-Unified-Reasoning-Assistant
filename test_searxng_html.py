import requests
from bs4 import BeautifulSoup
import re

def test():
    # Let's try to query an instance's HTML search page
    url = "https://priv.au/search"
    params = {"q": "FastAPI", "categories": "general", "language": "en"}
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"}
    
    try:
        print(f"Fetching HTML search from {url}...")
        r = requests.get(url, params=params, headers=headers, timeout=10, allow_redirects=True)
        print(f"Status Code: {r.status_code}")
        print(f"Content-Type: {r.headers.get('Content-Type')}")
        
        soup = BeautifulSoup(r.text, 'html.parser')
        
        # Let's search for result divs/articles
        results = []
        
        # In SearXNG, results typically look like:
        # <article class="result result-default ..."> or <div class="result ...">
        articles = soup.find_all(['article', 'div'], class_=re.compile(r'\bresult\b'))
        print(f"Found {len(articles)} candidate result elements.")
        
        for art in articles[:5]:
            # Print a snippet of the element HTML to inspect
            print(f"--- CANDIDATE ---")
            print(str(art)[:400])
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test()
