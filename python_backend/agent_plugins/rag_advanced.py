import os
import torch
from sentence_transformers import SentenceTransformer

class AdvancedRAG:
    """Advanced RAG system with Hybrid Search (BM25 + Vector) and Reranking."""
    
    def __init__(self, vector_db_collection, embedder_model='all-MiniLM-L6-v2'):
        self.collection = vector_db_collection
        # Lazy load torch/st only if needed, but keeping here as they are stable
        self.embedder = SentenceTransformer(embedder_model, device='cuda' if torch.cuda.is_available() else 'cpu')
        self.bm25_retriever = None

    def _get_langchain_doc(self):
        try:
            from langchain_core.documents import Document
            return Document
        except:
            class Document: 
                def __init__(self, page_content): self.page_content = page_content
            return Document

    def initialize_bm25(self, texts):
        """Initialize BM25 with a corpus of texts."""
        if not texts: return
        try:
            from langchain_community.retrievers import BM25Retriever
            DocClass = self._get_langchain_doc()
            documents = [DocClass(page_content=t) for t in texts]
            self.bm25_retriever = BM25Retriever.from_documents(documents)
            self.bm25_retriever.k = 5
        except Exception as e:
            print(f"BM25 Initialization Failed (Non-Critical): {e}")

    def hybrid_search(self, query, top_k=5):
        """Perform hybrid search combining vector similarity and keyword matching."""
        # 1. Vector Search
        query_embedding = self.embedder.encode(query).tolist()
        vector_results = self.collection.query(query_embeddings=[query_embedding], n_results=top_k)
        vector_docs = vector_results['documents'][0] if vector_results['documents'] else []
        
        # 2. BM25 Search (if initialized)
        bm25_docs = []
        if self.bm25_retriever:
            try:
                results = self.bm25_retriever.get_relevant_documents(query)
                bm25_docs = [doc.page_content for doc in results]
            except: pass

        # 3. Ensemble (Simple deduplication and ranking)
        combined = list(dict.fromkeys(vector_docs + bm25_docs))
        return combined[:top_k]

    def add_intelligence(self, new_text):
        """Add new information to the brain."""
        embedding = self.embedder.encode(new_text).tolist()
        self.collection.add(
            documents=[new_text],
            embeddings=[embedding],
            ids=[str(hash(new_text))]
        )
