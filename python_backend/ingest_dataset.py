import os
import argparse
from langchain_community.document_loaders import DirectoryLoader, TextLoader
from services.rag_pipeline import ingest_documents_to_pack

def ingest_directory(directory_path, pack_name):
    print(f"Starting ingestion from: {directory_path} into pack: {pack_name}")
    
    # Load all markdown and text files
    print("Loading documents...")
    loader = DirectoryLoader(directory_path, glob="**/*.md", loader_cls=TextLoader, loader_kwargs={'autodetect_encoding': True})
    documents = loader.load()
    
    txt_loader = DirectoryLoader(directory_path, glob="**/*.txt", loader_cls=TextLoader, loader_kwargs={'autodetect_encoding': True})
    txt_documents = txt_loader.load()
    
    all_documents = documents + txt_documents
    
    if not all_documents:
        print("No documents found in the specified directory.")
        return
        
    print(f"Loaded {len(all_documents)} documents. Starting chunking and embedding...")
    
    # Process and ingest
    chunks_processed = ingest_documents_to_pack(all_documents, pack_name)
    
    print(f"Ingestion complete! Successfully added {chunks_processed} chunks to '{pack_name}'.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest documentation into AURA Knowledge Packs")
    parser.add_argument("--dir", type=str, required=True, help="Directory containing .md or .txt files")
    parser.add_argument("--pack-name", type=str, required=True, help="Name of the ChromaDB collection (e.g. photoshop_pack)")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.dir):
        print(f"Error: Directory '{args.dir}' does not exist.")
        exit(1)
        
    ingest_directory(args.dir, args.pack_name)
