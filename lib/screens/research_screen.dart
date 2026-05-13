import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

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
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Text("Explore complex research do", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("Web", Icons.language_rounded, true, const Color(0xFFE0B0FF)),
                  _buildFilterChip("Academic", Icons.school_outlined, false, Colors.white54),
                  _buildFilterChip("News", Icons.article_outlined, false, Colors.white54),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: Colors.white24),
                  const SizedBox(width: 8),
                  _buildFilterChip("More Filters", Icons.filter_list_rounded, false, Colors.white54),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Synthesis Stream
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Synthesis\nStream", style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 20, fontWeight: FontWeight.bold, height: 1.1)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("REAL-TIME", style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Text("UPDATING", style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
                      children: const [
                        TextSpan(text: "Emerging patterns in neural architecture suggest a shift toward "),
                        TextSpan(text: "decentralized transformer logic. ", style: TextStyle(color: Color(0xFFE0B0FF), fontWeight: FontWeight.bold)),
                        TextSpan(text: "Recent findings from the Open-Source community align with academic papers published within the last 48 hours."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.show_chart_rounded, color: Color(0xFFFFB74D), size: 16),
                            const SizedBox(width: 8),
                            Text("Efficiency Metric", style: GoogleFonts.outfit(color: const Color(0xFFFFB74D), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBar(30, Colors.white24),
                            const SizedBox(width: 8),
                            _buildBar(40, Colors.white24),
                            const SizedBox(width: 8),
                            _buildBar(35, Colors.white24),
                            const SizedBox(width: 8),
                            _buildBar(50, Colors.white24),
                            const SizedBox(width: 8),
                            _buildBar(65, const Color(0xFFFFB74D)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.hub_outlined, color: Color(0xFF6B8AFD), size: 16),
                        const SizedBox(width: 8),
                        Text("Node Distribution", style: GoogleFonts.outfit(color: const Color(0xFF6B8AFD), fontSize: 11, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(value: 0.7, strokeWidth: 3, color: Color(0xFF6B8AFD), backgroundColor: Colors.white12),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // News Cards
            _buildNewsCard("TechCrunch", "5m ago", "Quantum Computing breakthrough announced in Zurich.", "Efficiency gains of 400% reported in low-temperature superconducting states...", "PHYSICS", const Color(0xFF00E5FF)),
            const SizedBox(height: 16),
            _buildNewsCard("arXiv", "2h ago", "Latent Space dynamics in high-dimensional manifolds.", "Proposed new methods for gradient descent optimization in sparse vectors...", "MATHEMATICS", const Color(0xFF00E5FF)),
            const SizedBox(height: 16),

            // Data Sources
            Text("Data Sources", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDataSourceTile(Icons.cloud_queue_rounded, "Public Web Archive", "4.2M docs scanned"),
            _buildDataSourceTile(Icons.storage_rounded, "PubMed Central", "Medical research focus"),
            _buildDataSourceTile(Icons.public_rounded, "Global News API", "Live world events"),
            const SizedBox(height: 24),

            // Latent Mapping
            Container(
              height: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("VISUAL CORRELATION", style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text("Latent Mapping Active", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.64,
                            child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text("64% Match", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8C52FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text("Synthesize", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
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

  Widget _buildFilterChip(String label, IconData icon, bool active, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(color: active ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 40,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
    );
  }

  Widget _buildNewsCard(String source, String time, String title, String desc, String tag, Color tagColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.article_rounded, color: Color(0xFF00E5FF), size: 12),
              ),
              const SizedBox(width: 8),
              Text("$source • $time", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 8),
          Text(desc, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
            child: Text(tag, style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          )
        ],
      ),
    );
  }

  Widget _buildDataSourceTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: Colors.white38, size: 16),
        ],
      ),
    );
  }
}
