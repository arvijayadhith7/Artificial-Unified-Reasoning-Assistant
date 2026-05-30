import os
import sys
import asyncio

sys.path.append(os.path.join(os.path.dirname(__file__), 'python_backend'))

async def main():
    from agent_plugins.search_agent import ResearchAgent
    agent = ResearchAgent()
    print("Testing dynamic active SearXNG instances retrieval...")
    instances = agent._get_active_searxng_instances()
    print(f"Top 5 retrieved instances: {instances[:5]}")
    
    print("\nTesting synchronous SearXNG search...")
    res_sync = agent._search_searxng_sync("Formula 1 standings", max_results=3)
    print(f"Sync Results Count: {len(res_sync) if res_sync else 0}")
    if res_sync:
        print(f"First result: {res_sync[0]}")
        
    print("\nTesting asynchronous SearXNG search...")
    res_async = await agent._search_searxng_async("FastAPI tutorial", max_results=3)
    print(f"Async Results Count: {len(res_async) if res_async else 0}")
    if res_async:
        print(f"First result: {res_async[0]}")

if __name__ == "__main__":
    asyncio.run(main())
