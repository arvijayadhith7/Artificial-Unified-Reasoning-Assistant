from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models.chat import Conversation, Message, Attachment

router = APIRouter(prefix="/api/history", tags=["history"])

@router.get("/conversations")
def get_recent_conversations(db: Session = Depends(get_db), limit: int = 20):
    """Fetch the most recent conversations, ordered by updated_at."""
    conversations = db.query(Conversation)\
        .order_by(Conversation.updated_at.desc())\
        .limit(limit).all()
    return conversations

@router.get("/conversations/{conversation_id}")
def get_conversation_details(conversation_id: str, db: Session = Depends(get_db)):
    """Fetch a specific conversation along with all its messages and attachments."""
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    # SQLAlchemy will lazy-load the messages relationship (or we could eager load)
    return {
        "id": conversation.id,
        "title": conversation.title,
        "category": conversation.category,
        "is_pinned": conversation.is_pinned,
        "created_at": conversation.created_at,
        "updated_at": conversation.updated_at,
        "messages": [
            {
                "id": msg.id,
                "role": msg.role,
                "content": msg.content,
                "created_at": msg.created_at,
                "attachments": [
                    {
                        "id": att.id,
                        "file_name": att.file_name,
                        "file_type": att.file_type
                    } for att in msg.attachments
                ]
            } for msg in conversation.messages
        ]
    }

@router.delete("/conversations/{conversation_id}")
def delete_conversation(conversation_id: str, db: Session = Depends(get_db)):
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    db.delete(conversation)
    db.commit()
    return {"status": "deleted"}

@router.patch("/conversations/{conversation_id}")
def update_conversation(conversation_id: str, update_data: dict, db: Session = Depends(get_db)):
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    
    if "title" in update_data:
        conversation.title = update_data["title"]
    if "is_pinned" in update_data:
        conversation.is_pinned = update_data["is_pinned"]
    if "category" in update_data:
        conversation.category = update_data["category"]
        
    db.commit()
    return {"status": "updated"}
