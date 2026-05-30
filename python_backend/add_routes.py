import os

main_py_path = r"d:\ANTIGRAVITY\llm APP\python_backend\main.py"

routes_code = """
from pydantic import BaseModel
class IngestRequest(BaseModel):
    directory_path: str
    pack_name: str

class QueryRequest(BaseModel):
    query: str
    pack_name: str
    top_k: int = 5

@app.post("/api/rag/ingest")
async def api_rag_ingest(req: IngestRequest):
    try:
        from ingest_dataset import ingest_directory
        ingest_directory(req.directory_path, req.pack_name)
        return {"status": "success", "message": f"Ingestion started/completed for pack {req.pack_name}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/rag/query")
async def api_rag_query(req: QueryRequest):
    try:
        from services.rag_pipeline import query_knowledge_pack
        results = query_knowledge_pack(req.query, req.pack_name, req.top_k)
        return {"status": "success", "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

"""

with open(main_py_path, 'r', encoding='utf-8') as f:
    content = f.read()

# find if __name__ == "__main__":
target = 'if __name__ == "__main__":'
if target in content:
    content = content.replace(target, routes_code + target)
    with open(main_py_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Routes injected successfully.")
else:
    print("Target block not found.")
