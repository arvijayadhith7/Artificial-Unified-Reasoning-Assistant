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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ambient Glow
              Container(
                width: widget.size * (0.8 + 0.1 * pulse),
                height: widget.size * (0.8 + 0.1 * pulse),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryGreen.withOpacity(0.15),
                      AppColors.hoverGreen.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Rotating Energy Ring 1
              Transform.rotate(
                angle: rotation * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.9, widget.size * 0.9),
                  painter: _OrbRingPainter(
                    color: AppColors.primaryGreen.withOpacity(0.4),
                    progress: 0.6,
                    thickness: 1.5,
                  ),
                ),
              ),

              // Rotating Energy Ring 2
              Transform.rotate(
                angle: -rotation * 3 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.8, widget.size * 0.8),
                  painter: _OrbRingPainter(
                    color: AppColors.hoverGreen.withOpacity(0.3),
                    progress: 0.3,
                    thickness: 1,
                  ),
                ),
              ),

              // The Core Glass Orb
              Container(
                width: widget.size * 0.65,
                height: widget.size * 0.65,
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
                    color: Colors.black.withOpacity(0.85),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner pulse
                      Container(
                        width: widget.size * 0.2 * (1 + 0.2 * pulse),
                        height: widget.size * 0.2 * (1 + 0.2 * pulse),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withOpacity(0.8),
                              blurRadius: 20 * pulse,
                              spreadRadius: 5 * pulse,
                            ),
                          ],
                        ),
                      ),
                      
                      // Status Visualization
                      if (widget.state == OrbState.listening)
                         _buildListeningEffect(widget.size * 0.6),
                    ],
                  ),
                ),
              ),
              
              // Top Surface Highlight
              IgnorePointer(
                child: Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.4),
                      radius: 0.8,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListeningEffect(double size) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ListeningPainter(_pulseController.value),
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
    canvas.drawArc(rect, math.pi * 0.8, progress * 0.4 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ListeningPainter extends CustomPainter {
  final double animationValue;
  _ListeningPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6) + (animationValue * math.pi * 0.2);
      final waveHeight = 10 * math.sin(animationValue * 2 * math.pi + i);
      final x1 = center.dx + math.cos(angle) * (radius * 0.6);
      final y1 = center.dy + math.sin(angle) * (radius * 0.6);
      final x2 = center.dx + math.cos(angle) * (radius * 0.6 + waveHeight);
      final y2 = center.dy + math.sin(angle) * (radius * 0.6 + waveHeight);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
