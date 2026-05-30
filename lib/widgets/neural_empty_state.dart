import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'aura_pulse.dart';

class NeuralEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;
  
  const NeuralEmptyState({super.key, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Neural Visuals
          const AuraPulse(isSpeaking: false),
          const SizedBox(height: 60),
          
          Text(
            "NEURAL COMMAND CENTER",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Your workspace is currently a blank canvas for neural intelligence. Initialize your first project to begin the strategic mapping process.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          
          // Premium CTA
          GestureDetector(
            onTap: onCreatePressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [AppColors.electricBlue, AppColors.violetGlow],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "INITIALIZE WORKSPACE",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          _buildOnboardingHint(
            Icons.auto_awesome_outlined,
            "AI-Assisted Onboarding",
            "Aura will guide your architectural choices.",
          ),
          const SizedBox(height: 12),
          _buildOnboardingHint(
            Icons.memory_rounded,
            "Neural Memory Vault",
            "Your projects gain long-term strategic recall.",
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingHint(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
