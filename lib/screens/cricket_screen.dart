import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../app_theme.dart';
import '../cricket_service.dart';

class CricketScreen extends StatefulWidget {
  const CricketScreen({super.key});

  @override
  State<CricketScreen> createState() => _CricketScreenState();
}

class _CricketScreenState extends State<CricketScreen> with SingleTickerProviderStateMixin {
  final CricketService _cricketService = CricketService();
  late AnimationController _pulseController;
  Map<String, dynamic>? _intelData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fetchAuraIntel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuraIntel() async {
    setState(() => _isLoading = true);
    final data = await _cricketService.getAuraIPLIntel();
    setState(() {
      _intelData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildNeuralBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchAuraIntel,
              color: AppColors.neonCyan,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _isLoading 
                        ? _buildLoadingState() 
                        : (_intelData == null ? _buildEmptyState() : _buildIntelDashboard()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeuralBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.neonCyan.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.violetGlow.withOpacity(0.05), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "CRICKET INTEL",
        style: GoogleFonts.outfit(
          fontSize: 12,
          letterSpacing: 6,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
          onPressed: _fetchAuraIntel,
        ),
      ],
    );
  }

  Widget _buildIntelDashboard() {
    final hero = _intelData!['match_hero'] ?? {};
    final winProb = _intelData!['win_probability'] ?? {};
    final insights = _intelData!['ai_insights'] as List? ?? [];
    final timeline = _intelData!['smart_timeline'] as List? ?? [];
    final players = _intelData!['player_impact'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildHeroMatchCard(hero),
        const SizedBox(height: 32),
        _buildWinProbabilitySection(winProb, hero['teams']),
        const SizedBox(height: 40),
        _buildSectionHeader("NEURAL INSIGHTS", Icons.auto_awesome_rounded),
        const SizedBox(height: 20),
        ...insights.map((insight) => _buildInsightItem(insight)),
        const SizedBox(height: 40),
        _buildSectionHeader("PLAYER IMPACT", Icons.bolt_rounded),
        const SizedBox(height: 20),
        _buildPlayerImpactSection(players),
        const SizedBox(height: 40),
        _buildSectionHeader("MATCH TIMELINE", Icons.timeline_rounded),
        const SizedBox(height: 20),
        ...timeline.map((event) => _buildTimelineItem(event)),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHeroMatchCard(Map<String, dynamic> hero) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTeamInitial(hero['teams']?[0] ?? "T1"),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withOpacity(0.1 + (_pulseController.value * 0.1)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: AppColors.neonCyan, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text("LIVE INTEL", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildTeamInitial(hero['teams']?[1] ?? "T2"),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  hero['score'] ?? "Initializing...",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
                ),
                const SizedBox(height: 12),
                Text(
                  hero['status'] ?? "Connecting to match clusters...",
                  style: GoogleFonts.outfit(color: AppColors.neonCyan.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMetaStat("CRR", hero['run_rate'] ?? "0.0"),
                    Container(width: 1, height: 20, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 20)),
                    _buildMetaStat("RRR", hero['required_rr'] ?? "0.0"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInitial(String name) {
    return Column(
      children: [
        Container(
          width: 50, height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: Text(name.substring(0, min(name.length, 3)).toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Text(name, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _buildMetaStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildWinProbabilitySection(Map<String, dynamic> winProb, List<dynamic>? teams) {
    final t1Prob = (winProb['team_a'] ?? 50).toDouble();
    final t2Prob = (winProb['team_b'] ?? 50).toDouble();
    final t1Name = teams?[0] ?? "Team A";
    final t2Name = teams?[1] ?? "Team B";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t1Name.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
            Text("WIN PROBABILITY", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w900)),
            Text(t2Name.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(6)),
            ),
            Row(
              children: [
                Expanded(
                  flex: t1Prob.toInt(),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF00FFFF)]),
                      borderRadius: BorderRadius.horizontal(left: const Radius.circular(6), right: Radius.circular(t1Prob > 95 ? 6 : 0)),
                    ),
                  ),
                ),
                Expanded(
                  flex: t2Prob.toInt(),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B00FF), Color(0xFFFF00FF)]),
                      borderRadius: BorderRadius.horizontal(right: const Radius.circular(6), left: Radius.circular(t2Prob > 95 ? 6 : 0)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$t1Prob%", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 18, fontWeight: FontWeight.w900)),
            Text("$t2Prob%", style: GoogleFonts.outfit(color: AppColors.violetGlow, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonCyan, size: 16),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildInsightItem(String insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 16),
          Expanded(child: Text(insight, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildPlayerImpactSection(List<dynamic> players) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final p = players[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(p['name'] ?? "Unknown", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    Text("${p['score']}", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
                const Spacer(),
                Text(p['analysis'] ?? "", maxLines: 2, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event) {
    Color color;
    switch (event['type']?.toString().toUpperCase()) {
      case "WICKET": color = Colors.redAccent; break;
      case "SIX":
      case "FOUR": color = AppColors.neonCyan; break;
      default: color = Colors.white24;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Text(event['time'] ?? "0", style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['event'] ?? "Update", style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(event['desc'] ?? "", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const CircularProgressIndicator(color: AppColors.neonCyan),
          const SizedBox(height: 24),
          Text("Synchronizing Neural Match Clusters...", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.sports_cricket_rounded, color: Colors.white10, size: 64),
          const SizedBox(height: 24),
          Text("Neural link established. No live match data clusters detected.", textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }
}

