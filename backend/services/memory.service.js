const { createClient } = require('@supabase/supabase-js');
const config = require('../config/config');

class MemoryService {
  constructor() {
    this.supabase = createClient(config.supabaseUrl, config.supabaseKey);
    console.log('✅ Supabase Cloud Memory connected');
  }

  async getHistory(sessionId) {
    try {
      const { data, error } = await this.supabase
        .from('messages')
        .select('role, content')
        .eq('session_id', sessionId)
        .order('timestamp', { ascending: true })
        .limit(20);

      if (error) throw error;

      return data.map(row => ({
        role: row.role,
        parts: [{ text: row.content }]
      }));
    } catch (err) {
      console.error('❌ Supabase History Error:', err.message);
      if (err.message.includes('column') && err.message.includes('does not exist')) {
        console.warn('💡 SCHEMA TIP: Ensure your Supabase "messages" table has a "session_id" column (snake_case).');
      }
      return [];
    }
  }

  async addMessage(sessionId, role, content) {
    try {
      const { error } = await this.supabase
        .from('messages')
        .insert([{ session_id: sessionId, role, content }]);

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
        .eq('session_id', sessionId);

      if (error) throw error;
    } catch (err) {
      console.error('❌ Supabase Clear Error:', err.message);
    }
  }
}

module.exports = new MemoryService();
