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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("AURA RESEARCH", style: GoogleFonts.outfit(fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
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
                  icon: const Icon(Icons.search_rounded, color: AppColors.neonCyan, size: 20),
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Intelligence Discovery Section
            if (researchState.synthesis.isEmpty && !researchState.isResearching) ...[
              Text("Intelligence Discovery", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildDiscoveryCard("Latest AI trends in 2026", Icons.auto_awesome),
                  _buildDiscoveryCard("Research about NVIDIA AI chips", Icons.memory_rounded),
                  _buildDiscoveryCard("Compare GPT-5 vs Claude", Icons.compare_arrows_rounded),
                  _buildDiscoveryCard("Future of Quantum Computing", Icons.science_rounded),
                  _buildDiscoveryCard("Latest IPL statistics", Icons.sports_cricket_rounded),
                  _buildDiscoveryCard("Best open-source AI models", Icons.folder_shared_rounded),
                ],
              ),
              const SizedBox(height: 24),
            ],

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
                        Text("Synthesis Stream", style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 20, fontWeight: FontWeight.bold, height: 1.1)),
                        const Icon(Icons.auto_awesome, color: Color(0xFFE0B0FF), size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MarkdownBody(
                      data: researchState.synthesis,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6),
                        h1: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        listBullet: GoogleFonts.outfit(color: const Color(0xFFE0B0FF)),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryCard(String title, IconData icon) {
    return InkWell(
      onTap: () {
        _searchController.text = title;
        ref.read(researchProvider.notifier).startResearch(title, _selectedCategory);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: const Color(0xFFE0B0FF), size: 20),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool active, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = label);
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
}
