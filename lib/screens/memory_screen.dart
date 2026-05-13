import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

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
            Text("Memory Sync", style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Refine how AURA perceives and remembers your digital identity. All knowledge is stored locally and encrypted.", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4)),
            const SizedBox(height: 32),

            // Core Identities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, color: const Color(0xFFE0B0FF), size: 20),
                    const SizedBox(width: 8),
                    Text("Core\nIdentities", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Text("Add Persona", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Personas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.work_outline, color: Color(0xFFE0B0FF), size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE0B0FF).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text("Active", style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Professional Architect", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Focuses on urban planning, sustainable materials, and CAD workflows.", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTag("Autodesk"),
                      const SizedBox(width: 8),
                      _buildTag("Sustainability"),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.palette_outlined, color: Color(0xFFFFB74D), size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                        child: Text("Secondary", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("Creative Explorer", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Personal interests in digital art, sci-fi literature, and synthwave music.", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTag("Digital Art"),
                      const SizedBox(width: 8),
                      _buildTag("Sci-Fi"),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Privacy Controls
            Text("Privacy Controls", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildToggleRow("Privacy Mode", "Pause new learning", false),
            const SizedBox(height: 16),
            _buildToggleRow("Context Retention", "Across all sessions", true),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFFE0B0FF), borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text("Purge All Records", style: GoogleFonts.outfit(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),

            // Sync Status
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [const Color(0xFFE0B0FF).withOpacity(0.5), Colors.transparent]),
                    ),
                    child: Center(
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFE0B0FF).withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.sync_rounded, color: Color(0xFFE0B0FF), size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Sync Status: Optimal", style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("42.8GB Neural Mapping Active", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Knowledge Graph
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hub_outlined, color: Color(0xFFE0B0FF), size: 20),
                      const SizedBox(width: 8),
                      Text("Knowledge Graph", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Interactive visual of associated memories", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE0B0FF), width: 2))),
                          const Icon(Icons.person_outline, color: Color(0xFFE0B0FF), size: 24),
                          // Abstract lines & dots for graph
                          Positioned(top: 20, left: 40, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF6B8AFD), shape: BoxShape.circle))),
                          Positioned(bottom: 20, right: 40, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: const Color(0xFFFFB74D), shape: BoxShape.circle))),
                          Positioned(right: 60, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white38, shape: BoxShape.circle))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.zoom_in_rounded, color: Colors.white54, size: 16)),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.filter_list_rounded, color: Colors.white54, size: 16)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Recently Learned
            Row(
              children: [
                const Icon(Icons.history_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text("Recently Learned", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            _buildTimelineItem("Today, 2:45 PM", "Sustainable Cement Research", "Archived interaction regarding carbon-negative construction materials in Northern Europe.", const Color(0xFFE0B0FF)),
            _buildTimelineItem("Yesterday, 9:12 AM", "Synthwave Playlist Refinement", "Updated music preference: prefers heavy bass, minimalist vocals, and retro-futurist aesthetics.", const Color(0xFFFFB74D)),
            _buildTimelineItem("Oct 22, 6:30 PM", "Core Identity: Professional Architect", "Primary persona established through career documentation analysis.", Colors.white38, isLast: true),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
          ],
        ),
        Container(
          width: 40, height: 20,
          decoration: BoxDecoration(color: isActive ? const Color(0xFFE0B0FF).withOpacity(0.5) : Colors.white10, borderRadius: BorderRadius.circular(10)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: isActive ? 2 : null,
                left: isActive ? null : 2,
                child: Container(width: 16, height: 16, decoration: BoxDecoration(color: isActive ? const Color(0xFFE0B0FF) : Colors.white54, shape: BoxShape.circle)),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTimelineItem(String time, String title, String desc, Color dotColor, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: dotColor, width: 2)),
              child: Center(child: Container(width: 4, height: 4, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle))),
            ),
            if (!isLast) Container(width: 2, height: 100, color: Colors.white10),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                  const Icon(Icons.delete_outline, color: Colors.white38, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(desc, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, height: 1.4)),
              const SizedBox(height: 24),
            ],
          ),
        )
      ],
    );
  }
}
