import asyncio
import time
import json
import logging
from typing import List, Dict, Any
from agent_plugins.search_agent import ResearchAgent

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("IngestionCluster")

class RealtimeIngestionCluster:
    def __init__(self):
        self.search_agent = ResearchAgent()
        self.intelligence_cache: Dict[str, Any] = {}
        self.is_running = False
        self.topics = ["AI Technology News", "Global Market Trends"]
        
    async def start(self):
        """Starts the realtime ingestion loop."""
        if self.is_running:
            return
        self.is_running = True
        logger.info("Neural Ingestion Cluster Activated.")
        asyncio.create_task(self._ingestion_loop())

    async def _ingestion_loop(self):
        while self.is_running:
            try:
                for topic in self.topics:
                    logger.info(f"Ingesting live intelligence for: {topic}")
                    results = self.search_agent.search_live(topic)
                    self.intelligence_cache[topic] = {
                        "data": results,
                        "timestamp": time.time(),
                        "summary": self._generate_quick_summary(results)
                    }
                    # Small delay between topics to avoid rate limits
                    await asyncio.sleep(2)
                
                # Global sleep before next full sync (e.g., every 5 minutes)
                await asyncio.sleep(300)
            except Exception as e:
                logger.error(f"Ingestion Error: {e}")
                await asyncio.sleep(60)

    def _generate_quick_summary(self, results: str) -> str:
        # In a real scenario, we could use an LLM here to summarize.
        # For now, we'll just take the first 500 chars as a "neural preview".
        return results[:500] + "..." if len(results) > 500 else results

    def query(self, query: str) -> List[Dict[str, Any]]:
        """Returns relevant intelligence from the cluster."""
        relevant_data = []
        query_lower = query.lower()
        
        for topic, info in self.intelligence_cache.items():
            if any(word in topic.lower() for word in query_lower.split()):
                relevant_data.append({
                    "topic": topic,
                    "intelligence": info["data"],
                    "freshness": f"{int(time.time() - info['timestamp'])}s ago"
                })
        
        return relevant_data

# Singleton instance
ingestion_cluster = RealtimeIngestionCluster()
