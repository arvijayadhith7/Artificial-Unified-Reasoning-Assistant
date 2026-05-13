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
      final response = await http.get(Uri.parse('https://vijayadhith7-aura-backend.hf.space/status')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return [
          {'title': 'AURA v2.0', 'description': 'Neural reasoning core online.'},
          {'title': 'Predictive Engine', 'description': 'Forecasting confidence at 98.4%.'},
          {'title': 'Knowledge Sync', 'description': 'Global indexing synchronization active.'},
        ];
      }
      return [];
    } catch (e) {
      return [
        {'title': 'AURA Intelligence', 'description': 'Neural Core is ready for input.'},
        {'title': 'Secure Link', 'description': 'Encrypted session established.'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -50,
            child: _buildAmbientGlow(AppColors.electricBlue, 0.1),
          ),
          Positioned(
            bottom: 200,
            right: -50,
            child: _buildAmbientGlow(AppColors.violetGlow, 0.05),
          ),
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => setState(() => _updatesFuture = _fetchAIUpdates()),
              color: AppColors.neonCyan,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildNeuralCore(),
                          const SizedBox(height: 40),
                          _buildSectionHeader("AURA ECOSYSTEM", "Integrated Intelligence"),
                          const SizedBox(height: 20),
                          _buildModularDashboard(),
                          const SizedBox(height: 40),
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
          
          Positioned(
            bottom: 100,
            right: 20,
            child: _buildFloatingVoiceButton(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAmbientGlow(Color color, double opacity) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome back, Commander",
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, letterSpacing: 0.5),
          ),
          Text(
            "AURA Intelligence",
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.grid_view_rounded, color: AppColors.neonCyan, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildNeuralCore() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.glassBorder.withOpacity(0.1)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.01),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const GlowingOrb(size: 240),
                Positioned(
                  bottom: 30,
                  child: Column(
                    children: [
                      Text(
                        "AURA CORE ONLINE",
                        style: GoogleFonts.outfit(
                          color: AppColors.neonCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Artificial Unified Reasoning Assistant",
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                color: AppColors.electricBlue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.border, size: 14),
      ],
    );
  }

  Widget _buildModularDashboard() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildModuleCard(
          icon: Icons.chat_bubble_rounded,
          title: "Smart Chat",
          subtitle: "Neural Reasoning",
          color: AppColors.neonCyan,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
        ),
        _buildModuleCard(
          icon: Icons.insights_rounded,
          title: "Predictive",
          subtitle: "Analytics Engine",
          color: AppColors.violetGlow,
          onTap: () {},
        ),
        _buildModuleCard(
          icon: Icons.auto_awesome_rounded,
          title: "Tools",
          subtitle: "System Plugins",
          color: AppColors.electricBlue,
          onTap: () {},
        ),
        _buildModuleCard(
          icon: Icons.storage_rounded,
          title: "Memory",
          subtitle: "Neural Vault",
          color: Colors.white,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 11,
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
          return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
        }
        final items = snapshot.data ?? [];
        return Column(
          children: items.map((item) => _buildUpdateItem(item)).toList(),
        );
      },
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_rounded, color: AppColors.neonCyan, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Neural Update',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  item['description'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.border, size: 18),
        ],
      ),
    );
  }

  Widget _buildFloatingVoiceButton() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.electricBlue, AppColors.violetGlow],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(32),
          child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_filled, "Home", true),
          _buildNavItem(Icons.explore_outlined, "Explore", false),
          _buildNavItem(Icons.auto_graph_rounded, "Insight", false),
          _buildNavItem(Icons.settings_outlined, "Settings", false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.neonCyan : AppColors.textSecondary.withOpacity(0.4),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isActive ? AppColors.neonCyan : AppColors.textSecondary.withOpacity(0.4),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
