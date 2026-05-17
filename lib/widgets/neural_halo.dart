import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_theme.dart';
import '../providers/chat_provider.dart';

class NeuralHaloWidget extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  const NeuralHaloWidget({Key? key, this.onTap}) : super(key: key);

  @override
  ConsumerState<NeuralHaloWidget> createState() => _NeuralHaloWidgetState();
}

class _NeuralHaloWidgetState extends ConsumerState<NeuralHaloWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(neuralHaloStateProvider);
    final isOverlayVisible = ref.watch(overlayVisibleProvider);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap ?? () {
          // Toggle overlay visibility dynamically
          ref.read(overlayVisibleProvider.notifier).state = !isOverlayVisible;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: isOverlayVisible ? "Close Overlay Assist" : "Awaken Aura Overlay Assist",
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(40, 40),
                  painter: NeuralHaloPainter(
                    animationValue: _controller.value,
                    state: isOverlayVisible ? 'overlay' : activeState,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class NeuralHaloPainter extends CustomPainter {
  final double animationValue;
  final String state;

  NeuralHaloPainter({required this.animationValue, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double coreRadius = state == 'overlay' ? 8.0 : 6.0;
    final double ringRadius = state == 'overlay' ? 16.0 : 12.0;

    // Pick Colors based on active Neural States
    Color primaryColor = AppColors.neonCyan;
    Color secondaryColor = AppColors.electricBlue;
    double pulseFactor = math.sin(animationValue * math.pi * 2);

    if (state == 'listening') {
      primaryColor = AppColors.neonCyan;
      secondaryColor = const Color(0xFF00E5FF);
    } else if (state == 'thinking') {
      primaryColor = AppColors.electricBlue;
      secondaryColor = AppColors.violetGlow;
    } else if (state == 'analyzing') {
      primaryColor = const Color(0xFFFF0055); // Alert dynamic crimson
      secondaryColor = const Color(0xFFBE123C);
    } else if (state == 'overlay') {
      primaryColor = const Color(0xFF10B981); // Emerald guidance state
      secondaryColor = const Color(0xFF059669);
    }

    // Draw Ambient breathing outer halo glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.25 * (1 - pulseFactor * 0.2)),
          secondaryColor.withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: ringRadius * 2));
    canvas.drawCircle(center, ringRadius * 2, glowPaint);

    // Draw central Quantum core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.95),
          secondaryColor.withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius * 1.8));
    canvas.drawCircle(center, coreRadius, corePaint);

    // Draw dynamic interactive ring borders
    final ringPaint = Paint()
      ..color = primaryColor.withOpacity(0.2 + (pulseFactor * 0.08))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Standard Breathing energy halo ring
    canvas.drawCircle(center, ringRadius + (pulseFactor * 1.0), ringPaint);

    // If active processing, draw orbital sweep arcs
    if (state == 'thinking' || state == 'overlay') {
      final activeRingPaint = Paint()
        ..color = primaryColor.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      final rect = Rect.fromCircle(center: center, radius: ringRadius);
      canvas.drawArc(rect, animationValue * math.pi * 2, math.pi / 2, false, activeRingPaint);
      canvas.drawArc(rect, (animationValue + 0.5) * math.pi * 2, math.pi / 4, false, activeRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NeuralHaloPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.state != state;
  }
}
