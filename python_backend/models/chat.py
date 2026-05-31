from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid
from .base import Base

class Conversation(Base):
    __tablename__ = 'aura_conversations'
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String, default="New Chat")
    category = Column(String, default="General Chat") # Workspace, Research, CRM, Coding, etc.
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    ai_model_used = Column(String, nullable=True)
    is_pinned = Column(Boolean, default=False)
    is_archived = Column(Boolean, default=False)

    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan", order_by="Message.created_at")

class Message(Base):
    __tablename__ = 'aura_messages'
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    conversation_id = Column(String, ForeignKey('aura_conversations.id'), nullable=False)
    role = Column(String, nullable=False) # 'user', 'assistant', 'system'
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    conversation = relationship("Conversation", back_populates="messages")
    attachments = relationship("Attachment", back_populates="message", cascade="all, delete-orphan")

class Attachment(Base):
    __tablename__ = 'aura_attachments'
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    message_id = Column(String, ForeignKey('aura_messages.id'), nullable=False)
    file_name = Column(String, nullable=False)
    file_type = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    extracted_text = Column(Text, nullable=True)
    upload_time = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    message = relationship("Message", back_populates="attachments")
