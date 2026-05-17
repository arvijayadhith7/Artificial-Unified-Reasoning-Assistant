import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../app_theme.dart';
import 'glowing_orb.dart';

class NeuralThinkingIndicator extends StatefulWidget {
  final String status;
  const NeuralThinkingIndicator({super.key, this.status = "Aura is typing"});

  @override
  State<NeuralThinkingIndicator> createState() => _NeuralThinkingIndicatorState();
}

class _NeuralThinkingIndicatorState extends State<NeuralThinkingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const GlowingOrb(size: 14),
              const SizedBox(width: 8),
              Text("AURA", style: GoogleFonts.outfit(color: AppColors.neonCyan, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.status, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(width: 8),
                _buildBouncingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBouncingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _dotController,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = math.sin((_dotController.value * 2 * math.pi) - delay);
            final bounce = (value + 1.0) / 2.0; // Normalise to 0.0 - 1.0

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              transform: Matrix4.translationValues(0, -3 * bounce, 0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan,
              ),
            );
          },
        );
      }),
    );
  }
}
