import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/workspace_service.dart';
import 'workspace_chat_screen.dart';

class ProjectDashboardScreen extends StatelessWidget {
  final Project project;

  const ProjectDashboardScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final blueprint = project.blueprint;
    final roadmap = blueprint['MVP Roadmap'] ?? blueprint['roadmap'] ?? {};
    final techStack = blueprint['Tech Stack Recommendations'] ?? blueprint['tech_stack'] ?? [];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusOverview(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Neural Roadmap", Icons.alt_route_rounded),
                  const SizedBox(height: 16),
                  _buildRoadmap(roadmap),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Technical Blueprint", Icons.architecture_rounded),
                  const SizedBox(height: 16),
                  _buildTechStack(techStack),
                  const SizedBox(height: 32),
                  _buildSectionTitle("AI Strategy & Monetization", Icons.auto_awesome_rounded),
                  const SizedBox(height: 16),
                  _buildStrategyCard(blueprint),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => WorkspaceChatScreen(project: project))
        ),
        backgroundColor: AppColors.neonCyan,
        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.black),
        label: Text("Consult Co-Founder", style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(project.title, 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.neonCyan.withOpacity(0.2), AppColors.background],
            ),
          ),
          child: Center(
            child: Icon(Icons.workspaces_filled, color: AppColors.neonCyan.withOpacity(0.1), size: 120),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem("Status", project.status.toUpperCase(), AppColors.neonCyan),
          ),
          Container(width: 1, height: 40, color: Colors.white10),
          Expanded(
            child: _buildStatItem("Progress", "${(project.progress * 100).toInt()}%", Colors.white),
          ),
          Container(width: 1, height: 40, color: Colors.white10),
          Expanded(
            child: _buildStatItem("Category", project.tag, Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonCyan, size: 18),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRoadmap(dynamic roadmap) {
    if (roadmap is! Map) return const Text("Architecting roadmap...", style: TextStyle(color: Colors.white38));
    
    return Column(
      children: roadmap.entries.map((e) => _buildRoadmapItem(e.key, e.value)).toList(),
    );
  }

  Widget _buildRoadmapItem(String phase, dynamic content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.neonCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(phase.replaceAll("Phase ", "P"), style: GoogleFonts.firaCode(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(content.toString(), style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStack(dynamic stack) {
    List<String> items = [];
    if (stack is List) items = stack.map((e) => e.toString()).toList();
    else if (stack is Map) items = stack.values.map((e) => e.toString()).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(item, style: GoogleFonts.firaCode(color: Colors.white, fontSize: 11)),
      )).toList(),
    );
  }

  Widget _buildStrategyCard(Map<String, dynamic> blueprint) {
    final strategy = blueprint['Monetization Ideas'] ?? blueprint['monetization'] ?? "Strategy analysis pending...";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.transparent]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(strategy.toString(), 
        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic)),
    );
  }
}
