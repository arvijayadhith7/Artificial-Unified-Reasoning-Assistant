import os
import requests

def ingest_directory(directory_path, api_url):
    print(f"Starting ingestion from: {directory_path}")
    for root, dirs, files in os.walk(directory_path):
        for file in files:
            if file.endswith('.md') or file.endswith('.txt'):
                file_path = os.path.join(root, file)
                print(f"Processing: {file_path}")
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                # Split large files into chunks for better retrieval
                chunks = [content[i:i+2000] for i in range(0, len(content), 2000)]
                
                for i, chunk in enumerate(chunks):
                    payload = {
                        "text": chunk,
                        "metadata": {"source": file, "chunk": i, "path": file_path}
                    }
                    try:
                        response = requests.post(api_url, json=payload)
                        if response.status_code == 200:
                            print(f"  Successfully ingested chunk {i} of {file}")
                        else:
                            print(f"  Failed to ingest chunk {i}: {response.text}")
                    except Exception as e:
                        print(f"  Connection error: {e}")

if __name__ == "__main__":
    DATASET_DIR = r'D:\ANTIGRAVITY\llm APP\llm-datasets-main'
    API_URL = "http://localhost:8000/add_document"
    
    ingest_directory(DATASET_DIR, API_URL)
    print("Ingestion complete!")
