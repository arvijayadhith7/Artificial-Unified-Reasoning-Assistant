import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/workspace_service.dart';

class ProjectOnboardingScreen extends ConsumerStatefulWidget {
  final String projectTitle;
  final String category;

  const ProjectOnboardingScreen({
    super.key,
    required this.projectTitle,
    required this.category,
  });

  @override
  ConsumerState<ProjectOnboardingScreen> createState() => _ProjectOnboardingScreenState();
}

class _ProjectOnboardingScreenState extends ConsumerState<ProjectOnboardingScreen> {
  int _currentIndex = 0;
  final List<dynamic> _questions = [];
  final Map<int, String> _answers = {};
  bool _isLoading = true;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await ref.read(workspaceProvider.notifier).getOnboardingQuestions(
        widget.projectTitle,
        widget.category,
      );
      setState(() {
        _questions.addAll(questions);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading intelligence modules: $e")),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      final List<String> answerList = [];
      for (int i = 0; i < _questions.length; i++) {
        answerList.add("${_questions[i]['question']}: ${_answers[i]}");
      }

      final blueprint = await ref.read(workspaceProvider.notifier).analyzeProject(
        widget.projectTitle,
        answerList,
      );
      
      // Create the final workspace
      await ref.read(workspaceProvider.notifier).createProject(
        widget.projectTitle,
        "AI Generated Workspace for ${widget.projectTitle}",
        blueprint: blueprint,
        tag: widget.category.toUpperCase(),
      );

      if (mounted) {
        Navigator.pop(context); // Close onboarding
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Workspace OS Generated Successfully!")),
        );
      }
    } catch (e) {
       if (mounted) {
         setState(() => _isAnalyzing = false);
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Analysis Disrupted: $e")),
        );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.neonCyan),
              const SizedBox(height: 24),
              Text("Calibrating Project Architect...", 
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_isAnalyzing) {
       return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.neonCyan, size: 64),
              const SizedBox(height: 24),
              Text("Analyzing Project Clusters...", 
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Generating MVP Roadmap & Architecture...", 
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
       return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text("No questions generated. Try again.", style: GoogleFonts.outfit(color: Colors.white54)),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              AppColors.neonCyan.withOpacity(0.05),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(progress),
                const SizedBox(height: 60),
                _buildQuestion(currentQuestion),
                const Spacer(),
                _buildNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded, color: Colors.white54),
            ),
            Text("Step ${_currentIndex + 1} of ${_questions.length}", 
              style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.neonCyan,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: AppColors.neonCyan.withOpacity(0.5), blurRadius: 8)
                ]
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.projectTitle.toUpperCase(), 
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(question['question'] ?? "Architecting Question...", 
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 40),
        ... (question['options'] as List? ?? []).map((opt) {
          final isSelected = _answers[_currentIndex] == opt;
          return GestureDetector(
            onTap: () => setState(() => _answers[_currentIndex] = opt.toString()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonCyan.withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.neonCyan : AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(opt.toString(), style: GoogleFonts.outfit(color: isSelected ? Colors.white : Colors.white70, fontSize: 15)),
                  ),
                  if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.neonCyan, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNavigation() {
    final isLast = _currentIndex == _questions.length - 1;
    final canGoNext = _answers.containsKey(_currentIndex);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentIndex > 0)
          TextButton(
            onPressed: () => setState(() => _currentIndex--),
            child: Text("Back", style: GoogleFonts.outfit(color: Colors.white54)),
          )
        else
          const SizedBox(),
        
        ElevatedButton(
          onPressed: canGoNext ? (isLast ? _submitAnalysis : () => setState(() => _currentIndex++)) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: Colors.white10,
          ),
          child: Text(isLast ? "Launch Workspace" : "Continue", 
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
