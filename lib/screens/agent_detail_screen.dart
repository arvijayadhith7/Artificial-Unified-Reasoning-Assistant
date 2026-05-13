import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class AgentDetailScreen extends StatelessWidget {
  const AgentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Creative Strategist", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text("ACTIVE", style: GoogleFonts.outfit(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
            child: const CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33')),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [const Color(0xFF6B8AFD).withOpacity(0.8), const Color(0xFFE0B0FF).withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=800&q=80'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                          child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Agent Identity", style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1)),
                              Text("Configuration", style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Fine-tuning the cognitive framework for high-level creative direction.",
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                Expanded(child: _buildStatBox("SUCCESS RATE", "98.4%", Icons.trending_up, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatBox("AVG. RESPONSE TIME", "1.2s", Icons.speed, const Color(0xFF6B8AFD))),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatBox("TOTAL TOKENS PROCESSED", "4.2M", Icons.data_usage, const Color(0xFFFFA07A), isFullWidth: true),
            const SizedBox(height: 32),

            // Skills & Capabilities
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text("Skills & Capabilities", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildToggleItem("Visual Trend Analysis", "Real-time aesthetic forecasting", true),
            const SizedBox(height: 12),
            _buildToggleItem("Narrative Synthesis", "Logical storytelling logic", true),
            const SizedBox(height: 12),
            _buildToggleItem("Brand Alignment", "Cross-referencing brand books", true),
            const SizedBox(height: 12),
            _buildToggleItem("Semantic Segmentation", "Deep content classification", false),
            const SizedBox(height: 32),

            // Model Parameters
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text("Model Parameters", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderItem("Temperature (Creativity)", "0.85", 0.85, "PRECISE", "BALANCED", "CHAOTIC", const Color(0xFFE0B0FF)),
            const SizedBox(height: 24),
            _buildSliderItem("Top-P (Nucleus Sampling)", "0.92", 0.92, "FOCUSED", "", "DIVERSE", const Color(0xFF6B8AFD)),
            const SizedBox(height: 32),

            // Knowledge Base
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.share_outlined, color: Color(0xFFFFA07A), size: 20),
                      const SizedBox(width: 8),
                      Text("Knowledge Base", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.add_circle_outline, color: Colors.white54),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildKnowledgeFile(Icons.folder_outlined, "Q4 Market Reports", "12 Documents • 4.2MB", const Color(0xFFE0B0FF)),
                  const SizedBox(height: 12),
                  _buildKnowledgeFile(Icons.description_outlined, "Brand Identity v2.4", "PDF Vector Index • 1.5MB", const Color(0xFF6B8AFD)),
                  const SizedBox(height: 12),
                  _buildKnowledgeFile(Icons.link_rounded, "Live Ad-Trends Web Feed", "Real-time Stream • API", const Color(0xFFFFA07A)),
                  
                  const SizedBox(height: 24),
                  Text("CONTEXT WINDOW USAGE", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Used: 84k Tokens", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                      Text("Max: 128k Tokens", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 84/128,
                      child: Container(decoration: BoxDecoration(color: const Color(0xFF6B8AFD), borderRadius: BorderRadius.circular(2))),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                    child: Text("Reset to\nDefaults", textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13, height: 1.2)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6B8AFD), Color(0xFF8C52FF)]), borderRadius: BorderRadius.circular(12)),
                    child: Text("Save\nChanges", textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value, style: GoogleFonts.outfit(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 2,
            width: isFullWidth ? 100 : double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, Colors.transparent]),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
              Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
            ],
          ),
          Container(
            width: 40, height: 24,
            decoration: BoxDecoration(color: isActive ? Colors.white : Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  right: isActive ? 4 : null,
                  left: isActive ? null : 4,
                  child: Container(width: 16, height: 16, decoration: BoxDecoration(color: isActive ? const Color(0xFF8C52FF) : Colors.white54, shape: BoxShape.circle)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSliderItem(String title, String value, double percent, String left, String mid, String right, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                child: Text(value, style: GoogleFonts.firaCode(color: color, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              ),
              Positioned(
                left: (MediaQueryData.fromView(PlatformDispatcher.instance.views.first).size.width - 72) * percent - 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(left, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
              if (mid.isNotEmpty) Text(mid, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
              Text(right, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKnowledgeFile(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13)),
              Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}
