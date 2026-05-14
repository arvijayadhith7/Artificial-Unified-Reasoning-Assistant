import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../app_theme.dart';
import '../services/research_service.dart';

class ResearchScreen extends ConsumerStatefulWidget {
  const ResearchScreen({super.key});

  @override
  ConsumerState<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends ConsumerState<ResearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Web";

  @override
  Widget build(BuildContext context) {
    final researchState = ref.watch(researchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu_rounded, color: Colors.white),
        title: Text("AURA RESEARCH", style: GoogleFonts.outfit(fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (researchState.isResearching)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan)),
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                  hintText: "Explore complex research domains...",
                  hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    ref.read(researchProvider.notifier).startResearch(value, _selectedCategory);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("Web", Icons.language_rounded, _selectedCategory == "Web", const Color(0xFFE0B0FF)),
                  _buildFilterChip("Academic", Icons.school_outlined, _selectedCategory == "Academic", Colors.cyanAccent),
                  _buildFilterChip("GitHub", Icons.code_rounded, _selectedCategory == "GitHub", Colors.greenAccent),
                  _buildFilterChip("News", Icons.article_outlined, _selectedCategory == "News", Colors.orangeAccent),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: Colors.white24),
                  const SizedBox(width: 8),
                  _buildFilterChip("History", Icons.history_rounded, false, Colors.white54),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status Indicator
            if (researchState.status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE0B0FF)),
                    ),
                    const SizedBox(width: 12),
                    Text(researchState.status.toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),

            // Synthesis Stream
            if (researchState.synthesis.isNotEmpty || researchState.isResearching)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Synthesis\nStream", style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 20, fontWeight: FontWeight.bold, height: 1.1)),
                        const Icon(Icons.auto_awesome, color: Color(0xFFE0B0FF), size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MarkdownBody(
                      data: researchState.synthesis,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
                        h1: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        h2: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        listBullet: GoogleFonts.outfit(color: const Color(0xFFE0B0FF)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Source Cards
            if (researchState.sources.isNotEmpty) ...[
              Text("Verified Sources", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...researchState.sources.map((source) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildSourceCard(source),
              )),
            ],

            const SizedBox(height: 24),

            // Visual Correlation Graph
            if (researchState.correlations.isNotEmpty) ...[
              Text("Visual Correlation", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: CustomPaint(
                  painter: CorrelationGraphPainter(researchState.correlations),
                  child: Container(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Follow-up Section
            if (researchState.synthesis.isNotEmpty && !researchState.isResearching)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: Color(0xFFE0B0FF), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Ask a follow-up question...",
                          hintStyle: GoogleFonts.outfit(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                           if (value.isNotEmpty) {
                             ref.read(researchProvider.notifier).startResearch(value, _selectedCategory);
                           }
                        },
                      ),
                    ),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label != "History") _selectedCategory = label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.1) : Colors.transparent,
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
      ),
    );
  }

  Widget _buildSourceCard(String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(content, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSmallAction("Summarize", Icons.notes_rounded),
              const SizedBox(width: 8),
              _buildSmallAction("Cite", Icons.format_quote_rounded),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallAction(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE0B0FF), size: 10),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class CorrelationGraphPainter extends CustomPainter {
  final List<dynamic> correlations;
  CorrelationGraphPainter(this.correlations);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFE0B0FF).withOpacity(0.3)
      ..strokeWidth = 1;

    final nodePaint = Paint()..color = const Color(0xFFE0B0FF);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < correlations.length; i++) {
      final topic = correlations[i]['topic'] ?? '';
      final strength = (correlations[i]['strength'] ?? 0.5).toDouble();
      
      final angle = (i * 2 * 3.14159) / correlations.length;
      final radius = 60.0 + (strength * 20);
      final offset = Offset(center.dx + radius * 1.5 * (i % 2 == 0 ? 1 : -0.8), center.dy + radius * (i % 3 == 0 ? 1 : -0.5));

      canvas.drawLine(center, offset, paint);
      canvas.drawCircle(offset, (4.0 + strength * 4.0).toDouble(), nodePaint);
      
      textPainter.text = TextSpan(
        text: topic,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, offset + const Offset(8, -5));
    }

    canvas.drawCircle(center, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
