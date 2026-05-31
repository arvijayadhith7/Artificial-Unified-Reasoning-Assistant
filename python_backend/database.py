import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Load env before importing models
load_dotenv()

from models.base import Base
# Import all models here so metadata is aware of them
from models.chat import Conversation, Message, Attachment
from models.user import User

# Use DATABASE_URL from .env, fallback to SQLite for local dev if missing
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./aura_database.db")
DATABASE_URL = DATABASE_URL.strip('"').strip("'")

# OVERRIDE: If the hosting environment (like Hugging Face Spaces) is injecting the dummy URL, replace it
if "db.mfmxknljzzpddwclqxlx.supabase.co" in DATABASE_URL:
    DATABASE_URL = "postgresql://postgres.mfmxknljzzpddwclqxlx:Aura_llm_india@aws-1-ap-northeast-1.pooler.supabase.com:6543/postgres"

# If using PostgreSQL, we might need different connect_args than SQLite
connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False

# Supabase fix: sometimes requires sslmode=require but Supabase connection strings usually have it.
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(
    DATABASE_URL, connect_args=connect_args
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def init_db():
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
