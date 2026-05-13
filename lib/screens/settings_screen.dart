import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu_rounded, color: Colors.white),
        title: Text(
          "AURA",
          style: GoogleFonts.outfit(
            fontSize: 20,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonCyan),
            ),
            child: const CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0B0FF), // light purple indicator
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surface, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Julian Thorne",
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "julian.thorne@aura.ai",
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionTitle("INTELLIGENCE"),
            _buildSettingsGroup([
              _buildSettingsTile(icon: Icons.psychology_outlined, title: "Model Selection", subtitle: "AURA Ultra (Active)", showArrow: true),
              _buildSettingsTile(icon: Icons.memory_outlined, title: "Context Window", subtitle: "128k Tokens", showArrow: true),
              _buildSettingsTile(icon: Icons.thermostat_outlined, title: "Temperature", subtitle: "0.7 (Balanced)", customTrailing: _buildSliderBar()),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("APPEARANCE"),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined, 
                title: "Theme", 
                customTrailing: _buildSegmentedControl(["DARK", "LIGHT"])
              ),
              _buildSettingsTile(
                icon: Icons.palette_outlined, 
                title: "Accent Color", 
                customTrailing: _buildColorDots()
              ),
              _buildSettingsTile(
                icon: Icons.grid_on_outlined, 
                title: "Transparency Effects", 
                customTrailing: _buildSwitch(true)
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("PRIVACY & SECURITY"),
            _buildSettingsGroup([
              _buildSettingsTile(icon: Icons.lock_outline, title: "Data Encryption", subtitle: "AES-256 Enabled", subtitleInline: true),
              _buildSettingsTile(icon: Icons.memory_rounded, title: "Memory Management", showArrow: true),
              _buildSettingsTile(icon: Icons.delete_outline, title: "Clear History", titleColor: const Color(0xFFFFA07A)),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("SUBSCRIPTION"),
            _buildSettingsGroup([
              _buildSettingsTile(icon: Icons.workspace_premium_outlined, title: "Manage Plan", subtitle: "Next renewal: Oct 24, 2024", showArrow: true),
              _buildSettingsTile(icon: Icons.receipt_long_outlined, title: "Billing & Invoices", showArrow: true),
            ]),
            const SizedBox(height: 32),

            // Sign Out Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Color(0xFFFFA07A), size: 18),
                  const SizedBox(width: 8),
                  Text("SIGN OUT", style: GoogleFonts.outfit(color: const Color(0xFFFFA07A), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "AURA INTELLIGENCE V2.0.4281",
                style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget child = entry.value;
          if (idx != children.length - 1) {
            return Column(
              children: [
                child,
                Divider(height: 1, color: AppColors.border.withOpacity(0.5), indent: 56, endIndent: 16),
              ],
            );
          }
          return child;
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool showArrow = false,
    Widget? customTrailing,
    Color? titleColor,
    bool subtitleInline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: subtitleInline && subtitle != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: GoogleFonts.outfit(color: titleColor ?? Colors.white, fontSize: 15)),
                      Text(subtitle, style: GoogleFonts.outfit(color: const Color(0xFFE0B0FF), fontSize: 13)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.outfit(color: titleColor ?? Colors.white, fontSize: 15)),
                      if (subtitle != null && !subtitleInline) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
                      ]
                    ],
                  ),
          ),
          if (customTrailing != null) ...[
            const SizedBox(width: 16),
            customTrailing,
          ] else if (showArrow) ...[
            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildSliderBar() {
    return Container(
      width: 80,
      height: 4,
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.7,
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFE0B0FF), borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(List<String> options) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          bool isSelected = opt == "DARK";
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE0B0FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              opt,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.black : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(const Color(0xFFE0B0FF)),
        const SizedBox(width: 8),
        _buildDot(const Color(0xFF6B8AFD)),
        const SizedBox(width: 8),
        _buildDot(const Color(0xFFD2B48C)),
      ],
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSwitch(bool value) {
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFE0B0FF).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: Color(0xFFE0B0FF), shape: BoxShape.circle),
            ),
          )
        ],
      ),
    );
  }
}
