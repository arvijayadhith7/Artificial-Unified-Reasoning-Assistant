from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime, timezone
from .base import Base

class User(Base):
    __tablename__ = "aura_users"
    id = Column(Integer, primary_key=True, index=True)
    google_id = Column(String, unique=True, index=True, nullable=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, nullable=True)
    password_hash = Column(String, nullable=True)
    profile_image = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_login = Column(DateTime, default=lambda: datetime.now(timezone.utc))
