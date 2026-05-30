import os
import chromadb
from agent_plugins.rag_advanced import AdvancedRAG

class ApiAgent:
    def __init__(self):
        # Resolve path robustly to support local and cloud/containerized environments
        possible_paths = [
            os.path.join(os.path.dirname(__file__), '../../memory/vector_db'),  # Local layout
            os.path.join(os.path.dirname(__file__), '../memory/vector_db'),     # Deployed layout
            os.path.abspath('memory/vector_db')                                 # Cwd layout
        ]
        db_path = possible_paths[0]
        for p in possible_paths:
            if os.path.exists(p):
                db_path = p
                break
                
        print(f"ApiAgent: Initializing ChromaDB at: {db_path}")
        self.client = chromadb.PersistentClient(path=db_path)
        self.collection = self.client.get_or_create_collection(name="aura_memory_vault")
        self.rag = AdvancedRAG(self.collection)

    def search_apis(self, query: str, top_k: int = 5) -> str:
        """Search the neural memory specifically for Public APIs."""
        # Prepend to guide the vector search towards our API entries
        enhanced_query = f"PUBLIC API ENTRY {query}"
        
        results = self.rag.hybrid_search(enhanced_query, top_k=top_k * 2) # Get more to filter
        
        # Filter for actual API entries
        api_entries = [res for res in results if "PUBLIC API ENTRY:" in res]
        
        if not api_entries:
            return "No matching free APIs found in the neural memory vault."
            
        # Deduplicate and limit
        unique_apis = []
        seen = set()
        for entry in api_entries:
            if entry not in seen:
                seen.add(entry)
                unique_apis.append(entry)
                if len(unique_apis) >= top_k:
                    break
                    
        # Format nicely
        output = "### Recommended Free Public APIs\n\n"
        for entry in unique_apis:
            lines = entry.split('\n')
            name, cat, desc, auth, https, cors, url = "", "", "", "", "", "", ""
            for line in lines:
                if line.startswith("Name: "): name = line.replace("Name: ", "")
                if line.startswith("Category: "): cat = line.replace("Category: ", "")
                if line.startswith("Description: "): desc = line.replace("Description: ", "")
                if line.startswith("Auth Required: "): auth = line.replace("Auth Required: ", "")
                if line.startswith("URL: "): url = line.replace("URL: ", "")
                
            output += f"**[{name}]({url})** ({cat})\n"
            output += f"> {desc}\n"
            output += f"> *Auth:* {auth}\n\n"
            
        return output
