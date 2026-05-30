import os
import chromadb
from chromadb.config import Settings

# Persistent local ChromaDB setup
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHROMA_DB_PATH = os.path.join(BASE_DIR, "memory", "chroma_db")

def get_chroma_client():
    """Returns a persistent ChromaDB client."""
    # Ensure directory exists
    os.makedirs(CHROMA_DB_PATH, exist_ok=True)
    
    client = chromadb.PersistentClient(
        path=CHROMA_DB_PATH,
        settings=Settings(anonymized_telemetry=False)
    )
    return client

def get_or_create_collection(pack_name: str):
    """
    Returns a specific ChromaDB collection for a knowledge pack.
    E.g., pack_name='photoshop_pack'
    """
    client = get_chroma_client()
    collection = client.get_or_create_collection(
        name=pack_name,
        metadata={"hnsw:space": "cosine"} # Use cosine similarity
    )
    return collection

def list_knowledge_packs():
    """Returns a list of all active knowledge packs (collections)."""
    client = get_chroma_client()
    return [col.name for col in client.list_collections()]
