import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../app_theme.dart';

class AuraPulse extends StatefulWidget {
  final bool isSpeaking;
  const AuraPulse({super.key, this.isSpeaking = false});

  @override
  State<AuraPulse> createState() => _AuraPulseState();
}

class _AuraPulseState extends State<AuraPulse> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController]),
      builder: (context, child) {
        final double pulse = _pulseController.value;
        final double rotation = _rotationController.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient outer glow
            Container(
              width: 240 + (20 * pulse),
              height: 240 + (20 * pulse),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.15 * (1 - pulse * 0.5)),
                    AppColors.hoverGreen.withOpacity(0.05 * (1 - pulse * 0.5)),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Dynamic ring 1
            Transform.rotate(
              angle: rotation * 2 * math.pi,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _OrbRingPainter(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  progress: 0.7,
                  thickness: 1,
                ),
              ),
            ),

            // Dynamic ring 2
            Transform.rotate(
              angle: -rotation * 3 * math.pi,
              child: CustomPaint(
                size: const Size(180, 180),
                painter: _OrbRingPainter(
                  color: AppColors.hoverGreen.withOpacity(0.2),
                  progress: 0.4,
                  thickness: 0.5,
                ),
              ),
            ),

            // The Core Orb
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: -10,
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.hoverGreen.withOpacity(0.8),
                  ],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.8),
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.8),
                          blurRadius: 20 * pulse,
                          spreadRadius: 5 * pulse,
                        ),
                      ],
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ),
            
            // Inner highlights
            IgnorePointer(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OrbRingPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double thickness;

  _OrbRingPainter({required this.color, required this.progress, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    canvas.drawArc(rect, 0, progress * 2 * math.pi, false, paint);
    canvas.drawArc(rect, math.pi, progress * 0.5 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
