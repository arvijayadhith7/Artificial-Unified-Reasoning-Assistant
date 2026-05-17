import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../app_theme.dart';
import '../services/workspace_service.dart';
import '../widgets/glass_project_card.dart';
import '../widgets/neural_empty_state.dart';
import 'project_onboarding_screen.dart';
import 'project_dashboard_screen.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildNeuralBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.read(workspaceProvider.notifier).fetchProjects(),
              color: AppColors.neonCyan,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(workspaceState.projects.length),
                          const SizedBox(height: 32),
                          _buildGlobalIntelligence(workspaceState),
                          const SizedBox(height: 48),
                          _buildProjectSection(workspaceState),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildNeuralBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -200,
              right: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.violetGlow.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.electricBlue.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80,
      floating: true,
      pinned: true,
      title: Text(
        "AURA OS",
        style: GoogleFonts.outfit(
          fontSize: 12,
          letterSpacing: 6,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
        onPressed: () {},
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
            ),
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.surface,
              child: Icon(Icons.person_outline, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int projectCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Command Center",
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "SYSTEM ACTIVE",
                style: GoogleFonts.outfit(
                  color: AppColors.neonCyan,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "$projectCount NEURAL THREADS INITIALIZED",
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlobalIntelligence(WorkspaceState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.white.withOpacity(0.01),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.neonCyan, size: 18),
              const SizedBox(width: 12),
              Text(
                "NEURAL INSIGHTS",
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            state.suggestion.isNotEmpty 
                ? state.suggestion 
                : "Scanning workspace for strategic optimizations... No immediate threats detected. System performance at 98.4%.",
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          if (state.projects.isNotEmpty && state.suggestion.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: GestureDetector(
                onTap: () => ref.read(workspaceProvider.notifier).getSuggestion(state.projects.first.id),
                child: Text(
                  "GENERATE PROACTIVE ANALYSIS →",
                  style: GoogleFonts.outfit(
                    color: AppColors.neonCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectSection(WorkspaceState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
    }

    if (state.projects.isEmpty) {
      return NeuralEmptyState(
        onCreatePressed: () => _showCreateProjectDialog(context, ref),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active Missions",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.sort_rounded, color: Colors.white24, size: 20),
          ],
        ),
        const SizedBox(height: 24),
        ...state.projects.map((project) => GlassProjectCard(
          project: project,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDashboardScreen(project: project),
            ),
          ),
          onDelete: () => ref.read(workspaceProvider.notifier).deleteProject(project.id),
        )),
      ],
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context, ref),
        backgroundColor: AppColors.electricBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String selectedCategory = "AI App";
    final categories = ["Mobile App", "AI App", "SaaS", "Website", "Dashboard", "Startup"];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Create",
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              title: Text(
                "Initiate Neural Project",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Mission Title...",
                      hintStyle: GoogleFonts.outfit(color: Colors.white24),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "DOMAIN CLUSTER",
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.neonCyan.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.neonCyan : Colors.white10),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.outfit(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("ABORT", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectOnboardingScreen(
                            projectTitle: titleController.text,
                            category: selectedCategory,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("INITIALIZE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
