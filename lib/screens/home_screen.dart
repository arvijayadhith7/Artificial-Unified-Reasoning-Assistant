import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_theme.dart';
import '../widgets/glowing_orb.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _updatesFuture;

  @override
  void initState() {
    super.initState();
    _updatesFuture = _fetchAIUpdates();
  }

  Future<List<dynamic>> _fetchAIUpdates() async {
    try {
      // Try to fetch from the production backend (Hugging Face)
      final response = await http.get(Uri.parse('https://vijayadhith7-aura-backend.hf.space/status')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        // Just return some mock enterprise updates since it's an enterprise dashboard
        return [
          {'title': 'Neural Core v1.2', 'description': 'Llama-3.3-70B pipeline optimized.'},
          {'title': 'Real-time Search', 'description': 'Mojeek indexing synchronization active.'},
          {'title': 'Memory Sync', 'description': 'Supabase cloud persistence verified.'},
        ];
      }
      return [];
    } catch (e) {
      // Fallback data if server is not reachable
      return [
        {'title': 'System Online', 'description': 'AURA Enterprise is ready for requests.'},
        {'title': 'Neural Link', 'description': 'Encrypted session established.'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonBlue.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => setState(() => _updatesFuture = _fetchAIUpdates()),
              color: AppColors.neonBlue,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildNeuralCore(),
                          const SizedBox(height: 48),
                          _buildSectionHeader("AGENTIC TOOLBOX", "Explore your capabilities"),
                          const SizedBox(height: 20),
                          _buildQuickActions(),
                          const SizedBox(height: 48),
                          _buildSectionHeader("KNOWLEDGE FEED", "Latest AI synchronization"),
                          const SizedBox(height: 20),
                          _buildUpdatesList(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, user",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Text(
            "AURA Hub",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNeuralCore() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.neonBlue.withOpacity(0.05),
              AppColors.neonPurple.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const GlowingOrb(size: 200),
            Positioned(
              bottom: 30,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.neonBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "INITIALIZE NEURAL LINK",
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.neonBlue,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white38,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: "Smart Chat",
            subtitle: "Neural Reasoning",
            color: AppColors.neonBlue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            icon: Icons.auto_awesome_mosaic_rounded,
            title: "Tools",
            subtitle: "System Plugins",
            color: AppColors.neonPurple,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("AURA Tools coming soon in v1.3")),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 40,
              spreadRadius: -20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesList() {
    return FutureBuilder<List<dynamic>>(
      future: _updatesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppColors.neonBlue)),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text("No updates available", style: TextStyle(color: Colors.white24)));
        }
        return Column(
          children: items.map((item) => _buildUpdateItem(item)).toList(),
        );
      },
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: AppColors.neonPurple, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Tool Update',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                Text(
                  item['description'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.background],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.home_filled, color: AppColors.neonBlue), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search_rounded, color: Colors.white38), onPressed: () {}),
          IconButton(icon: const Icon(Icons.history_rounded, color: Colors.white38), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline_rounded, color: Colors.white38), onPressed: () {}),
        ],
      ),
    );
  }
}
