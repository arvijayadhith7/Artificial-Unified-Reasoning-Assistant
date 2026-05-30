import sqlite3
import json
import os

# Database and dataset paths
DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../memory/vector_db/ai_knowledge.db'))
DATASET_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../memory/datasets/ai_tools_dataset.json'))

def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Create the main tools table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS ai_tools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_name TEXT UNIQUE,
        category TEXT,
        description TEXT,
        pricing_model TEXT,
        official_website TEXT,
        raw_json TEXT
    )
    ''')
    
    # Create an FTS5 virtual table for fast full-text semantic-style search
    cursor.execute('''
    CREATE VIRTUAL TABLE IF NOT EXISTS ai_tools_fts USING fts5(
        tool_name,
        category,
        description,
        use_cases,
        strengths,
        recommended_for,
        workflow_tags,
        content=ai_tools,
        content_rowid=id
    )
    ''')
    
    # Create triggers to keep FTS table in sync with the main table
    cursor.execute('''
    CREATE TRIGGER IF NOT EXISTS tools_ai_insert AFTER INSERT ON ai_tools BEGIN
        INSERT INTO ai_tools_fts(rowid, tool_name, category, description, use_cases, strengths, recommended_for, workflow_tags)
        VALUES (
            new.id, 
            new.tool_name, 
            new.category, 
            new.description, 
            json_extract(new.raw_json, '$.use_cases'),
            json_extract(new.raw_json, '$.strengths'),
            json_extract(new.raw_json, '$.recommended_for'),
            json_extract(new.raw_json, '$.workflow_tags')
        );
    END;
    ''')
    
    conn.commit()
    return conn

def ingest_data(conn):
    if not os.path.exists(DATASET_PATH):
        print(f"Error: Dataset not found at {DATASET_PATH}")
        return
        
    with open(DATASET_PATH, 'r', encoding='utf-8') as f:
        tools = json.load(f)
        
    cursor = conn.cursor()
    inserted_count = 0
    
    for tool in tools:
        try:
            cursor.execute('''
            INSERT INTO ai_tools (tool_name, category, description, pricing_model, official_website, raw_json)
            VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                tool.get('tool_name'),
                tool.get('category'),
                tool.get('description'),
                tool.get('pricing_model'),
                tool.get('official_website'),
                json.dumps(tool)
            ))
            inserted_count += 1
        except sqlite3.IntegrityError:
            # Tool already exists
            pass
            
    conn.commit()
    print(f"Ingested {inserted_count} new AI tools into the cognitive database.")

def search_tools(conn, query, limit=5):
    """
    Retrieval-Augmented Generation (RAG) backend utility function.
    Performs FTS match across all fields to retrieve the most relevant tools.
    """
    cursor = conn.cursor()
    
    # Format query for FTS5 (basic word match)
    # E.g. "instagram marketing" -> '"instagram" OR "marketing"'
    words = query.split()
    fts_query = " OR ".join([f'"{word}"' for word in words])
    
    print(f"\n--- AURA Search Results for: '{query}' ---")
    
    cursor.execute('''
    SELECT ai_tools.tool_name, ai_tools.category, ai_tools.description, ai_tools.raw_json 
    FROM ai_tools_fts 
    JOIN ai_tools ON ai_tools.id = ai_tools_fts.rowid
    WHERE ai_tools_fts MATCH ?
    ORDER BY rank
    LIMIT ?
    ''', (fts_query, limit))
    
    results = cursor.fetchall()
    
    if not results:
        print("No matching tools found.")
        return
        
    for idx, row in enumerate(results, 1):
        name, category, desc, raw = row
        tool_data = json.loads(raw)
        
        print(f"\n{idx}. {name} [{category}]")
        print(f"   Desc: {desc}")
        print(f"   Best for: {', '.join(tool_data.get('use_cases', []))}")
        print(f"   Pricing: {tool_data.get('pricing_model')}")

if __name__ == "__main__":
    print("Initializing AURA Vector Memory (SQLite FTS)...")
    db_conn = init_db()
    
    ingest_data(db_conn)
    
    # Test the ingestion with a couple of workflow queries
    search_tools(db_conn, "instagram marketing social media")
    search_tools(db_conn, "video editing avatars")
    
    db_conn.close()
