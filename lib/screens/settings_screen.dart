import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../providers/settings_provider.dart';
import 'login_screen.dart';
import '../services/overlay_service.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _pingTime = -1;
  bool _isCheckingPing = false;
  bool _isWipingMemory = false;

  @override
  void initState() {
    super.initState();
    _checkNeuralCorePing();
  }

  Future<void> _checkNeuralCorePing() async {
    if (mounted) setState(() => _isCheckingPing = true);
    final stopwatch = Stopwatch()..start();
    try {
      final url = '${SettingsNotifier.baseUrl}/';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _pingTime = response.statusCode == 200 ? stopwatch.elapsedMilliseconds : -1;
          _isCheckingPing = false;
        });
      }
    } catch (e) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _pingTime = -1;
          _isCheckingPing = false;
        });
      }
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? Colors.redAccent : AppTheme.getAccentColor(ref.read(settingsProvider).accentColor),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F0F0F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isError ? Colors.redAccent.withOpacity(0.3) : Colors.white10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateSettingField(String key, dynamic value, String successMsg) async {
    final success = await ref.read(settingsProvider.notifier).updateSetting(key, value);
    if (success) {
      _showNotification(successMsg);
    } else {
      _showNotification("Sync offset. Settings preserved locally.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == 'DARK';
    final accent = AppTheme.getAccentColor(settings.accentColor);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () {
            // Check if we can pop, else just ignore since it's inside IndexedStack main view
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: Text(
          "SYSTEM CONTROL",
          style: GoogleFonts.outfit(
            fontSize: 13,
            letterSpacing: 6,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white54 : Colors.black54),
            onPressed: _checkNeuralCorePing,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(settings, isDark, accent),
            const SizedBox(height: 28),

            _buildSectionTitle("NEURAL ENGINE (AI)", isDark),
            _buildSettingsGroup(isDark, [
              _buildSettingsTile(
                icon: Icons.psychology_outlined,
                title: "Inference Model",
                subtitle: settings.activeModel,
                accentColor: accent,
                isDark: isDark,
                onTap: () => _showModelPicker(settings, accent, isDark),
                showArrow: true,
              ),
              _buildSettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: "Response Persona Style",
                subtitle: _formatPersonaName(settings.responseStyle),
                accentColor: accent,
                isDark: isDark,
                onTap: () => _showPersonaPicker(settings, accent, isDark),
                showArrow: true,
              ),
              _buildSettingsTile(
                icon: Icons.compress_rounded,
                title: "Concise Mode",
                subtitle: "Direct and compact answers",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.conciseMode, (val) {
                  _updateSettingField('conciseMode', val, "Concise mode ${val ? 'activated' : 'deactivated'}.");
                }, accent),
              ),
              _buildSettingsTile(
                icon: Icons.travel_explore_rounded,
                title: "Realtime Intelligence Strategy",
                subtitle: _formatSearchStrategy(settings.searchStrategy),
                accentColor: accent,
                isDark: isDark,
                onTap: () => _showSearchStrategyPicker(settings, accent, isDark),
                showArrow: true,
              ),
              _buildSettingsTile(
                icon: Icons.insights_outlined,
                title: "Realtime Streaming",
                subtitle: "Stream output text letter by letter",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.streamingEnabled, (val) {
                  _updateSettingField('streamingEnabled', val, "Streaming ${val ? 'enabled' : 'disabled'}.");
                }, accent),
              ),
              _buildSettingsTile(
                icon: Icons.sd_card_outlined,
                title: "Memory Isolation Level",
                subtitle: _formatMemoryBehavior(settings.memoryBehavior),
                accentColor: accent,
                isDark: isDark,
                onTap: () => _showMemoryBehaviorPicker(settings, accent, isDark),
                showArrow: true,
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("VISUAL DESIGN & COSMETICS", isDark),
            _buildSettingsGroup(isDark, [
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                title: "Interface Mode",
                subtitle: "Light vs dark background styles",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSegmentedThemeControl(settings, accent, isDark),
              ),
              _buildSettingsTile(
                icon: Icons.palette_outlined,
                title: "Core Accent Color",
                subtitle: "System-wide fluorescent theme color",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildAccentColorPicker(settings, isDark),
              ),
              _buildSettingsTile(
                icon: Icons.format_size_rounded,
                title: "Text Scaling",
                subtitle: "Font scale multiplier: ${settings.fontScale.toStringAsFixed(1)}x",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildFontScaleSlider(settings, accent),
              ),
              _buildSettingsTile(
                icon: Icons.auto_awesome_motion_outlined,
                title: "Dynamic Micro-Animations",
                subtitle: "Glow effects and transition curves",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.animationsEnabled, (val) {
                  _updateSettingField('animationsEnabled', val, "Animations ${val ? 'unlocked' : 'minimized'}.");
                }, accent),
              ),
              _buildSettingsTile(
                icon: Icons.grid_view_rounded,
                title: "Layout Spacing Density",
                subtitle: settings.layoutDensity,
                accentColor: accent,
                isDark: isDark,
                onTap: () => _showDensityPicker(settings, accent, isDark),
                showArrow: true,
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("INTELLIGENT OVERLAY ASSISTANT", isDark),
            _buildSettingsGroup(isDark, [
              _buildSettingsTile(
                icon: Icons.picture_in_picture_alt_rounded,
                title: "Overlay Assistant Screen View",
                subtitle: "Activate floating neural companion",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.overlayEnabled, (val) {
                  if (val) {
                    _simulateOverlayPermissionDialog(accent, isDark);
                  } else {
                    _updateSettingField('overlayEnabled', false, "Overlay assistant disabled.");
                    OverlayService.stopOverlay();
                  }
                }, accent),

              ),
              _buildSettingsTile(
                icon: Icons.touch_app_outlined,
                title: "Floating Orb Toggle Trigger",
                subtitle: "Tap dynamic halo to evoke sidebar",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.floatingAssistantEnabled, (val) {
                  _updateSettingField('floatingAssistantEnabled', val, "Floating orb trigger ${val ? 'active' : 'inactive'}.");
                }, accent),
              ),
              _buildSettingsTile(
                icon: Icons.settings_input_component_outlined,
                title: "Overlay Background Service",
                subtitle: "Run diagnostic accessibility listeners",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.backgroundServiceEnabled, (val) {
                  _updateSettingField('backgroundServiceEnabled', val, "Background listening daemon ${val ? 'online' : 'offline'}.");
                }, accent),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("NEURAL NOTIFICATIONS", isDark),
            _buildSettingsGroup(isDark, [
              _buildSettingsTile(
                icon: Icons.notifications_active_outlined,
                title: "Push Notifications",
                subtitle: "Instant project event alerts",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.pushNotificationsEnabled, (val) {
                  _updateSettingField('pushNotificationsEnabled', val, "Push notifications ${val ? 'active' : 'muted'}.");
                }, accent),
              ),
              _buildSettingsTile(
                icon: Icons.summarize_outlined,
                title: "Daily Neural Briefings",
                subtitle: "Summarized project & research milestones",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.neuralBriefingEnabled, (val) {
                  _updateSettingField('neuralBriefingEnabled', val, "Briefing digest ${val ? 'scheduled' : 'removed'}.");
                }, accent),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("WORKSPACE PARAMETERS", isDark),
            _buildSettingsGroup(isDark, [
              _buildSettingsTile(
                icon: Icons.save_outlined,
                title: "Workspace Auto-Save Rate",
                subtitle: settings.autoSaveFrequency == 'manual' ? 'Manual Sync only' : 'Save every ${settings.autoSaveFrequency}',
                accentColor: accent,
                isDark: isDark,
                onTap: () => _showAutoSavePicker(settings, accent, isDark),
                showArrow: true,
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("PRIVACY & SECURITY GATEWAY", isDark),
            _buildSettingsGroup(isDark, [
              _buildSettingsTile(
                icon: Icons.fingerprint_rounded,
                title: "Biometric OS Lock",
                subtitle: "Verify identity via biometric vault",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.biometricLockEnabled, (val) {
                  _updateSettingField('biometricLockEnabled', val, "Biometric security lock ${val ? 'activated' : 'deactivated'}.");
                }, accent),
              ),
              _buildSettingsTile(
                icon: Icons.security_rounded,
                title: "Change Account Access Key",
                subtitle: "Reset password with validation metrics",
                accentColor: accent,
                isDark: isDark,
                onTap: () => _showChangePasswordDialog(accent, isDark),
                showArrow: true,
              ),
              _buildSettingsTile(
                icon: Icons.share_location_outlined,
                title: "Model Optimization Data Ingestion",
                subtitle: "Share anonymous logs for model refinement",
                accentColor: accent,
                isDark: isDark,
                customTrailing: _buildSwitch(settings.dataSharingEnabled, (val) {
                  _updateSettingField('dataSharingEnabled', val, "Telemetry transmission ${val ? 'enabled' : 'isolated'}.");
                }, accent),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("LONG-TERM COGNITIVE MEMORY", isDark),
            _buildSettingsGroup(isDark, [
              _buildSettingsTile(
                icon: Icons.memory_rounded,
                title: "Memory Vault Reset",
                subtitle: "Permanently wipe vector DB & databases",
                isDark: isDark,
                accentColor: Colors.redAccent,
                titleColor: const Color(0xFFFFA07A),
                onTap: () => _showWipeMemoryWarningDialog(accent, isDark),
                showArrow: true,
              ),
            ]),
            const SizedBox(height: 36),

            _buildSignOutButton(accent, isDark),
            const SizedBox(height: 28),

            _buildDiagnosticPanel(settings, isDark, accent),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(AuraSettings settings, bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: accent.withOpacity(0.1),
                    backgroundImage: settings.profileImage.isNotEmpty ? NetworkImage(settings.profileImage) : null,
                    child: settings.profileImage.isEmpty
                        ? Text(
                            settings.profileUsername.isNotEmpty ? settings.profileUsername[0].toUpperCase() : 'G',
                            style: GoogleFonts.outfit(color: accent, fontSize: 32, fontWeight: FontWeight.w900),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditProfileModal(settings, accent, isDark),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 8)],
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.black, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.profileUsername,
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      settings.profileEmail,
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Tier: Intelligence Pro",
                        style: GoogleFonts.outfit(color: accent, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.verified_user_rounded, color: accent, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.link_rounded, color: settings.isGoogleLinked ? Colors.blue : Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Google Identity Link",
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white70 : Colors.black.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildSwitch(settings.isGoogleLinked, (val) {
                _updateSettingField('isGoogleLinked', val, val ? "Google Identity Linked." : "Google Link severed.");
              }, accent),
            ],
          ),
          if (settings.activeSessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "ACTIVE SESSIONS CLUSTER",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white24 : Colors.black.withOpacity(0.38),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...settings.activeSessions.map((session) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            session.contains('Device') ? Icons.phone_android_rounded : Icons.laptop_chromebook_rounded,
                            color: isDark ? Colors.white30 : Colors.black.withOpacity(0.3),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            session,
                            style: GoogleFonts.outfit(
                              color: isDark ? Colors.white54 : Colors.black.withOpacity(0.54),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (!session.contains('Active Now'))
                        GestureDetector(
                          onTap: () async {
                            final ok = await ref.read(settingsProvider.notifier).terminateSession(session);
                            if (ok) {
                              _showNotification("Session terminated.");
                            }
                          },
                          child: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                        ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(bool isDark, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(children: tiles),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isDark,
    Widget? customTrailing,
    Color? titleColor,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accentColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: titleColor ?? (isDark ? Colors.white : Colors.black),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(
          color: isDark ? Colors.white30 : Colors.black38,
          fontSize: 11,
        ),
      ),
      trailing: customTrailing ??
          (showArrow ? Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26) : null),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged, Color accent) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: accent,
      activeTrackColor: accent.withOpacity(0.2),
    );
  }

  Widget _buildSegmentedThemeControl(AuraSettings settings, Color accent, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ["DARK", "LIGHT"].map((opt) {
        final isSelected = settings.themeMode == opt;
        return GestureDetector(
          onTap: () => _updateSettingField('themeMode', opt, "Switched to $opt visual core."),
          child: Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? accent : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              opt,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black.withOpacity(0.7)),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccentColorPicker(AuraSettings settings, bool isDark) {
    final colors = ['cyan', 'blue', 'violet', 'orange', 'green'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((c) {
        final isSelected = settings.accentColor == c;
        final cVal = AppTheme.getAccentColor(c);
        return GestureDetector(
          onTap: () => _updateSettingField('accentColor', c, "Accent tone recalibrated."),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: cVal,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected ? [BoxShadow(color: cVal.withOpacity(0.6), blurRadius: 6)] : [],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontScaleSlider(AuraSettings settings, Color accent) {
    return SizedBox(
      width: 100,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        child: Slider(
          value: settings.fontScale,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          activeColor: accent,
          inactiveColor: Colors.grey.withOpacity(0.2),
          onChanged: (val) {
            ref.read(settingsProvider.notifier).updateSetting('fontScale', val);
          },
        ),
      ),
    );
  }

  Widget _buildSignOutButton(Color accent, bool isDark) {
    return InkWell(
      onTap: () async {
        await ref.read(settingsProvider.notifier).updateSetting('activeSessions', ['Android Device - Terminated']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          color: Colors.redAccent.withOpacity(0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
            const SizedBox(width: 12),
            Text(
              "TERMINATE SESSION",
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticPanel(AuraSettings settings, bool isDark, Color accent) {
    final statusColor = _pingTime != -1 ? accent : Colors.redAccent;
    final statusText = _pingTime != -1 ? "ONLINE (${_pingTime}ms)" : "OFFLINE / LOCAL GATEWAY";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NEURAL CORE STANDBY STATS",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              if (_isCheckingPing)
                const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey))
              else
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Diagnostic Core Link", style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black.withOpacity(0.7), fontSize: 12)),
              Text(statusText, style: GoogleFonts.outfit(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Active Engine Model", style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black.withOpacity(0.7), fontSize: 12)),
              Text(settings.activeModel, style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sync Protocol Frequency", style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black.withOpacity(0.7), fontSize: 12)),
              Text("Real-Time (Auto-Retry Enabled)", style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "AURA NEURAL OS V2.7.5 PROD",
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PICKERS & MODALS ---

  void _showModelPicker(AuraSettings settings, Color accent, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ["AURA Ultra", "AURA Flash", "AURA Reasoning"].map((m) {
          final isSelected = settings.activeModel == m;
          return ListTile(
            leading: Icon(Icons.psychology_outlined, color: isSelected ? accent : Colors.grey),
            title: Text(
              m,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected ? Icon(Icons.check_circle_outline_rounded, color: accent) : null,
            onTap: () {
              Navigator.pop(context);
              _updateSettingField('activeModel', m, "Inference calibrated to $m.");
            },
          );
        }).toList(),
      ),
    );
  }

  void _showPersonaPicker(AuraSettings settings, Color accent, bool isDark) {
    final personas = {
      'warm-narrative': 'Warm Strategic Co-Founder',
      'ultra-technical': 'Authoritative Technical Architect',
      'minimalist-hacker': 'Hyper-Optimized Minimalist Developer',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: personas.entries.map((e) {
          final isSelected = settings.responseStyle == e.key;
          return ListTile(
            leading: Icon(Icons.chat_bubble_outline_rounded, color: isSelected ? accent : Colors.grey),
            title: Text(
              e.value,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected ? Icon(Icons.check_circle_outline_rounded, color: accent) : null,
            onTap: () {
              Navigator.pop(context);
              _updateSettingField('responseStyle', e.key, "Persona style shifted to ${e.value}.");
            },
          );
        }).toList(),
      ),
    );
  }

  void _showSearchStrategyPicker(AuraSettings settings, Color accent, bool isDark) {
    final strategies = {
      'multi-tier': 'Multi-Tier Web & API Search (High-Fidelity)',
      'local-only': 'Offline Vault Ingestion (Local-Only)',
      'web-first': 'Instant Search Scraper (Fastest Live Update)',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: strategies.entries.map((e) {
          final isSelected = settings.searchStrategy == e.key;
          return ListTile(
            leading: Icon(Icons.travel_explore_rounded, color: isSelected ? accent : Colors.grey),
            title: Text(
              e.value,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected ? Icon(Icons.check_circle_outline_rounded, color: accent) : null,
            onTap: () {
              Navigator.pop(context);
              _updateSettingField('searchStrategy', e.key, "Search strategy set to: ${e.value}.");
            },
          );
        }).toList(),
      ),
    );
  }

  void _showMemoryBehaviorPicker(AuraSettings settings, Color accent, bool isDark) {
    final behaviors = {
      'project-isolated': 'Project Isolated Space Memory',
      'global-vault': 'Cross-Project Global Knowledge base',
      'disabled': 'Volatile Buffer Mode (No saving)',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: behaviors.entries.map((e) {
          final isSelected = settings.memoryBehavior == e.key;
          return ListTile(
            leading: Icon(Icons.sd_card_outlined, color: isSelected ? accent : Colors.grey),
            title: Text(
              e.value,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected ? Icon(Icons.check_circle_outline_rounded, color: accent) : null,
            onTap: () {
              Navigator.pop(context);
              _updateSettingField('memoryBehavior', e.key, "Memory Isolation level set to: ${e.value}.");
            },
          );
        }).toList(),
      ),
    );
  }

  void _showDensityPicker(AuraSettings settings, Color accent, bool isDark) {
    final densities = ["COMFY", "COZY", "COMPACT"];
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: densities.map((d) {
          final isSelected = settings.layoutDensity == d;
          return ListTile(
            leading: Icon(Icons.grid_view_rounded, color: isSelected ? accent : Colors.grey),
            title: Text(
              d,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected ? Icon(Icons.check_circle_outline_rounded, color: accent) : null,
            onTap: () {
              Navigator.pop(context);
              _updateSettingField('layoutDensity', d, "Layout Spacing set to $d.");
            },
          );
        }).toList(),
      ),
    );
  }

  void _showAutoSavePicker(AuraSettings settings, Color accent, bool isDark) {
    final rates = ["1m", "5m", "10m", "manual"];
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: rates.map((r) {
          final isSelected = settings.autoSaveFrequency == r;
          return ListTile(
            leading: Icon(Icons.save_outlined, color: isSelected ? accent : Colors.grey),
            title: Text(
              r == 'manual' ? 'Manual Sync only' : 'Save every $r',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected ? Icon(Icons.check_circle_outline_rounded, color: accent) : null,
            onTap: () {
              Navigator.pop(context);
              _updateSettingField('autoSaveFrequency', r, "Auto-Save rate calibrated to $r.");
            },
          );
        }).toList(),
      ),
    );
  }

  void _showEditProfileModal(AuraSettings settings, Color accent, bool isDark) {
    final usernameController = TextEditingController(text: settings.profileUsername);
    final emailController = TextEditingController(text: settings.profileEmail);
    final imageController = TextEditingController(text: settings.profileImage);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "EDIT NEURAL PROFILE",
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Username",
                labelStyle: GoogleFonts.outfit(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Email Address",
                labelStyle: GoogleFonts.outfit(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageController,
              style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: "Avatar Image Network URL",
                labelStyle: GoogleFonts.outfit(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("CANCEL", style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (usernameController.text.isNotEmpty) {
                      await ref.read(settingsProvider.notifier).updateSetting('profileUsername', usernameController.text);
                    }
                    await ref.read(settingsProvider.notifier).updateSetting('profileEmail', emailController.text);
                    await ref.read(settingsProvider.notifier).updateSetting('profileImage', imageController.text);
                    _showNotification("Neural Profile Updated successfully.");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("SAVE METRICS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(Color accent, bool isDark) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDlgState) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
          ),
          title: Text(
            "Change Account Security Access Key",
            style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Current Password Key",
                  labelStyle: GoogleFonts.outfit(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "New Password Key",
                  labelStyle: GoogleFonts.outfit(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: "Confirm Password Key",
                  labelStyle: GoogleFonts.outfit(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accent)),
                ),
              ),
              const SizedBox(height: 10),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(color: accent),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: GoogleFonts.outfit(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newController.text != confirmController.text) {
                        _showNotification("Confirmation mismatch.", isError: true);
                        return;
                      }
                      if (newController.text.length < 8) {
                        _showNotification("Key must be 8+ characters.", isError: true);
                        return;
                      }

                      setDlgState(() => isLoading = true);
                      final success = await ref
                          .read(settingsProvider.notifier)
                          .changePassword(currentController.text, newController.text);
                      setDlgState(() => isLoading = false);
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (success) {
                          _showNotification("Security keys rotated successfully.");
                        } else {
                          _showNotification("Failed to authenticate or sync key.", isError: true);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: Text("ROTATE KEYS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        );
      }),
    );
  }

  void _showWipeMemoryWarningDialog(Color accent, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? Colors.redAccent.withOpacity(0.3) : Colors.black.withOpacity(0.1)),
        ),
        title: Text(
          "PURGE COGNITIVE VAULT?",
          style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Warning: This will perform an irreversible purge of the vector databases, local chat memory folders, and operational caches. This action cannot be undone.",
          style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black.withOpacity(0.8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ABORT PURGE", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isWipingMemory
                ? null
                : () async {
                    Navigator.pop(context);
                    if (mounted) setState(() => _isWipingMemory = true);
                    _showNotification("Purging database nodes...");
                    final success = await ref.read(settingsProvider.notifier).wipeNeuralMemory();
                    if (mounted) setState(() => _isWipingMemory = false);
                    
                    if (success) {
                      _showNotification("Neural memory purged. System rebooted.");
                    } else {
                      _showNotification("Purge execution disrupted.", isError: true);
                    }
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("EXECUTE PURGE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _simulateOverlayPermissionDialog(Color accent, bool isDark) {
    bool isClosed = false;
    bool systemOverlayGranted = false;
    bool accessibilityGranted = false;
    bool batteryOptimizationIgnored = false;
    bool screenCaptureGranted = false;

    void checkPermissions(Function setDlgState) async {
      if (isClosed || !mounted) return;
      final overlayOk = await OverlayService.checkOverlayPermission();
      final accessOk = await OverlayService.checkAccessibilityPermission();
      final batteryOk = await OverlayService.checkBatteryOptimizationIgnored();
      final screenOk = await OverlayService.checkScreenCapturePermission();
      if (overlayOk != systemOverlayGranted || 
          accessOk != accessibilityGranted || 
          batteryOk != batteryOptimizationIgnored ||
          screenOk != screenCaptureGranted) {
        setDlgState(() {
          systemOverlayGranted = overlayOk;
          accessibilityGranted = accessOk;
          batteryOptimizationIgnored = batteryOk;
          screenCaptureGranted = screenOk;
        });
      }
      Future.delayed(const Duration(seconds: 1), () => checkPermissions(setDlgState));
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(builder: (context, setDlgState) {
        checkPermissions(setDlgState);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ANDROID SYSTEM PERMISSIONS",
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      isClosed = true;
                      ref.read(settingsProvider.notifier).updateSetting('overlayEnabled', false);
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Overlay Assistant Verification",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "To display the floating AI assistant over other application interfaces, AURA OS requires system permissions. Click enable below for each node:",
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _buildPermissionTile(
                icon: Icons.filter_none_outlined,
                title: "Display over other apps",
                subtitle: systemOverlayGranted ? "Permission Granted" : "Allow AURA to appear above apps so it can assist you anywhere.",
                value: systemOverlayGranted,
                accent: accent,
                isDark: isDark,
                onChanged: (val) {
                  if (!systemOverlayGranted) {
                    OverlayService.requestOverlayPermission();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildPermissionTile(
                icon: Icons.accessibility_new_rounded,
                title: "Accessibility Services",
                subtitle: accessibilityGranted ? "Permission Granted" : "Allow accessibility access so AURA can understand app context and guide you intelligently.",
                value: accessibilityGranted,
                accent: accent,
                isDark: isDark,
                onChanged: (val) {
                  if (!accessibilityGranted) {
                    OverlayService.requestAccessibilityPermission();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildPermissionTile(
                icon: Icons.screenshot_monitor_rounded,
                title: "Screen Capture Permission",
                subtitle: screenCaptureGranted ? "Screen Access Active" : "Allow screen access so AURA can analyze visible content and help in realtime.",
                value: screenCaptureGranted,
                accent: accent,
                isDark: isDark,
                onChanged: (val) {
                  if (!screenCaptureGranted) {
                    OverlayService.requestScreenCapturePermission();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildPermissionTile(
                icon: Icons.battery_saver_rounded,
                title: "Ignore Battery Optimizations",
                subtitle: batteryOptimizationIgnored ? "Process Protection Active" : "Prevents Android from killing AURA in background",
                value: batteryOptimizationIgnored,
                accent: accent,
                isDark: isDark,
                onChanged: (val) {
                  if (!batteryOptimizationIgnored) {
                    OverlayService.requestIgnoreBatteryOptimization();
                  }
                },
              ),
              if (!systemOverlayGranted) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Allow display over other apps to enable AURA Assistant.",
                          style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!systemOverlayGranted)
                      ? null
                      : () async {
                           isClosed = true;
                           Navigator.pop(context);
                           _updateSettingField('overlayEnabled', true, "Overlay assistant and permissions locked.");
                           _updateSettingField('floatingAssistantEnabled', true, "Floating helper activated.");
                           _updateSettingField('backgroundServiceEnabled', accessibilityGranted, "Accessibility listeners ${accessibilityGranted ? 'activated' : 'inactive'}.");
                           await OverlayService.startOverlay();
                         },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  ),
                  child: Text(
                    (!systemOverlayGranted) ? "AWAITING PERMISSIONS..." : "CONFIRM PERMISSION ACCESS",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: (!systemOverlayGranted) ? Colors.grey : Colors.black,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      }),
    );
  }


  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color accent,
    required bool isDark,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value ? accent.withOpacity(0.3) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? accent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: value ? accent : Colors.grey, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _buildSwitch(value, onChanged, accent),
        ],
      ),
    );
  }

  // --- STRING FORMATTERS ---

  String _formatPersonaName(String key) {
    switch (key) {
      case 'ultra-technical':
        return 'Authoritative Architect';
      case 'minimalist-hacker':
        return 'Minimalist Hacker';
      case 'warm-narrative':
      default:
        return 'Warm Narrative';
    }
  }

  String _formatSearchStrategy(String key) {
    switch (key) {
      case 'local-only':
        return 'Local Vault Only';
      case 'web-first':
        return 'Web Scraper First';
      case 'multi-tier':
      default:
        return 'Multi-Tier Web (Tavily)';
    }
  }

  String _formatMemoryBehavior(String key) {
    switch (key) {
      case 'global-vault':
        return 'Cross-Project Global';
      case 'disabled':
        return 'Volatile (Disabled)';
      case 'project-isolated':
      default:
        return 'Project Isolated';
    }
  }
}
