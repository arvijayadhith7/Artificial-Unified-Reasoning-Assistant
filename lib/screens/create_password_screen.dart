import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/glowing_orb.dart';
import 'main_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String email;
  final String? googleId;

  const CreatePasswordScreen({super.key, required this.email, this.googleId});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _usernameController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _initStep = "";

  Future<void> _handleSetup() async {
    final password = _passwordController.text;
    
    // Neural Password Validation
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AURA security requires 8+ characters")));
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Must include an UPPERCASE letter")));
      return;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Must include a lowercase letter")));
      return;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Must include a special character")));
      return;
    }

    if (password != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Access keys do not match")));
      return;
    }

    setState(() {
      _isLoading = true;
      _initStep = "VALIDATING IDENTITY...";
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _initStep = "CONSTRUCTING WORKSPACE...");
      
      final result = await _authService.setupAuraPassword(
        email: widget.email,
        password: _passwordController.text,
        username: _usernameController.text,
        googleId: widget.googleId,
      );

      if (result['status'] == 'success') {
        setState(() => _initStep = "INITIALIZING NEURAL MEMORY...");
        await Future.delayed(const Duration(seconds: 1));
        
        setState(() => _initStep = "SECURING ACCESS KEYS...");
        await _authService.saveSession(result['token'], _usernameController.text);
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Setup failed: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading ? _buildLoadingOverlay() : _buildForm(),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlowingOrb(size: 80),
          const SizedBox(height: 40),
          Text(
            _initStep,
            style: GoogleFonts.outfit(
              color: AppColors.neonCyan, 
              fontSize: 12, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 4
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white10,
              color: AppColors.neonCyan,
              minHeight: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "COMPLETE YOUR\nNEURAL PROFILE",
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
            ),
            const SizedBox(height: 12),
            Text("Identify yourself within the AURA network", style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            const SizedBox(height: 50),
            
            _buildField("USERNAME", Icons.person_outline, _usernameController),
            const SizedBox(height: 24),
            _buildField("CREATE AURA PASSWORD", Icons.lock_outline, _passwordController, isPassword: true),
            const SizedBox(height: 24),
            _buildField("CONFIRM PASSWORD", Icons.lock_reset, _confirmController, isPassword: true),
            
            const SizedBox(height: 60),
            
            GestureDetector(
              onTap: _handleSetup,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.electricBlue, AppColors.violetGlow]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.electricBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: Text("INITIALIZE ACCOUNT", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.white24), border: InputBorder.none, contentPadding: const EdgeInsets.all(20)),
          ),
        ),
      ],
    );
  }
}
