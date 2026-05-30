import os
import sys

# Add backend directory to sys path so we can import ApiAgent
sys.path.append(os.path.join(os.path.dirname(__file__), '../python_backend'))
from agent_plugins.api_agent import ApiAgent

def test_search():
    agent = ApiAgent()
    
    # Test queries targeting real-time datasets
    queries = [
        "coinbase market data",
        "real-time flight data",
        "transportation",
        "seismic portal weather"
    ]
    
    for q in queries:
        print(f"\n=== Query: '{q}' ===")
        res = agent.search_apis(q, top_k=3)
        # print safely to console to avoid Windows cp1252 character map issues
        print(res.encode('ascii', errors='ignore').decode('ascii'))

if __name__ == "__main__":
    test_search()
