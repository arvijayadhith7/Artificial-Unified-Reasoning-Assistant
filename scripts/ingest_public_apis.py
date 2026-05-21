import os
import re
import sys
import chromadb
from tqdm import tqdm

# Add backend directory to sys path so we can import RAG
sys.path.append(os.path.join(os.path.dirname(__file__), '../python_backend'))
from agent_plugins.rag_advanced import AdvancedRAG

def parse_readme(file_path):
    apis = []
    current_category = "General"
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    for line in lines:
        line = line.strip()
        
        # Check for category header
        if line.startswith("### "):
            current_category = line.replace("### ", "").strip()
            continue
            
        # Check for table row
        if line.startswith("|") and not line.startswith("|:") and not line.startswith("| API |") and not line.startswith("|---|"):
            parts = [p.strip() for p in line.split('|')[1:-1]]
            if len(parts) >= 5:
                # Parse markdown link [Name](URL)
                name_col = parts[0]
                match = re.search(r'\[(.*?)\]\((.*?)\)', name_col)
                if match:
                    name = match.group(1)
                    url = match.group(2)
                else:
                    name = name_col
                    url = "Unknown"
                
                desc = parts[1]
                auth = parts[2].replace("`", "")
                https = parts[3]
                cors = parts[4]
                
                if auth.lower() == "no":
                    auth = "No Auth"
                
                apis.append({
                    "name": name,
                    "url": url,
                    "description": desc,
                    "auth": auth,
                    "https": https,
                    "cors": cors,
                    "category": current_category
                })
    return apis

def ingest_to_chroma():
    readme_path = os.path.join(os.path.dirname(__file__), '../public_apis_readme.md')
    print("Parsing README...")
    apis = parse_readme(readme_path)
    print(f"Found {len(apis)} APIs.")
    
    db_path = os.path.join(os.path.dirname(__file__), '../memory/vector_db')
    os.makedirs(db_path, exist_ok=True)
    
    print("Initializing ChromaDB...")
    client = chromadb.PersistentClient(path=db_path)
    collection = client.get_or_create_collection(name="aura_memory_vault")
    
    # We use AdvancedRAG to handle embeddings easily
    rag = AdvancedRAG(collection)
    
    print("Ingesting APIs into Neural Memory...")
    # Add in batches to avoid overwhelming
    for api in tqdm(apis):
        text_fragment = (
            f"PUBLIC API ENTRY:\n"
            f"Name: {api['name']}\n"
            f"Category: {api['category']}\n"
            f"Description: {api['description']}\n"
            f"Auth Required: {api['auth']}\n"
            f"HTTPS: {api['https']}\n"
            f"CORS: {api['cors']}\n"
            f"URL: {api['url']}"
        )
        try:
            rag.add_intelligence(text_fragment)
        except Exception as e:
            print(f"Failed to ingest {api['name']}: {e}")
            
    print("Ingestion Complete. AURA now has knowledge of all public APIs.")

if __name__ == "__main__":
    ingest_to_chroma()
