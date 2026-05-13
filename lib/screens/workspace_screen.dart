import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu_rounded, color: Colors.white),
        title: Text("AURA", style: GoogleFonts.outfit(fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          const Icon(Icons.search_rounded, color: Colors.white54, size: 24),
          const SizedBox(width: 16),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.neonCyan)),
            child: const CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Workspace Overview", style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Welcome back. Your AI clusters are running at peak efficiency with 4 active neural threads.", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4)),
            const SizedBox(height: 24),

            // Start New Project
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFF8C52FF), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text("Start New Project", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Active Projects
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Active Projects", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("View All", style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildProjectCard("NEURAL NETWORK", "Quantum Synthesis v4", 0.84, "84%", [11, 33], "+3", const Color(0xFF8C52FF), Icons.hub_outlined),
            const SizedBox(height: 16),
            _buildProjectCard("MARKET INTEL", "Trend Scout AI", 0.42, "42%", [], "", const Color(0xFFFFB74D), Icons.analytics_outlined, subtitle: "Analyzing 1.2M data points..."),
            const SizedBox(height: 32),

            // Recent Documents
            Text("Recent Documents", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDocItem("Q4 Neural Roadmap.pdf", "PDF • 12.4 MB • Edited 15m ago", 'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?auto=format&fit=crop&w=100&q=80'),
            _buildDocItem("Interface Guidelines v2", "Doc • 4.2 MB • Edited 2h ago", 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=100&q=80'),
            _buildDocItem("Market Analysis 2024", "Sheet • 2.1 MB • Edited yesterday", 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=100&q=80'),
            const SizedBox(height: 32),

            // AURA Intelligence Thread
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF8C52FF).withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, color: Color(0xFFE0B0FF), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("AURA Intelligence", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("v2.0 Active Thread", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
                      children: const [
                        TextSpan(text: "\"Quantum Synthesis optimization is currently at "),
                        TextSpan(text: "84%", style: TextStyle(color: Color(0xFFE0B0FF), fontWeight: FontWeight.bold)),
                        TextSpan(text: ". Predicted completion in "),
                        TextSpan(text: "14 minutes", style: TextStyle(color: Color(0xFFE0B0FF), fontWeight: FontWeight.bold)),
                        TextSpan(text: ". Should I prepare the briefing for the dev team?\""),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                          child: Text("Yes, prepare it", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                          child: Text("Not yet", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Compute Load", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text("62%", style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Memory Usage", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text("4.8 GB / 12 GB", style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(String tag, String title, double progress, String progressTxt, List<int> avatars, String extraAvatar, Color color, IconData icon, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tag, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
          if (subtitle != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Analysis", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                Text(progressTxt, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              ),
            ),
            const SizedBox(height: 12),
            Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
          ] else ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Optimization Progress", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                Text(progressTxt, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 24,
                  child: Stack(
                    children: [
                      if (avatars.isNotEmpty) Positioned(left: 0, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${avatars[0]}'))),
                      if (avatars.length > 1) Positioned(left: 18, child: CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${avatars[1]}'))),
                      if (extraAvatar.isNotEmpty) Positioned(left: 36, child: CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Text(extraAvatar, style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.access_time, color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text("2h ago", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDocItem(String title, String subtitle, String imgUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.white54, size: 20),
        ],
      ),
    );
  }
}
