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
  int _step = 1; // 1: Experience Level, 2: Project Details Form, 3: Adaptive Questions
  String? _selectedExperience;
  
  // Project Details Controllers
  late final Map<String, TextEditingController> _detailsControllers;
  final _formKey = GlobalKey<FormState>();

  // Question State
  List<dynamic> _generatedQuestions = [];
  int _questionIndex = 0;
  final Map<int, String> _questionAnswers = {};
  final TextEditingController _customQuestionAnswerController = TextEditingController();
  
  bool _showAdvancedSpecs = false;
  
  bool _isLoadingQuestions = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _detailsControllers = {
      'name': TextEditingController(text: widget.projectTitle),
      'topic': TextEditingController(text: widget.category),
      'description': TextEditingController(),
      'goal': TextEditingController(),
      'target_users': TextEditingController(),
      'platform': TextEditingController(text: 'Web'),
      'tech_stack': TextEditingController(),
      'team_size': TextEditingController(text: '1'),
      'timeline': TextEditingController(),
      'main_features': TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (var controller in _detailsControllers.values) {
      controller.dispose();
    }
    _customQuestionAnswerController.dispose();
    super.dispose();
  }

  void _onExperienceSelected(String level) {
    setState(() {
      _selectedExperience = level;
      _step = 2;
      if (level == 'Beginner') {
        _detailsControllers['goal']!.text = "Create and explore a basic version of this idea.";
        _detailsControllers['target_users']!.text = "Early users and general audience.";
        _detailsControllers['platform']!.text = "Web";
        _detailsControllers['tech_stack']!.text = "Simple frontend website (HTML/JS/CSS) or lightweight app.";
        _detailsControllers['team_size']!.text = "1";
        _detailsControllers['timeline']!.text = "1-2 weeks";
        _detailsControllers['main_features']!.text = "Interactive interface, simple data persistence, and clean navigation.";
      } else {
        _detailsControllers['goal']!.text = "";
        _detailsControllers['target_users']!.text = "";
        _detailsControllers['platform']!.text = "Web";
        _detailsControllers['tech_stack']!.text = "";
        _detailsControllers['team_size']!.text = "1";
        _detailsControllers['timeline']!.text = "";
        _detailsControllers['main_features']!.text = "";
      }
    });
  }

  Future<void> _fetchAdaptiveQuestions() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoadingQuestions = true);
    
    final details = {
      'topic': _detailsControllers['topic']!.text.trim(),
      'description': _detailsControllers['description']!.text.trim(),
      'goal': _detailsControllers['goal']!.text.trim(),
      'target_users': _detailsControllers['target_users']!.text.trim(),
      'platform': _detailsControllers['platform']!.text.trim(),
      'tech_stack': _detailsControllers['tech_stack']!.text.trim(),
      'team_size': _detailsControllers['team_size']!.text.trim(),
      'timeline': _detailsControllers['timeline']!.text.trim(),
      'main_features': _detailsControllers['main_features']!.text.trim(),
    };

    try {
      final questions = await ref.read(workspaceProvider.notifier).getOnboardingQuestions(
        _detailsControllers['name']!.text.trim(),
        _selectedExperience!,
        details,
      );

      setState(() {
        _generatedQuestions = questions;
        _isLoadingQuestions = false;
        if (_generatedQuestions.isNotEmpty) {
          _step = 3;
          _questionIndex = 0;
          _questionAnswers.clear();
          _customQuestionAnswerController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to generate adaptive questions. Please try again."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    } catch (e) {
      setState(() => _isLoadingQuestions = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _submitAnalysis() async {
    setState(() => _isAnalyzing = true);
    try {
      final details = {
        'topic': _detailsControllers['topic']!.text.trim(),
        'description': _detailsControllers['description']!.text.trim(),
        'goal': _detailsControllers['goal']!.text.trim(),
        'target_users': _detailsControllers['target_users']!.text.trim(),
        'platform': _detailsControllers['platform']!.text.trim(),
        'tech_stack': _detailsControllers['tech_stack']!.text.trim(),
        'team_size': _detailsControllers['team_size']!.text.trim(),
        'timeline': _detailsControllers['timeline']!.text.trim(),
        'main_features': _detailsControllers['main_features']!.text.trim(),
      };

      final List<String> answerList = [];
      for (int i = 0; i < _generatedQuestions.length; i++) {
        final q = _generatedQuestions[i];
        final ans = _questionAnswers[i] ?? "N/A";
        answerList.add("Question: ${q['question']}\nAnswer: $ans");
      }

      final blueprint = await ref.read(workspaceProvider.notifier).analyzeProject(
        title: _detailsControllers['name']!.text.trim(),
        answers: answerList,
        experienceLevel: _selectedExperience!,
        projectDetails: details,
      );
      
      await ref.read(workspaceProvider.notifier).createProject(
        _detailsControllers['name']!.text.trim(),
        _detailsControllers['description']!.text.trim(),
        blueprint: blueprint,
        tag: _detailsControllers['platform']!.text.trim().toUpperCase(),
      );

      if (mounted) {
        Navigator.pop(context); // Close onboarding
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Project '${_detailsControllers['name']!.text}' initialized successfully!"),
            backgroundColor: AppColors.electricBlue,
          ),
        );
      }
    } catch (e) {
       if (mounted) {
         setState(() => _isAnalyzing = false);
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Analysis failed: $e"), backgroundColor: Colors.redAccent),
        );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.neonCyan, size: 70),
              const SizedBox(height: 32),
              Text(
                "COMPILING NEURAL ARCHITECTURES", 
                style: GoogleFonts.outfit(
                  color: Colors.white, 
                  fontSize: 16, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                )
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 250,
                child: LinearProgressIndicator(
                  color: AppColors.neonCyan,
                  backgroundColor: AppColors.neonCyan.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Analyzing domains and compiling technical roadmap...", 
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingQuestions) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology_rounded, color: AppColors.neonCyan, size: 70),
              const SizedBox(height: 32),
              Text(
                "SYNTHESIZING QUESTIONS", 
                style: GoogleFonts.outfit(
                  color: Colors.white, 
                  fontSize: 16, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                )
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 250,
                child: LinearProgressIndicator(
                  color: AppColors.neonCyan,
                  backgroundColor: AppColors.neonCyan.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Adapting difficulty schema to $_selectedExperience Mode...", 
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              AppColors.neonCyan.withOpacity(0.03),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildCurrentStepBody(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    double progress = 0.0;
    String stepLabel = "EXPERIENCE LEVEL";
    if (_step == 1) {
      progress = 0.33;
      stepLabel = "EXPERIENCE LEVEL";
    } else if (_step == 2) {
      progress = 0.66;
      stepLabel = "PROJECT DETAILS";
    } else if (_step == 3) {
      final totalQ = _generatedQuestions.isNotEmpty ? _generatedQuestions.length : 1;
      progress = 0.66 + (0.34 * (_questionIndex + 1) / totalQ);
      stepLabel = "ADAPTIVE QUESTIONS (${_questionIndex + 1}/$totalQ)";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded, color: Colors.white54, size: 24),
            ),
            Text(
              stepLabel, 
              style: GoogleFonts.outfit(
                color: AppColors.neonCyan, 
                fontSize: 11, 
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              )
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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

  Widget _buildCurrentStepBody() {
    if (_step == 1) {
      return _buildExperienceSelector();
    } else if (_step == 2) {
      return _buildProjectDetailsForm();
    } else {
      return _buildAdaptiveQuestionsBody();
    }
  }

  Widget _buildExperienceSelector() {
    final experiences = [
      {
        'level': 'Beginner',
        'title': 'Beginner / Creator',
        'icon': Icons.lightbulb_outline_rounded,
        'desc': 'I want to explore an idea. Jargon-free language with simple learning assistance.',
      },
      {
        'level': 'Intermediate',
        'title': 'Intermediate / Builder',
        'icon': Icons.handyman_outlined,
        'desc': 'I understand basic web/app architectures. Create full-stack and API MVPs.',
      },
      {
        'level': 'Advanced',
        'title': 'Advanced / Architect',
        'icon': Icons.architecture_rounded,
        'desc': 'I am a software engineer. Scale microservices, complex vector pipelines, or deep RAG.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MISSION PLANNER", 
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w900)
        ),
        const SizedBox(height: 8),
        Text(
          "What is your experience level?", 
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)
        ),
        const SizedBox(height: 10),
        Text(
          "AURA adapts development strategies, explanations, and system blueprints to match your expertise.", 
          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13, height: 1.4)
        ),
        const SizedBox(height: 32),
        ...experiences.map((exp) {
          final isSelected = _selectedExperience == exp['level'];
          return GestureDetector(
            onTap: () => _onExperienceSelected(exp['level'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonCyan.withOpacity(0.08) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.neonCyan : Colors.white.withOpacity(0.05),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.neonCyan.withOpacity(0.15), blurRadius: 20)]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.neonCyan.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(exp['icon'] as IconData, color: isSelected ? AppColors.neonCyan : Colors.white38, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp['title'] as String,
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exp['desc'] as String,
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildProjectDetailsForm() {
    final isBeginner = _selectedExperience == 'Beginner';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "EXPERIENCE: ${_selectedExperience?.toUpperCase()}", 
            style: GoogleFonts.outfit(color: AppColors.neonCyan.withOpacity(0.7), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w900)
          ),
          const SizedBox(height: 8),
          Text(
            isBeginner ? "Describe your Idea" : "Project Specifications", 
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)
          ),
          const SizedBox(height: 8),
          Text(
            isBeginner 
                ? "Enter your project title and describe your vision below." 
                : "Provide basic info to initialize the adaptive architect.", 
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)
          ),
          const SizedBox(height: 24),
          _buildFormField('name', 'Project Name', 'Enter your project title', true),
          _buildFormField('topic', 'Project Topic / Keyword', 'e.g. Finance Tracker, Travel Agent, Social Network', true),
          _buildFormField('description', 'Short Description', 'Summarize what your project does', true, maxLines: 3),
          
          if (!isBeginner) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showAdvancedSpecs = !_showAdvancedSpecs),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.neonCyan, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          "Advanced Specifications (Optional)",
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Icon(
                      _showAdvancedSpecs ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_showAdvancedSpecs) ...[
              _buildFormField('goal', 'Project Goal', 'What is the main objective of this build?', false),
              _buildFormField('target_users', 'Target Users', 'Who are the primary end users?', false),
              _buildPlatformSelector(),
              _buildFormField('tech_stack', 'Preferred Tech Stack', 'e.g. Flutter/FastAPI, Next.js/Supabase', false),
              _buildFormField('team_size', 'Team Size', 'Number of developers (e.g. 1, 3, 5)', false, keyboardType: TextInputType.number),
              _buildFormField('timeline', 'Timeline / Duration', 'e.g. 2 weeks, 1 month', false),
              _buildFormField('main_features', 'Main Features (Comma Separated)', 'e.g. Authentication, Chat dashboard', false, maxLines: 2),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformSelector() {
    final platforms = ['Web', 'Mobile', 'Desktop', 'AI Assistant', 'SaaS'];
    final currentVal = _detailsControllers['platform']!.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Platform Type",
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: platforms.map((p) {
              final isSel = currentVal == p;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _detailsControllers['platform']!.text = p;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.neonCyan.withOpacity(0.1) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? AppColors.neonCyan : Colors.white.withOpacity(0.05),
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    p,
                    style: GoogleFonts.outfit(
                      color: isSel ? Colors.white : Colors.white60,
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String key, String label, String hint, bool required, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextFormField(
              controller: _detailsControllers[key],
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              maxLines: maxLines,
              keyboardType: keyboardType,
              validator: required ? (val) {
                if (val == null || val.trim().isEmpty) {
                  return "This field is required";
                }
                return null;
              } : null,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveQuestionsBody() {
    if (_generatedQuestions.isEmpty) return const SizedBox();
    
    final currentQ = _generatedQuestions[_questionIndex];
    final options = (currentQ['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final selectedAns = _questionAnswers[_questionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AI ADAPTIVE ANALYSIS", 
          style: GoogleFonts.outfit(color: AppColors.neonCyan.withOpacity(0.6), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w900)
        ),
        const SizedBox(height: 8),
        Text(
          currentQ['question'] as String, 
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.3)
        ),
        const SizedBox(height: 24),
        
        // Options List
        if (options.isNotEmpty) ...[
          ...options.map((opt) {
            final isSelected = selectedAns == opt;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _questionAnswers[_questionIndex] = opt;
                  _customQuestionAnswerController.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neonCyan.withOpacity(0.08) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.neonCyan : Colors.white.withOpacity(0.05),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt, 
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : Colors.white70, 
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        )
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.neonCyan, size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
        ],

        const SizedBox(height: 12),
        // Write-in answer field
        Text(
          "Custom Response",
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _customQuestionAnswerController.text.isNotEmpty ? AppColors.neonCyan : Colors.white.withOpacity(0.05)
            ),
          ),
          child: TextField(
            controller: _customQuestionAnswerController,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
            onChanged: (val) {
              setState(() {
                if (val.isNotEmpty) {
                  _questionAnswers[_questionIndex] = val;
                } else {
                  _questionAnswers.remove(_questionIndex);
                }
              });
            },
            decoration: InputDecoration(
              hintText: "Or specify your own answer here...",
              hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.white30, size: 22),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    if (_step == 1) return const SizedBox();

    final isLastQ = _step == 3 && _questionIndex == _generatedQuestions.length - 1;
    final canGoNext = _step == 2 
        ? true // Checked by form validator
        : _questionAnswers.containsKey(_questionIndex);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              if (_step == 2) {
                _step = 1;
              } else if (_step == 3) {
                if (_questionIndex > 0) {
                  _questionIndex--;
                  _customQuestionAnswerController.clear();
                  final savedAns = _questionAnswers[_questionIndex];
                  if (savedAns != null && !((_generatedQuestions[_questionIndex]['options'] as List<dynamic>?)?.contains(savedAns) ?? false)) {
                    _customQuestionAnswerController.text = savedAns;
                  }
                } else {
                  _step = 2;
                }
              }
            });
          },
          child: Text(
            "BACK", 
            style: GoogleFonts.outfit(
              color: Colors.white38, 
              fontSize: 11, 
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            )
          ),
        ),
        ElevatedButton(
          onPressed: canGoNext
              ? () {
                  if (_step == 2) {
                    _fetchAdaptiveQuestions();
                  } else if (_step == 3) {
                    if (isLastQ) {
                      _submitAnalysis();
                    } else {
                      setState(() {
                        _questionIndex++;
                        _customQuestionAnswerController.clear();
                        final savedAns = _questionAnswers[_questionIndex];
                        if (savedAns != null && !((_generatedQuestions[_questionIndex]['options'] as List<dynamic>?)?.contains(savedAns) ?? false)) {
                          _customQuestionAnswerController.text = savedAns;
                        }
                      });
                    }
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: Colors.white10,
          ),
          child: Text(
            isLastQ ? "COMPILE BLUEPRINT" : "CONTINUE", 
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)
          ),
        ),
      ],
    );
  }
}

// Custom Animated Fractional Size Widget to support beautiful bar animation in Flutter
class AnimatedFractionallySizedBox extends StatefulWidget {
  final double widthFactor;
  final Widget child;
  final Alignment alignment;
  final Duration duration;
  final Curve curve;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
    this.alignment = Alignment.centerLeft,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedFractionallySizedBox> createState() => _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState extends State<AnimatedFractionallySizedBox> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.widthFactor),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, factor, child) {
        return FractionallySizedBox(
          alignment: widget.alignment,
          widthFactor: factor,
          child: widget.child,
        );
      },
    );
  }
}
