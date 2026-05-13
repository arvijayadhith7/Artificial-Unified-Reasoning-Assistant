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
    this.size = 220,
  });

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _innerRotationController;

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

    _innerRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _innerRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController, _innerRotationController]),
      builder: (context, child) {
        final double pulse = Curves.easeInOut.transform(_pulseController.value);
        final double rotation = _rotationController.value;
        final double innerRotation = _innerRotationController.value;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ambient Glow (Electric Blue)
              Container(
                width: widget.size * (0.85 + 0.1 * pulse),
                height: widget.size * (0.85 + 0.1 * pulse),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.electricBlue.withOpacity(0.2),
                      AppColors.violetGlow.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Outer Ring (Neon Cyan)
              Transform.rotate(
                angle: rotation * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.95, widget.size * 0.95),
                  painter: _OrbRingPainter(
                    color: AppColors.neonCyan.withOpacity(0.4),
                    segments: 3,
                    gap: 0.2,
                    thickness: 1.0,
                  ),
                ),
              ),

              // Middle Ring (Electric Blue)
              Transform.rotate(
                angle: -rotation * 3 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.85, widget.size * 0.85),
                  painter: _OrbRingPainter(
                    color: AppColors.electricBlue.withOpacity(0.3),
                    segments: 4,
                    gap: 0.15,
                    thickness: 1.5,
                  ),
                ),
              ),

              // Inner Data Ring (Violet)
              Transform.rotate(
                angle: innerRotation * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.75, widget.size * 0.75),
                  painter: _OrbRingPainter(
                    color: AppColors.violetGlow.withOpacity(0.5),
                    segments: 8,
                    gap: 0.05,
                    thickness: 2.0,
                  ),
                ),
              ),

              // The Core Glass Orb
              Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withOpacity(0.5),
                      blurRadius: 50 * pulse,
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: AppColors.violetGlow.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: -10,
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.electricBlue.withOpacity(0.8),
                      AppColors.violetGlow.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.9),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Central White Core
                      Container(
                        width: widget.size * 0.15 * (1 + 0.1 * pulse),
                        height: widget.size * 0.15 * (1 + 0.1 * pulse),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan,
                              blurRadius: 15 * pulse,
                              spreadRadius: 2,
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      
                      // State-specific visualizers
                      if (widget.state == OrbState.listening)
                        _buildListeningEffect(widget.size * 0.55),
                      if (widget.state == OrbState.thinking)
                        _buildThinkingEffect(widget.size * 0.55),
                    ],
                  ),
                ),
              ),
              
              // Gloss / Glass Highlight
              IgnorePointer(
                child: Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.35),
                      radius: 0.7,
                      colors: [
                        Colors.white.withOpacity(0.2),
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

  Widget _buildThinkingEffect(double size) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ThinkingPainter(_rotationController.value),
    );
  }
}

class _OrbRingPainter extends CustomPainter {
  final Color color;
  final int segments;
  final double gap;
  final double thickness;

  _OrbRingPainter({
    required this.color, 
    required this.segments, 
    required this.gap, 
    required this.thickness
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    final segmentAngle = (2 * math.pi) / segments;
    final gapAngle = segmentAngle * gap;
    final arcAngle = segmentAngle - gapAngle;

    for (var i = 0; i < segments; i++) {
      canvas.drawArc(rect, i * segmentAngle, arcAngle, false, paint);
    }
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
      ..color = AppColors.neonCyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 0; i < 32; i++) {
      final angle = (i * math.pi / 16);
      final noise = math.sin(animationValue * 10 + i * 0.5) * 5;
      final x1 = center.dx + math.cos(angle) * (radius * 0.5);
      final y1 = center.dy + math.sin(angle) * (radius * 0.5);
      final x2 = center.dx + math.cos(angle) * (radius * 0.6 + noise);
      final y2 = center.dy + math.sin(angle) * (radius * 0.6 + noise);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ThinkingPainter extends CustomPainter {
  final double rotation;
  _ThinkingPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.violetGlow.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 0; i < 4; i++) {
      final angle = (rotation * 2 * math.pi) + (i * math.pi / 2);
      final x = center.dx + math.cos(angle) * (radius * 0.4);
      final y = center.dy + math.sin(angle) * (radius * 0.4);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
