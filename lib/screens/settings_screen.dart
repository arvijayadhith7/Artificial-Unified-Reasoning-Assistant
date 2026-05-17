import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _transparencyEffects = true;
  String _selectedTheme = "DARK";
  double _temperature = 0.7;
  String _activeModel = "AURA Ultra";
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _transparencyEffects = prefs.getBool('transparency') ?? true;
      _selectedTheme = prefs.getString('theme') ?? "DARK";
      _temperature = prefs.getDouble('temp') ?? 0.7;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is double) await prefs.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("MISSION CONTROL", style: GoogleFonts.outfit(fontSize: 14, letterSpacing: 6, fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 30),

            _buildSectionTitle("NEURAL CONFIG"),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.psychology_outlined, 
                title: "Inference Engine", 
                subtitle: _activeModel, 
                onTap: () => _showModelPicker(),
                showArrow: true
              ),
              _buildSettingsTile(
                icon: Icons.thermostat_outlined, 
                title: "Neural Temperature", 
                subtitle: _temperature.toStringAsFixed(1),
                customTrailing: _buildSliderBar(),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("VISUAL CORE"),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined, 
                title: "Theme Mode", 
                customTrailing: _buildSegmentedControl(["DARK", "LIGHT"])
              ),
              _buildSettingsTile(
                icon: Icons.grid_on_outlined, 
                title: "Transparency", 
                customTrailing: _buildSwitch(_transparencyEffects, (val) {
                  setState(() => _transparencyEffects = val);
                  _saveSetting('transparency', val);
                })
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionTitle("SECURITY GATEWAY"),
            _buildSettingsGroup([
              _buildSettingsTile(icon: Icons.vpn_key_outlined, title: "API Terminal", subtitle: "Manage Neural Keys", showArrow: true, onTap: _showAPITerminal),
              _buildSettingsTile(icon: Icons.delete_outline, title: "Purge Neural Memory", titleColor: const Color(0xFFFFA07A), onTap: _showPurgeDialog),
            ]),
            const SizedBox(height: 32),

            _buildSignOutButton(),
            const SizedBox(height: 20),
            Center(
              child: Text("AURA OS V2.3.0", style: GoogleFonts.outfit(color: Colors.white24, fontSize: 11, letterSpacing: 2)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          CircleAvatar(radius: 28, backgroundColor: AppColors.neonCyan.withOpacity(0.1), child: const Icon(Icons.person_outline_rounded, color: AppColors.neonCyan, size: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NEURAL GUEST", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text("Tier: Intelligence Pro", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.verified_user_rounded, color: AppColors.electricBlue, size: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, bool showArrow = false, Widget? customTrailing, Color? titleColor, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.neonCyan, size: 22),
      title: Text(title, style: GoogleFonts.outfit(color: titleColor ?? Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)) : null,
      trailing: customTrailing ?? (showArrow ? const Icon(Icons.chevron_right_rounded, color: Colors.white24) : null),
    );
  }

  Widget _buildSliderBar() {
    return SizedBox(
      width: 100,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
        child: Slider(
          value: _temperature,
          onChanged: (val) {
            setState(() => _temperature = val);
            _saveSetting('temp', val);
          },
          activeColor: AppColors.neonCyan,
          inactiveColor: Colors.white10,
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(List<String> options) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        bool isSelected = _selectedTheme == opt;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedTheme = opt);
            _saveSetting('theme', opt);
          },
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.neonCyan : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(opt, style: GoogleFonts.outfit(color: isSelected ? Colors.black : Colors.white54, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.neonCyan,
      activeTrackColor: AppColors.neonCyan.withOpacity(0.3),
    );
  }

  Widget _buildSignOutButton() {
    return InkWell(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
            const SizedBox(width: 12),
            Text("TERMINATE SESSION", style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ["AURA Ultra", "AURA Flash", "AURA Reasoning"].map((m) => ListTile(
          title: Text(m, style: GoogleFonts.outfit(color: Colors.white)),
          onTap: () {
            setState(() => _activeModel = m);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _showAPITerminal() {}
  void _showPurgeDialog() {}
}
