import os
from langchain_community.embeddings import HuggingFaceEmbeddings
try:
    from langchain_text_splitters import RecursiveCharacterTextSplitter
except ImportError:
    from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from .vector_store import get_or_create_collection

# Define the embedding model
EMBEDDING_MODEL_NAME = "all-MiniLM-L6-v2"
embeddings = HuggingFaceEmbeddings(model_name=EMBEDDING_MODEL_NAME)

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    length_function=len,
    is_separator_regex=False,
)

def ingest_documents_to_pack(documents: list[Document], pack_name: str):
    """
    Chunks documents and inserts them into the specific ChromaDB pack.
    """
    collection = get_or_create_collection(pack_name)
    
    # Split documents into chunks
    chunks = text_splitter.split_documents(documents)
    
    if not chunks:
        return 0
        
    # Extract text and metadata for ChromaDB
    texts = [chunk.page_content for chunk in chunks]
    metadatas = [chunk.metadata for chunk in chunks]
    ids = [f"{pack_name}_{i}_{os.urandom(4).hex()}" for i in range(len(chunks))]
    
    # Generate embeddings
    embedded_docs = embeddings.embed_documents(texts)
    
    collection.add(
        ids=ids,
        embeddings=embedded_docs,
        documents=texts,
        metadatas=metadatas
    )
    
    return len(chunks)

def query_knowledge_pack(query: str, pack_name: str, top_k: int = 5):
    """
    Queries a specific knowledge pack.
    """
    collection = get_or_create_collection(pack_name)
    
    # Embed the query
    query_embedding = embeddings.embed_query(query)
    
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=top_k
    )
    
    # Format results
    retrieved_docs = []
    if results and 'documents' in results and len(results['documents']) > 0:
        for i in range(len(results['documents'][0])):
            retrieved_docs.append({
                "content": results['documents'][0][i],
                "metadata": results['metadatas'][0][i] if 'metadatas' in results else {}
            })
            
    return retrieved_docs
