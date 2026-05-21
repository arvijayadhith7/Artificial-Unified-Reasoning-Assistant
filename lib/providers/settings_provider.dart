import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/overlay_service.dart';


class AuraSettings {
  final String themeMode;
  final String accentColor;
  final double fontScale;
  final bool animationsEnabled;
  final String layoutDensity;
  final String activeModel;
  final String responseStyle;
  final bool conciseMode;
  final String searchStrategy;
  final bool streamingEnabled;
  final String memoryBehavior;
  final bool overlayEnabled;
  final bool floatingAssistantEnabled;
  final bool backgroundServiceEnabled;
  final bool pushNotificationsEnabled;
  final bool neuralBriefingEnabled;
  final bool realtimeAlertsEnabled;
  final String autoSaveFrequency;
  final bool biometricLockEnabled;
  final bool dataSharingEnabled;
  final int contextWindowLimit;
  final bool tavilyEnabled;
  final String searchFallbackStrategy;
  final String profileUsername;
  final String profileEmail;
  final String profileImage;
  final bool isGoogleLinked;
  final List<String> activeSessions;

  AuraSettings({
    this.themeMode = 'DARK',
    this.accentColor = 'cyan',
    this.fontScale = 1.0,
    this.animationsEnabled = true,
    this.layoutDensity = 'COZY',
    this.activeModel = 'AURA Ultra',
    this.responseStyle = 'warm-narrative',
    this.conciseMode = false,
    this.searchStrategy = 'multi-tier',
    this.streamingEnabled = true,
    this.memoryBehavior = 'project-isolated',
    this.overlayEnabled = false,
    this.floatingAssistantEnabled = false,
    this.backgroundServiceEnabled = false,
    this.pushNotificationsEnabled = true,
    this.neuralBriefingEnabled = true,
    this.realtimeAlertsEnabled = false,
    this.autoSaveFrequency = '5m',
    this.biometricLockEnabled = false,
    this.dataSharingEnabled = true,
    this.contextWindowLimit = 8000,
    this.tavilyEnabled = true,
    this.searchFallbackStrategy = 'api-fallback',
    this.profileUsername = 'NEURAL GUEST',
    this.profileEmail = 'guest@aura.ai',
    this.profileImage = '',
    this.isGoogleLinked = false,
    this.activeSessions = const ['Android Device - Active Now', 'Web Portal - 2 hrs ago'],
  });

