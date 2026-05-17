import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class Project {
  final String id;
  final String title;
  final String description;
  final String tag;
  final double progress;
  final String status;
  final String lastActive;
  final Map<String, dynamic> blueprint;
  final String? priority;
  final String? aiSummary;
  final List<String>? suggestions;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.tag,
    required this.progress,
    required this.status,
    required this.lastActive,
    this.blueprint = const {},
    this.priority,
    this.aiSummary,
    this.suggestions,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tag: json['tag'] ?? 'AI PROJECT',
      progress: (json['progress'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      lastActive: json['last_active'] ?? '',
      blueprint: json['blueprint'] ?? {},
      priority: json['priority'],
      aiSummary: json['ai_summary'],
      suggestions: json['suggestions'] != null ? List<String>.from(json['suggestions']) : null,
    );
  }
}

class WorkspaceState {
  final List<Project> projects;
  final bool isLoading;
  final String suggestion;

  WorkspaceState({
    this.projects = const [],
    this.isLoading = false,
    this.suggestion = '',
  });

  WorkspaceState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? suggestion,
  }) {
    return WorkspaceState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      suggestion: suggestion ?? this.suggestion,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier() : super(WorkspaceState()) {
    fetchProjects();
  }

  static const String baseUrl = 'https://vijayadhith7-aura-backend.hf.space';

  Future<void> fetchProjects() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/workspaces'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        state = state.copyWith(
          projects: data.map((json) => Project.fromJson(json)).toList(),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<List<dynamic>> getOnboardingQuestions(String title, String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workspaces/onboarding?title=$title&category=$category')
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['questions'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> analyzeProject(String title, List<String> answers) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/workspaces/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'answers': answers}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> createProject(String title, String description, {Map<String, dynamic>? blueprint, String tag = "AI PROJECT"}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/workspaces'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title, 
          'description': description,
          'blueprint': blueprint,
          'tag': tag
        }),
      );
      if (response.statusCode == 200) {
        await fetchProjects();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/workspaces/$projectId'));
      if (response.statusCode == 200) {
        await fetchProjects();
      }
    } catch (e) {}
  }

  Future<void> getSuggestion(String projectId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/workspaces/$projectId/suggest'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = state.copyWith(suggestion: data['suggestion']);
      }
    } catch (e) {}
  }
}

final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier();
});
