import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/workspace_service.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu_rounded, color: Colors.white),
        title: Text("AURA WORKSPACE", style: GoogleFonts.outfit(fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white)),
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
      body: RefreshIndicator(
        onRefresh: () => ref.read(workspaceProvider.notifier).fetchProjects(),
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Workspace Overview", style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Welcome back. Your AI clusters are running at peak efficiency with ${workspaceState.projects.length} active neural threads.", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),

              // Start New Project
              GestureDetector(
                onTap: () => _showCreateProjectDialog(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8C52FF), Color(0xFF6B8AFD)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF8C52FF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text("Start New Project", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
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
              
              if (workspaceState.isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
              else if (workspaceState.projects.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.folder_open_rounded, color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      Text("No active projects found.", style: GoogleFonts.outfit(color: Colors.white38)),
                    ],
                  ),
                )
              else
                ...workspaceState.projects.map((project) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildProjectCard(project),
                )),

              const SizedBox(height: 32),

              // Recent Documents
              Text("Recent Documents", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDocItem("Q4 Neural Roadmap.pdf", "PDF • 12.4 MB • Edited 15m ago", 'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?auto=format&fit=crop&w=100&q=80'),
              _buildDocItem("Interface Guidelines v2", "Doc • 4.2 MB • Edited 2h ago", 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=100&q=80'),
              _buildDocItem("Market Analysis 2024", "Sheet • 2.1 MB • Edited yesterday", 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=100&q=80'),
              const SizedBox(height: 32),

              // AURA Intelligence Thread
              if (workspaceState.projects.isNotEmpty)
                _buildIntelligencePanel(workspaceState.suggestion, workspaceState.projects.first.id),
              
              const SizedBox(height: 32),

              // Planning & Research Hub
              Text("Neural Planning Hub", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPlanningCard("Research Strategy", "Analyze market trends and competitor clusters.", Icons.biotech_rounded, Colors.cyanAccent),
              _buildPlanningCard("Development Roadmap", "Execute neural link integrations and core optimization.", Icons.alt_route_rounded, const Color(0xFFE0B0FF)),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        title: Text("Create Neural Project", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Project Title",
                hintStyle: GoogleFonts.outfit(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Short Description",
                hintStyle: GoogleFonts.outfit(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref.read(workspaceProvider.notifier).createProject(titleController.text, descController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C52FF)),
            child: Text("Initialize", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligencePanel(String suggestion, String projectId) {
    return Container(
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
                  Text("Active Planning Thread", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          if (suggestion.isEmpty)
             Center(
               child: TextButton(
                 onPressed: () => ref.read(workspaceProvider.notifier).getSuggestion(projectId),
                 child: Text("Generate Proactive Suggestion", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
               ),
             )
          else
            Text(suggestion, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Text("Accept Suggestion", style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Text("Dismiss", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(project.tag, style: GoogleFonts.outfit(color: const Color(0xFF8C52FF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              GestureDetector(
                onTap: () => ref.read(workspaceProvider.notifier).deleteProject(project.id),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(project.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 8),
          Text(project.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, height: 1.4)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Project Progress", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
              Text("${(project.progress * 100).toInt()}%", style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: project.progress.clamp(0.01, 1.0),
              child: Container(decoration: BoxDecoration(color: const Color(0xFF8C52FF), borderRadius: BorderRadius.circular(2))),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(project.lastActive, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
              const Spacer(),
              _buildSmallAction("Chat", Icons.chat_bubble_outline_rounded),
              const SizedBox(width: 8),
              _buildSmallAction("Files", Icons.folder_open_rounded),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPlanningCard(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(desc, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
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
          Icon(icon, color: Colors.white54, size: 10),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
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
