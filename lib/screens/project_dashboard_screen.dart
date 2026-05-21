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
    final domainClusters = blueprint['domain_clusters'] ?? {};
    final aiOpportunities = blueprint['ai_opportunities'] ?? blueprint['AI Opportunities'] ?? [];
    final risks = blueprint['risks'] ?? [];
    final scalability = blueprint['scalability_suggestions'] ?? [];
    final monetization = blueprint['Monetization Ideas'] ?? blueprint['monetization'] ?? [];
    final architectureSuggestion = blueprint['architecture_suggestion'] ?? blueprint['Architecture Strategy'] ?? '';
    final summary = blueprint['summary'] ?? blueprint['Summary'] ?? '';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusOverview(),
                  
                  // Summary Section
                  if (summary.toString().isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSummaryCard(summary.toString()),
                  ],
                  
                  // Domain Clusters Section
                  if (domainClusters is Map && domainClusters.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle("Domain Clusters", Icons.hub_rounded),
                    const SizedBox(height: 16),
                    _buildDomainClusters(domainClusters),
                  ],

                  // Neural Roadmap
                  const SizedBox(height: 32),
                  _buildSectionTitle("Neural Roadmap", Icons.alt_route_rounded),
                  const SizedBox(height: 16),
                  _buildRoadmap(roadmap),
                  
                  // Technical Blueprint
                  const SizedBox(height: 32),
                  _buildSectionTitle("Technical Blueprint", Icons.architecture_rounded),
                  const SizedBox(height: 16),
                  _buildTechStack(techStack),
                  
                  // Architecture Suggestion
                  if (architectureSuggestion.toString().isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle("Architecture Strategy", Icons.schema_rounded),
                    const SizedBox(height: 16),
                    _buildInfoCard(architectureSuggestion.toString(), AppColors.electricBlue),
                  ],
                  
                  // AI Opportunities
                  if (_hasContent(aiOpportunities)) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle("AI Opportunities", Icons.psychology_rounded),
                    const SizedBox(height: 16),
                    _buildListSection(aiOpportunities, AppColors.violetGlow),
                  ],
                  
                  // Monetization
                  if (_hasContent(monetization)) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle("Monetization Strategy", Icons.auto_awesome_rounded),
                    const SizedBox(height: 16),
                    _buildListSection(monetization, AppColors.neonCyan),
                  ],
                  
                  // Risks
                  if (_hasContent(risks)) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle("Risks & Mitigations", Icons.warning_amber_rounded),
                    const SizedBox(height: 16),
                    _buildListSection(risks, Colors.orangeAccent),
                  ],
                  
                  // Scalability
                  if (_hasContent(scalability)) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle("Scalability Roadmap", Icons.trending_up_rounded),
                    const SizedBox(height: 16),
                    _buildListSection(scalability, Colors.greenAccent),
                  ],
                  
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
  
  bool _hasContent(dynamic data) {
    if (data == null) return false;
    if (data is List) return data.isNotEmpty;
    if (data is String) return data.isNotEmpty;
    if (data is Map) return data.isNotEmpty;
    return false;
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

  Widget _buildSummaryCard(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.neonCyan.withOpacity(0.05),
            AppColors.electricBlue.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.neonCyan, size: 16),
              const SizedBox(width: 8),
              Text("PROJECT SUMMARY",
                style: GoogleFonts.outfit(
                  color: AppColors.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(summary, 
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildDomainClusters(Map<dynamic, dynamic> clusters) {
    final domains = clusters['domains'];
    final subdomains = clusters['subdomains'];
    final relatedTech = clusters['related_technologies'];
    final recommendedArch = clusters['recommended_architecture'];
    final learningRoadmap = clusters['learning_roadmap'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violetGlow.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Domains
          if (domains != null) ...[
            Text("PRIMARY DOMAINS",
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _toStringList(domains).map((d) => _buildClusterChip(d, AppColors.neonCyan)).toList(),
            ),
          ],
          
          // Subdomains
          if (subdomains != null) ...[
            const SizedBox(height: 20),
            Text("SUBDOMAINS",
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _toStringList(subdomains).map((d) => _buildClusterChip(d, AppColors.electricBlue)).toList(),
            ),
          ],
          
          // Related Technologies
          if (relatedTech != null) ...[
            const SizedBox(height: 20),
            Text("RELATED TECHNOLOGIES",
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _toStringList(relatedTech).map((d) => _buildClusterChip(d, AppColors.violetGlow)).toList(),
            ),
          ],
          
          // Recommended Architecture
          if (recommendedArch != null && recommendedArch.toString().isNotEmpty) ...[
            const SizedBox(height: 20),
            Text("RECOMMENDED ARCHITECTURE",
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            Text(recommendedArch.toString(),
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5)),
          ],
          
          // Learning Roadmap
          if (learningRoadmap != null) ...[
            const SizedBox(height: 20),
            Text("LEARNING ROADMAP",
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            ..._toStringList(learningRoadmap).asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22, height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text("${entry.key + 1}",
                        style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.value,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, height: 1.4)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildClusterChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text,
        style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  List<String> _toStringList(dynamic data) {
    if (data is List) return data.map((e) => e.toString()).toList();
    if (data is String) return [data];
    return [];
  }

  Widget _buildRoadmap(dynamic roadmap) {
    if (roadmap is! Map) return Text("Architecting roadmap...", style: GoogleFonts.outfit(color: Colors.white38));
    
    return Column(
      children: roadmap.entries.map((e) => _buildRoadmapItem(e.key.toString(), e.value)).toList(),
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
  
  Widget _buildInfoCard(String text, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accentColor.withOpacity(0.05), Colors.transparent]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Text(text, 
        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5)),
    );
  }

  Widget _buildListSection(dynamic data, Color accentColor) {
    List<String> items = [];
    if (data is List) {
      items = data.map((e) => e.toString()).toList();
    } else if (data is String) {
      items = [data];
    } else if (data is Map) {
      items = data.entries.map((e) => "${e.key}: ${e.value}").toList();
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(entry.value,
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
