import sqlite3
import json
import os

DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), 'memory/vector_db/ai_knowledge.db'))

cli_anything_data = {
    "tool_name": "CLI-Anything",
    "category": "AI Automation",
    "description": "Desktop software automation framework and GUI-to-CLI conversion engine that enables AI agents to control software with no API by scanning source code and auto-generating structured CLIs.",
    "use_cases": [
        "automated Blender rendering",
        "GIMP batch exports",
        "LibreOffice report generation",
        "OBS recording automation",
        "Audacity cleanup pipelines",
        "desktop workflow orchestration",
        "AI-assisted software control"
    ],
    "pricing_model": "open-source",
    "strengths": [
        "automatic CLI generation",
        "self-documenting commands",
        "--help discovery system",
        "--json structured outputs for AI",
        "REPL mode",
        "end-to-end testing",
        "unit testing",
        "command discovery for AI agents"
    ],
    "platforms_supported": ["windows", "mac", "linux"],
    "official_website": "https://github.com/HKUDS/CLI-Anything",
    "recommended_for": [
        "AI agents",
        "workflow orchestrators",
        "automation engineers",
        "n8n workflows",
        "custom Python agents",
        "Claude Code users"
    ],
    "marketing_use_cases": ["automated creative workflows", "batch media generation"],
    "workflow_tags": [
        "Desktop AI Control",
        "Software Automation",
        "AI Workflow Infrastructure",
        "CLI Toolchains",
        "Agent Runtime Systems",
        "AI Operating Layer"
    ]
}

def ingest_cli_anything():
    if not os.path.exists(DB_PATH):
        print(f"Error: Database not found at {DB_PATH}")
        return
        
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        cursor.execute('''
        INSERT INTO ai_tools (tool_name, category, description, pricing_model, official_website, raw_json)
        VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            cli_anything_data['tool_name'],
            cli_anything_data['category'],
            cli_anything_data['description'],
            cli_anything_data['pricing_model'],
            cli_anything_data['official_website'],
            json.dumps(cli_anything_data)
        ))
        conn.commit()
        print(f"Successfully ingested {cli_anything_data['tool_name']} into AURA's cognitive memory.")
    except sqlite3.IntegrityError:
        print(f"Tool {cli_anything_data['tool_name']} already exists in memory.")
    except Exception as e:
        print(f"Error ingesting data: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    print("Ingesting CLI-Anything Knowledge...")
    ingest_cli_anything()
