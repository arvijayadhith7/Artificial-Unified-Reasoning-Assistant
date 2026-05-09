# Enterprise AI System Database Schema

## 1. Users Collection
```json
{
  "_id": "ObjectId",
  "name": "String",
  "email": "String (unique)",
  "passwordHash": "String",
  "preferences": {
    "theme": "String (dark/light)",
    "aiPersona": "String",
    "language": "String"
  },
  "usage": {
    "tokensUsed": "Number",
    "plan": "String (free/pro/enterprise)"
  },
  "createdAt": "Date"
}
```

## 2. Conversations Collection
```json
{
  "_id": "ObjectId",
  "userId": "ObjectId",
  "title": "String",
  "summary": "String",
  "lastMessageAt": "Date",
  "tags": ["String"],
  "metadata": {
    "modelUsed": "String",
    "tokenCount": "Number"
  }
}
```

## 3. Messages Collection
```json
{
  "_id": "ObjectId",
  "conversationId": "ObjectId",
  "role": "String (user/model/system)",
  "content": "String",
  "attachments": [
    {
      "type": "String (image/pdf/code)",
      "url": "String",
      "name": "String"
    }
  ],
  "latency": "Number (ms)",
  "timestamp": "Date"
}
```

## 4. Vector Store (Pinecone/ChromaDB Schema)
```json
{
  "id": "String (doc_id)",
  "values": [0.12, 0.45, ...], // Embedding vector
  "metadata": {
    "userId": "String",
    "source": "String (filename)",
    "content": "String (text chunk)",
    "tags": ["knowledge", "personal"]
  }
}
```
