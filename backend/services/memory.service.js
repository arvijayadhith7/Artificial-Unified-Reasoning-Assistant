const { createClient } = require('@supabase/supabase-js');
const WebSocket = require('ws');
const config = require('../config/config');

class MemoryService {
  constructor() {
    // Exposed as public so external routes can query Supabase directly
    this.supabase = createClient(config.supabaseUrl, config.supabaseKey, {
      auth: { persistSession: false },
      realtime: { transport: WebSocket }
    });
    console.log('✅ Supabase Cloud Memory connected');
  }

  async getHistory(sessionId) {
    try {
      const { data, error } = await this.supabase
        .from('messages')
        .select('role, content')
        .eq('sessionid', sessionId)          // Supabase column: sessionid (no underscore)
        .order('timestamp', { ascending: true })
        .limit(20);

      if (error) throw error;

      return (data || []).map(row => ({
        role: row.role,
        parts: [{ text: row.content }]
      }));
    } catch (err) {
      console.error('❌ Supabase History Error:', err.message);
      return [];
    }
  }

  async addMessage(sessionId, role, content) {
    try {
      const { error } = await this.supabase
        .from('messages')
        .insert([{ sessionid: sessionId, role, content }]); // Supabase column: sessionid

      if (error) throw error;
    } catch (err) {
      console.error('❌ Supabase Save Error:', err.message);
    }
  }

  async clearHistory(sessionId) {
    try {
      const { error } = await this.supabase
        .from('messages')
        .delete()
        .eq('sessionid', sessionId); // Supabase column: sessionid

      if (error) throw error;
    } catch (err) {
      console.error('❌ Supabase Clear Error:', err.message);
    }
  }
}

module.exports = new MemoryService();
