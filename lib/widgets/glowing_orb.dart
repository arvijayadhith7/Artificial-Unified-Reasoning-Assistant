import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../app_theme.dart';

enum OrbState { idle, listening, thinking, speaking }

class GlowingOrb extends StatefulWidget {
  final OrbState state;
  final double size;

  const GlowingOrb({
    super.key,
    this.state = OrbState.idle,
    this.size = 200,
  });

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Container(
                width: widget.size * _pulseAnimation.value,
                height: widget.size * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonBlue.withOpacity(0.3),
                      AppColors.neonPurple.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Inner Orb
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.neonBlue,
                        AppColors.neonPurple,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonBlue.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: OrbPainter(widget.state, _pulseController.value),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OrbPainter extends CustomPainter {
  final OrbState state;
  final double animationValue;

  OrbPainter(this.state, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw some futuristic "energy" lines inside the orb
    for (var i = 0; i < 3; i++) {
      final r = radius * (0.4 + (i * 0.2));
      canvas.drawCircle(center, r, paint);
    }

    if (state == OrbState.listening) {
      // Draw waveform-like patterns
      final wavePaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      for (var i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4) + (animationValue * math.pi);
        final x1 = center.dx + math.cos(angle) * (radius * 0.5);
        final y1 = center.dy + math.sin(angle) * (radius * 0.5);
        final x2 = center.dx + math.cos(angle) * (radius * (0.5 + animationValue * 0.3));
        final y2 = center.dy + math.sin(angle) * (radius * (0.5 + animationValue * 0.3));
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
