const sqlite3 = require('sqlite3');
const { open } = require('sqlite');
const path = require('path');

class MemoryService {
  constructor() {
    this.db = null;
    this.init();
  }

  async init() {
    // Database stored on D: drive for persistence
    const dbPath = 'D:\\ANTIGRAVITY\\llm APP\\memory\\chat_memory.db';
    
    this.db = await open({
      filename: dbPath,
      driver: sqlite3.Database
    });

    await this.db.exec(`
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId TEXT,
        role TEXT,
        content TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('✅ SQLite Memory System initialized on D: drive');
  }

  async getHistory(sessionId) {
    if (!this.db) await this.init();
    
    const rows = await this.db.all(
      'SELECT role, content FROM messages WHERE sessionId = ? ORDER BY timestamp ASC LIMIT 20',
      [sessionId]
    );

    // Transform to Gemini/Transformer-style format
    return rows.map(row => ({
      role: row.role,
      parts: [{ text: row.content }]
    }));
  }

  async addMessage(sessionId, role, content) {
    if (!this.db) await this.init();
    
    await this.db.run(
      'INSERT INTO messages (sessionId, role, content) VALUES (?, ?, ?)',
      [sessionId, role, content]
    );
  }

  async clearHistory(sessionId) {
    if (!this.db) await this.init();
    await this.db.run('DELETE FROM messages WHERE sessionId = ?', [sessionId]);
  }
}

module.exports = new MemoryService();
