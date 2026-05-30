import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/overlay_service.dart';
import '../providers/settings_provider.dart';
import '../app_theme.dart';

Future<void> handleActivateOverlay(BuildContext context, WidgetRef ref) async {
  if (defaultTargetPlatform != TargetPlatform.android) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F0F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Text(
          "Platform Not Supported",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "The system-wide floating overlay assistant is only supported on Android devices. For this platform, please use the in-app chat companion.",
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.outfit(color: AppColors.neonCyan)),
          ),
        ],
      ),
    );
    return;
  }

  // On Android, check overlay permission first
  final bool hasPermission = await OverlayService.checkOverlayPermission();
  if (hasPermission) {
    // Check screen capture permission
    final bool screenCaptureOk = await OverlayService.checkScreenCapturePermission();
    if (!screenCaptureOk) {
      final bool granted = await OverlayService.requestScreenCapturePermission();
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Screen capture denied. Screen analysis will be unavailable."),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }

    // Start service directly
    await ref.read(settingsProvider.notifier).updateSetting('overlayEnabled', true);
    await ref.read(settingsProvider.notifier).updateSetting('floatingAssistantEnabled', true);
    await OverlayService.startOverlay();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AURA Assistant overlay started! Look for the floating orb on your screen."),
          backgroundColor: AppColors.neonCyan,
        ),
      );
    }
  } else {
    // Show permission dialog if missing
    if (context.mounted) {
      showOverlayPermissionDialog(context, ref);
    }
  }
}

void showOverlayPermissionDialog(BuildContext context, WidgetRef ref, {VoidCallback? onComplete}) {
  final settings = ref.read(settingsProvider);
  final isDark = settings.themeMode == 'DARK';
  final accent = AppTheme.getAccentColor(settings.accentColor);

  bool isClosed = false;
  bool systemOverlayGranted = false;
  bool accessibilityGranted = false;
  bool batteryOptimizationIgnored = false;
  bool screenCaptureGranted = false;

  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDlgState) {
          // Inner function to poll permissions while dialog is active
          void checkPermissions() async {
            if (isClosed || !context.mounted) return;
            final overlayOk = await OverlayService.checkOverlayPermission();
            final accessOk = await OverlayService.checkAccessibilityPermission();
            final batteryOk = await OverlayService.checkBatteryOptimizationIgnored();
            final screenOk = await OverlayService.checkScreenCapturePermission();
            
            if (overlayOk != systemOverlayGranted ||
                accessOk != accessibilityGranted ||
                batteryOk != batteryOptimizationIgnored ||
                screenOk != screenCaptureGranted) {
              if (context.mounted) {
                setDlgState(() {
                  systemOverlayGranted = overlayOk;
                  accessibilityGranted = accessOk;
                  batteryOptimizationIgnored = batteryOk;
                  screenCaptureGranted = screenOk;
                });
              }
            }
            Future.delayed(const Duration(seconds: 1), checkPermissions);
          }

          // Trigger polling
          checkPermissions();

          return Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
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
                    "To display the floating AI assistant over other application interfaces, AURA OS requires system permissions. Grant the display permission to enable overlay.",
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
                    subtitle: systemOverlayGranted
                        ? "Permission Granted"
                        : "Allow AURA to appear above apps so it can assist you anywhere. (REQUIRED)",
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
                    subtitle: accessibilityGranted
                        ? "Permission Granted"
                        : "Allow accessibility access so AURA can understand app context and guide you intelligently.",
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
                    subtitle: screenCaptureGranted
                        ? "Screen Access Active"
                        : "Allow screen access so AURA can analyze visible content and help in realtime.",
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
                    subtitle: batteryOptimizationIgnored
                        ? "Process Protection Active"
                        : "Prevents Android from killing AURA in background",
                    value: batteryOptimizationIgnored,
                    accent: accent,
                    isDark: isDark,
                    onChanged: (val) {
                      if (!batteryOptimizationIgnored) {
                        OverlayService.requestIgnoreBatteryOptimization();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!systemOverlayGranted) {
                          // Prompt Android settings directly
                          await OverlayService.requestOverlayPermission();
                        } else {
                          isClosed = true;
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          // Check and request screen capture permission if not granted
                          if (!screenCaptureGranted) {
                            final bool granted = await OverlayService.requestScreenCapturePermission();
                            if (!granted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("Screen capture denied. Screen analysis will be unavailable."),
                                  backgroundColor: Colors.orangeAccent,
                                ),
                              );
                            }
                          }

                          await ref.read(settingsProvider.notifier).updateSetting('overlayEnabled', true);
                          await ref.read(settingsProvider.notifier).updateSetting('floatingAssistantEnabled', true);
                          await ref.read(settingsProvider.notifier).updateSetting('backgroundServiceEnabled', accessibilityGranted);
                          await OverlayService.startOverlay();

                          navigator.pop();
                          if (onComplete != null) {
                            onComplete();
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("AURA Assistant overlay started! Look for the floating orb on your screen."),
                                backgroundColor: AppColors.neonCyan,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: systemOverlayGranted ? accent : Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        (!systemOverlayGranted)
                            ? "GRANT OVERLAY PERMISSION"
                            : "CONFIRM & ACTIVATE OVERLAY",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: systemOverlayGranted ? Colors.black : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      );
    },
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
      border: Border.all(
        color: value
            ? accent.withOpacity(0.3)
            : (isDark ? Colors.white10 : Colors.black.withOpacity(0.1)),
      ),
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: accent,
          activeTrackColor: accent.withOpacity(0.2),
        ),
      ],
    ),
  );
}
