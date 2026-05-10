import 'package:flutter/material.dart';
import '../app_theme.dart';

class AuraPulse extends StatefulWidget {
  final bool isSpeaking;
  const AuraPulse({super.key, this.isSpeaking = false});

  @override
  State<AuraPulse> createState() => _AuraPulseState();
}

class _AuraPulseState extends State<AuraPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              _buildPulseCircle(1.0 + (i * 0.5 * _controller.value), 1.0 - _controller.value),
            
            // Core
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.neonBlue, AppColors.neonPurple],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonBlue.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPulseCircle(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.neonBlue.withOpacity(opacity * 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }
}
