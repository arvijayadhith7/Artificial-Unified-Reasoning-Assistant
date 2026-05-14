import os
import psycopg2
import pandas as pd
from sqlalchemy import create_engine, inspect

class SQLAgent:
    """Agent plugin for Natural Language to Postgres (Supabase) query execution."""
    
    def __init__(self, connection_url=None):
        # Fallback to local if no URL provided, but prioritize Supabase
        self.url = connection_url or os.environ.get('SUPABASE_DB_URL')
        if self.url:
            self.engine = create_engine(self.url)
        else:
            self.engine = create_engine("sqlite:///./memory/aura_system.db")

    def get_schema(self):
        """Explore the database schema to provide context to the LLM."""
        try:
            inspector = inspect(self.engine)
            schema_info = {}
            # Focus on public schema for Supabase
            for table_name in inspector.get_table_names(schema='public'):
                columns = inspector.get_columns(table_name, schema='public')
                schema_info[table_name] = [c['name'] for c in columns]
            return schema_info
        except Exception as e:
            return f"Schema Error: {str(e)}"

    def execute_query(self, sql_query):
        """Execute a raw SQL query on Supabase and return results in Markdown."""
        try:
            # Using pandas for clean markdown output
            df = pd.read_sql_query(sql_query, self.engine)
            if df.empty:
                return "Query successful, but no matching records found."
            return df.to_markdown(index=False)
        except Exception as e:
            return f"❌ Postgres Error: {str(e)}"

    def generate_sql_prompt(self, natural_query):
        """Guides AURA on how to write valid Postgres SQL for the current schema."""
        schema = self.get_schema()
        if isinstance(schema, str): return schema # Return error if schema fetch failed
        
        schema_str = "\n".join([f"Table {t}: {', '.join(cols)}" for t, cols in schema.items()])
        
        return f"""
Given the following Postgres (Supabase) schema:
{schema_str}

Convert the request into a valid, optimized PostgreSQL query.
User Request: {natural_query}

Rules:
- Use double quotes for table/column names if they are reserved keywords.
- Return ONLY the SQL code inside ```sql blocks.
"""
