import os
import re
import sys
import urllib.request
import hashlib
import chromadb
from tqdm import tqdm

# Add backend directory to sys path so we can import AdvancedRAG
sys.path.append(os.path.join(os.path.dirname(__file__), '../python_backend'))
from agent_plugins.rag_advanced import AdvancedRAG

def fetch_readme(url):
    print(f"Fetching README from: {url}")
    req = urllib.request.Request(
        url, 
        headers={'User-Agent': 'Mozilla/5.0'}
    )
    with urllib.request.urlopen(req) as response:
        return response.read().decode('utf-8')

def parse_readme(content):
    datasets = []
    current_section = "Free"  # Default section
    current_category = "General"
    
    lines = content.splitlines()
    for line in lines:
        line = line.strip()
        
        # Detect sections (e.g., ## Free, ## Paid)
        if line.startswith("## "):
            section_name = line.replace("## ", "").strip()
            if "free" in section_name.lower():
                current_section = "Free"
            elif "paid" in section_name.lower():
                current_section = "Paid"
            continue
            
        # Detect category headers (e.g., ### Finance/Crypto)
        if line.startswith("### "):
            current_category = line.replace("### ", "").strip()
            continue
            
        # Detect list item (e.g., - [Name](URL) - Description)
        if line.startswith("-") or line.startswith("*"):
            match = re.match(r'^[\-\*]\s*\[(.*?)\]\((.*?)\)\s*(?:[\-\:]\s*)?(.*)', line)
            if match:
                name = match.group(1).strip()
                url = match.group(2).strip()
                description = match.group(3).strip()
                
                # Deduce auth requirement
                if current_section == "Free":
                    auth = "No Auth / Free API"
                else:
                    auth = "Paid / Subscription"
                
                # Check for explicit mentions of keys/auth in the description
                desc_lower = description.lower()
                if "api key" in desc_lower or "requires an api key" in desc_lower or "signup required" in desc_lower:
                    auth = "Free / Key Required"
                
                datasets.append({
                    "name": name,
                    "url": url,
                    "description": description,
                    "auth": auth,
                    "https": "Yes" if url.startswith("https") or url.startswith("wss") else "No",
                    "cors": "Unknown",
                    "category": f"Real-Time / {current_category}"
                })
    return datasets

def ingest_datasets():
    readme_url = "https://raw.githubusercontent.com/bytewax/awesome-public-real-time-datasets/main/README.md"
    try:
        content = fetch_readme(readme_url)
    except Exception as e:
        print(f"Error fetching README: {e}")
        return
        
    print("Parsing datasets...")
    datasets = parse_readme(content)
    print(f"Parsed {len(datasets)} real-time datasets.")
    
    db_path = os.path.join(os.path.dirname(__file__), '../memory/vector_db')
    os.makedirs(db_path, exist_ok=True)
    
    print(f"Connecting to ChromaDB at: {db_path}")
    client = chromadb.PersistentClient(path=db_path)
    collection = client.get_or_create_collection(name="aura_memory_vault")
    
    rag = AdvancedRAG(collection)
    
    print("Ingesting datasets into neural memory...")
    success_count = 0
    for ds in tqdm(datasets):
        text_fragment = (
            f"PUBLIC API ENTRY:\n"
            f"Name: {ds['name']}\n"
            f"Category: {ds['category']}\n"
            f"Description: {ds['description']}\n"
            f"Auth Required: {ds['auth']}\n"
            f"HTTPS: {ds['https']}\n"
            f"CORS: {ds['cors']}\n"
            f"URL: {ds['url']}"
        )
        
        # Generate a stable, unique ID based on the URL and Name to avoid duplicates
        id_str = f"realtime_{ds['name']}_{ds['url']}"
        hashed_id = hashlib.sha256(id_str.encode('utf-8')).hexdigest()
        
        try:
            embedding = rag.embedder.encode(text_fragment).tolist()
            collection.upsert(
                documents=[text_fragment],
                embeddings=[embedding],
                ids=[hashed_id]
            )
            success_count += 1
        except Exception as e:
            safe_name = ds['name'].encode('ascii', errors='ignore').decode('ascii')
            print(f"Failed to ingest dataset '{safe_name}': {e}")
            
    print(f"Ingestion complete. Successfully added/updated {success_count}/{len(datasets)} datasets.")

if __name__ == "__main__":
    ingest_datasets()