  AuraSettings copyWith({
    String? themeMode,
    String? accentColor,
    double? fontScale,
    bool? animationsEnabled,
    String? layoutDensity,
    String? activeModel,
    String? responseStyle,
    bool? conciseMode,
    String? searchStrategy,
    bool? streamingEnabled,
    String? memoryBehavior,
    bool? overlayEnabled,
    bool? floatingAssistantEnabled,
    bool? backgroundServiceEnabled,
    bool? pushNotificationsEnabled,
    bool? neuralBriefingEnabled,
    bool? realtimeAlertsEnabled,
    String? autoSaveFrequency,
    bool? biometricLockEnabled,
    bool? dataSharingEnabled,
    int? contextWindowLimit,
    bool? tavilyEnabled,
    String? searchFallbackStrategy,
    String? profileUsername,
    String? profileEmail,
    String? profileImage,
    bool? isGoogleLinked,
    List<String>? activeSessions,
  }) {
    return AuraSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      fontScale: fontScale ?? this.fontScale,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      layoutDensity: layoutDensity ?? this.layoutDensity,
      activeModel: activeModel ?? this.activeModel,
      responseStyle: responseStyle ?? this.responseStyle,
      conciseMode: conciseMode ?? this.conciseMode,
      searchStrategy: searchStrategy ?? this.searchStrategy,
      streamingEnabled: streamingEnabled ?? this.streamingEnabled,
      memoryBehavior: memoryBehavior ?? this.memoryBehavior,
      overlayEnabled: overlayEnabled ?? this.overlayEnabled,
      floatingAssistantEnabled: floatingAssistantEnabled ?? this.floatingAssistantEnabled,
      backgroundServiceEnabled: backgroundServiceEnabled ?? this.backgroundServiceEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      neuralBriefingEnabled: neuralBriefingEnabled ?? this.neuralBriefingEnabled,
      realtimeAlertsEnabled: realtimeAlertsEnabled ?? this.realtimeAlertsEnabled,
      autoSaveFrequency: autoSaveFrequency ?? this.autoSaveFrequency,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      dataSharingEnabled: dataSharingEnabled ?? this.dataSharingEnabled,
      contextWindowLimit: contextWindowLimit ?? this.contextWindowLimit,
      tavilyEnabled: tavilyEnabled ?? this.tavilyEnabled,
      searchFallbackStrategy: searchFallbackStrategy ?? this.searchFallbackStrategy,
      profileUsername: profileUsername ?? this.profileUsername,
      profileEmail: profileEmail ?? this.profileEmail,
      profileImage: profileImage ?? this.profileImage,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
      activeSessions: activeSessions ?? this.activeSessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'accentColor': accentColor,
      'fontScale': fontScale,
      'animationsEnabled': animationsEnabled,
      'layoutDensity': layoutDensity,
      'activeModel': activeModel,
      'responseStyle': responseStyle,
      'conciseMode': conciseMode,
      'searchStrategy': searchStrategy,
      'streamingEnabled': streamingEnabled,
      'memoryBehavior': memoryBehavior,
      'overlayEnabled': overlayEnabled,
      'floatingAssistantEnabled': floatingAssistantEnabled,
      'backgroundServiceEnabled': backgroundServiceEnabled,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'neuralBriefingEnabled': neuralBriefingEnabled,
      'realtimeAlertsEnabled': realtimeAlertsEnabled,
      'autoSaveFrequency': autoSaveFrequency,
      'biometricLockEnabled': biometricLockEnabled,
      'dataSharingEnabled': dataSharingEnabled,
      'contextWindowLimit': contextWindowLimit,
      'tavilyEnabled': tavilyEnabled,
      'searchFallbackStrategy': searchFallbackStrategy,
      'profileUsername': profileUsername,
      'profileEmail': profileEmail,
      'profileImage': profileImage,
      'isGoogleLinked': isGoogleLinked,
      'activeSessions': activeSessions,
    };
  }

  factory AuraSettings.fromJson(Map<String, dynamic> json) {
    return AuraSettings(
      themeMode: json['themeMode'] ?? 'DARK',
      accentColor: json['accentColor'] ?? 'cyan',
      fontScale: (json['fontScale'] ?? 1.0).toDouble(),
      animationsEnabled: json['animationsEnabled'] ?? true,
      layoutDensity: json['layoutDensity'] ?? 'COZY',
      activeModel: json['activeModel'] ?? 'AURA Ultra',
      responseStyle: json['responseStyle'] ?? 'warm-narrative',
      conciseMode: json['conciseMode'] ?? false,
      searchStrategy: json['searchStrategy'] ?? 'multi-tier',
      streamingEnabled: json['streamingEnabled'] ?? true,
      memoryBehavior: json['memoryBehavior'] ?? 'project-isolated',
      overlayEnabled: json['overlayEnabled'] ?? false,
      floatingAssistantEnabled: json['floatingAssistantEnabled'] ?? false,
      backgroundServiceEnabled: json['backgroundServiceEnabled'] ?? false,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
      neuralBriefingEnabled: json['neuralBriefingEnabled'] ?? true,
      realtimeAlertsEnabled: json['realtimeAlertsEnabled'] ?? false,
      autoSaveFrequency: json['autoSaveFrequency'] ?? '5m',
      biometricLockEnabled: json['biometricLockEnabled'] ?? false,
      dataSharingEnabled: json['dataSharingEnabled'] ?? true,
      contextWindowLimit: json['contextWindowLimit'] ?? 8000,
      tavilyEnabled: json['tavilyEnabled'] ?? true,
      searchFallbackStrategy: json['searchFallbackStrategy'] ?? 'api-fallback',
      profileUsername: json['profileUsername'] ?? 'NEURAL GUEST',
      profileEmail: json['profileEmail'] ?? 'guest@aura.ai',
      profileImage: json['profileImage'] ?? '',
      isGoogleLinked: json['isGoogleLinked'] ?? false,
      activeSessions: json['activeSessions'] != null 
          ? List<String>.from(json['activeSessions']) 
          : const ['Android Device - Active Now', 'Web Portal - 2 hrs ago'],
    );
  }
}

class SettingsNotifier extends StateNotifier<AuraSettings> {
  SettingsNotifier() : super(AuraSettings()) {
    _loadLocalSettings();
  }

  static const String _settingsKey = 'aura_cached_settings';
  static String get baseUrl => AppConfig.baseUrl;

  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(_settingsKey);
      if (localJson != null) {
        state = AuraSettings.fromJson(jsonDecode(localJson));
      }
      
