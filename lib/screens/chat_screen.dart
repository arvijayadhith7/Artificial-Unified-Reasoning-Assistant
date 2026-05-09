import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../chat_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  String _currentResponse = "";
  String _currentThought = "";
  String _currentTool = "";
  String _selectedModel = 'groq'; // Exclusive Groq Engine

  @override
  void initState() {
    super.initState();
    _chatService.connect();
    _chatService.responseStream.listen((data) {
      final type = data['type'];
      final content = data['content'] as String;

      setState(() {
        if (type == 'chunk') {
          if (_messages.isNotEmpty && !_messages.last.isUser && _currentResponse.isNotEmpty) {
            _currentResponse += content;
            _messages[_messages.length - 1] = ChatMessage(text: _currentResponse, isUser: false);
          } else {
            _currentResponse = content;
            _messages.add(ChatMessage(text: _currentResponse, isUser: false));
          }
          _currentThought = ""; // Clear thought once speech starts
          _currentTool = "";
        } else if (type == 'thought') {
          _currentThought = content;
        } else if (type == 'tool') {
          _currentTool = content;
        } else if (type == 'output') {
          // You could display tool outputs in a special bubble if desired
        }
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _currentResponse = "";
      _textController.clear();
    });
    
    _chatService.sendMessage(text, modelType: _selectedModel);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chatService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate
      drawer: _buildSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "AURA",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              ),
              child: const Text(
                "PRO",
                style: TextStyle(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildModelSelector(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: index == 0 && !msg.isUser ? _buildBotCardMessage(msg.text) : _buildSimpleMessage(msg),
                );
              },
            ),
          ),
          _buildInputSection(),
          if (_currentThought.isNotEmpty || _currentTool.isNotEmpty) _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 50),
          // New Chat Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: InkWell(
                onTap: () => setState(() => _messages.clear()),
                child: const Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text("New chat", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          
          // Menu Items
          _buildSidebarItem(Icons.search, "Search chats"),
          _buildSidebarItem(Icons.folder_open, "Projects"),
          _buildSidebarItem(Icons.more_horiz, "More"),
          
          const Divider(color: Colors.white10),
          
          // Recents
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text("Recents", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 14),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "No recent chats",
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white10),
          
          // User Profile
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFF87171), // Salmon/Pinkish as per image
                  child: Text("VA", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("vijay adhith", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      Text("Free", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text("Upgrade", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      dense: true,
      onTap: () {},
    );
  }

  Widget _buildRecentItem(String title) {
    return ListTile(
      title: Text(
        title, 
        style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      onTap: () {},
    );
  }

  // --- RESTORED UI COMPONENTS ---

  Widget _buildModelSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_outlined, size: 16, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  "AURA Pipeline Active",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: msg.isUser ? Colors.white12 : Colors.transparent),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildBotCardMessage(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _handleSend(),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Message AURA...",
                  hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              height: 52,
              width: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Center(
        child: Text(
          _currentTool.isNotEmpty ? "Searching..." : "Thinking...",
          style: const TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
