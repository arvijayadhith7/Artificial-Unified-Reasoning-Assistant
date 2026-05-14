import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../cricket_service.dart';

class CricketScreen extends StatefulWidget {
  const CricketScreen({super.key});

  @override
  State<CricketScreen> createState() => _CricketScreenState();
}

class _CricketScreenState extends State<CricketScreen> {
  final CricketService _cricketService = CricketService();
  List<dynamic> _liveMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    final matches = await _cricketService.getCurrentMatches();
    setState(() {
      _liveMatches = matches;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu_rounded, color: Colors.white),
        title: Text("AURA", style: GoogleFonts.outfit(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchMatches,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.neonCyan, size: 20),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.neonCyan)),
            child: const CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMatches,
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Cricket Hub", style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text("Real-time ball-by-ball analysis, live scores, and trending cricket insights curated by AURA.", 
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5)),
              // AURA IPL Intelligence Section
              FutureBuilder<String?>(
                future: _cricketService.getAuraIPLScore(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFFFF4B2B).withOpacity(0.15), const Color(0xFFFF416C).withOpacity(0.15)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFF4B2B).withOpacity(0.3)),
                        boxShadow: [
                           BoxShadow(color: const Color(0xFFFF4B2B).withOpacity(0.1), blurRadius: 20, spreadRadius: -5),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.flash_on_rounded, color: Color(0xFFFF4B2B), size: 18),
                                  const SizedBox(width: 8),
                                  Text("IPL 2026 LIVE TICKER", style: GoogleFonts.outfit(color: const Color(0xFFFF4B2B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFF4B2B), borderRadius: BorderRadius.circular(8)),
                                child: Text("LIVE", style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(snapshot.data!, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Color(0xFFFF4B2B), size: 14),
                              const SizedBox(width: 8),
                              Text("AURA Real-time Analysis", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 8),

              // Live Matches Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.live_tv_rounded, color: AppColors.electricBlue, size: 20),
                      const SizedBox(width: 8),
                      Text("Live Matches", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
              else if (_liveMatches.isEmpty)
                _buildEmptyState()
              else
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _liveMatches.length,
                    itemBuilder: (context, index) {
                      return _buildMatchCard(_liveMatches[index]);
                    },
                  ),
                ),

              const SizedBox(height: 32),

              // Match Analytics (Static for now, as API provides basic score)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Match Analytics", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Icon(Icons.analytics_outlined, color: AppColors.neonCyan, size: 20),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildAnalyticCard("WIN PROBABILITY", "IND 72%")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildAnalyticCard("PREDICTED SCORE", "380-400")),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Latest News (Mocked for premium feel)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.newspaper_rounded, color: AppColors.electricBlue, size: 20),
                      const SizedBox(width: 8),
                      Text("Latest Cricket News", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text("View All", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              _buildNewsItem("MATCH REPORT", "Kohli's Masterclass leads India to a historic victory in Perth", "2 hours ago • 5 min read"),
              _buildNewsItem("IPL 2024", "IPL Auction 2024: Key Highlights and Record-Breaking Bids", "5 hours ago • 8 min read"),
              _buildNewsItem("TEAM NEWS", "Rising Star: Analyzing the impact of new pace sensations", "Yesterday • 4 min read"),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_cricket_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          Text("No Live Matches", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Check back later for ongoing international and domestic fixtures.", textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMatchCard(dynamic match) {
    final name = match['name'] ?? 'Unknown Match';
    final status = match['status'] ?? 'Scheduled';
    final matchType = (match['matchType'] ?? 'T20').toUpperCase();
    final teams = (name as String).split(' vs ');
    final team1 = teams.length > 0 ? teams[0] : 'T1';
    final team2 = teams.length > 1 ? teams[1] : 'T2';
    
    final scoreList = match['score'] as List?;
    String score1 = "Yet to bat";
    String score2 = "Yet to bat";
    
    if (scoreList != null && scoreList.isNotEmpty) {
      score1 = "${scoreList[0]['r']}/${scoreList[0]['w']} (${scoreList[0]['o']})";
      if (scoreList.length > 1) {
        score2 = "${scoreList[1]['r']}/${scoreList[1]['w']} (${scoreList[1]['o']})";
      }
    }

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(matchType, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              if (match['matchStarted'] == true && match['matchEnded'] == false)
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text("LIVE", style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                )
            ],
          ),
          const SizedBox(height: 20),
          _buildTeamRow(team1, score1),
          const SizedBox(height: 12),
          _buildTeamRow(team2, score2),
          const Spacer(),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTeamRow(String name, String score) {
    return Row(
      children: [
        CircleAvatar(radius: 10, backgroundColor: Colors.white.withOpacity(0.1), child: Text(name[0], style: const TextStyle(fontSize: 10, color: Colors.white))),
        const SizedBox(width: 12),
        Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
        Text(score, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildAnalyticCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNewsItem(String category, String title, String meta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.image_outlined, color: Colors.white10),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: GoogleFonts.outfit(color: AppColors.neonCyan.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(height: 8),
                Text(meta, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