      // Defer overlay auto-start until UI is up — avoids killing the app on cold launch
      if (state.overlayEnabled) {
        await OverlayService.syncOverlayEnabledPref(true);
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            await OverlayService.startOverlay();
          } catch (e) {
            debugPrint("Overlay auto-start failed: $e");
          }
        });
      } else {
        await OverlayService.syncOverlayEnabledPref(false);
      }
      
      // Attempt backend sync load in background
      _fetchBackendSettings();
    } catch (e) {
      debugPrint("Error loading local settings: $e");
    }
  }


  Future<void> _fetchBackendSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/settings'));
      if (response.statusCode == 200) {
        final backendData = jsonDecode(response.body);
        final backendSettings = AuraSettings.fromJson(backendData);
        state = backendSettings;
        await _saveLocalSettings(backendSettings);
      }
    } catch (e) {
      debugPrint("Backend fetch failed, using local settings: $e");
    }
  }

  Future<void> _saveLocalSettings(AuraSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    await OverlayService.syncOverlayEnabledPref(settings.overlayEnabled);
  }

  Future<bool> updateSetting(String key, dynamic value) async {
    AuraSettings updated;
    switch (key) {
      case 'themeMode':
        updated = state.copyWith(themeMode: value as String);
        break;
      case 'accentColor':
        updated = state.copyWith(accentColor: value as String);
        break;
      case 'fontScale':
        updated = state.copyWith(fontScale: value as double);
        break;
      case 'animationsEnabled':
        updated = state.copyWith(animationsEnabled: value as bool);
        break;
      case 'layoutDensity':
        updated = state.copyWith(layoutDensity: value as String);
        break;
      case 'activeModel':
        updated = state.copyWith(activeModel: value as String);
        break;
      case 'responseStyle':
        updated = state.copyWith(responseStyle: value as String);
        break;
      case 'conciseMode':
        updated = state.copyWith(conciseMode: value as bool);
        break;
      case 'searchStrategy':
        updated = state.copyWith(searchStrategy: value as String);
        break;
      case 'streamingEnabled':
        updated = state.copyWith(streamingEnabled: value as bool);
        break;
      case 'memoryBehavior':
        updated = state.copyWith(memoryBehavior: value as String);
        break;
      case 'overlayEnabled':
        updated = state.copyWith(overlayEnabled: value as bool);
        break;
      case 'floatingAssistantEnabled':
        updated = state.copyWith(floatingAssistantEnabled: value as bool);
        break;
      case 'backgroundServiceEnabled':
        updated = state.copyWith(backgroundServiceEnabled: value as bool);
        break;
      case 'pushNotificationsEnabled':
        updated = state.copyWith(pushNotificationsEnabled: value as bool);
        break;
      case 'neuralBriefingEnabled':
        updated = state.copyWith(neuralBriefingEnabled: value as bool);
        break;
      case 'realtimeAlertsEnabled':
        updated = state.copyWith(realtimeAlertsEnabled: value as bool);
        break;
      case 'autoSaveFrequency':
        updated = state.copyWith(autoSaveFrequency: value as String);
        break;
      case 'biometricLockEnabled':
        updated = state.copyWith(biometricLockEnabled: value as bool);
        break;
      case 'dataSharingEnabled':
        updated = state.copyWith(dataSharingEnabled: value as bool);
        break;
      case 'contextWindowLimit':
        updated = state.copyWith(contextWindowLimit: value as int);
        break;
      case 'tavilyEnabled':
        updated = state.copyWith(tavilyEnabled: value as bool);
        break;
      case 'searchFallbackStrategy':
        updated = state.copyWith(searchFallbackStrategy: value as String);
        break;
      case 'profileUsername':
        updated = state.copyWith(profileUsername: value as String);
        break;
      case 'profileEmail':
        updated = state.copyWith(profileEmail: value as String);
        break;
      case 'profileImage':
        updated = state.copyWith(profileImage: value as String);
        break;
      case 'isGoogleLinked':
        updated = state.copyWith(isGoogleLinked: value as bool);
        break;
      case 'activeSessions':
        updated = state.copyWith(activeSessions: List<String>.from(value));
        break;
      default:
        return false;
    }

    // Instantly update local state and SharedPreferences
    state = updated;
    await _saveLocalSettings(updated);

    // Sync to backend with auto-retry
    return _syncWithBackend(updated);
  }

  Future<bool> _syncWithBackend(AuraSettings settings, {int retries = 3}) async {
    int attempts = 0;
    while (attempts < retries) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/settings'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(settings.toJson()),
        );
        if (response.statusCode == 200) {
          debugPrint("Backend Settings Sync Successful.");
          return true;
        }
      } catch (e) {
        debugPrint("Settings Sync Attempt ${attempts + 1} Failed: $e");
      }
      attempts++;
      if (attempts < retries) {
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
      }
    }
    return false; // Failed sync after all retries
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Password change network failure: $e");
      return false;
    }
  }

  Future<bool> terminateSession(String sessionName) async {
    try {
      final updatedSessions = state.activeSessions.where((s) => s != sessionName).toList();
      state = state.copyWith(activeSessions: updatedSessions);
      await _saveLocalSettings(state);

      final response = await http.post(
        Uri.parse('$baseUrl/auth/sessions/terminate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session': sessionName}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> wipeNeuralMemory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/neural/reset'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AuraSettings>((ref) {
  return SettingsNotifier();
});
