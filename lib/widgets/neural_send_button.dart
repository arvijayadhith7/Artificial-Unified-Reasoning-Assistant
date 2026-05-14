import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../app_theme.dart';

class NeuralSendButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isActive;
  final bool isSending;

  const NeuralSendButton({
    super.key,
    this.onTap,
    required this.isActive,
    this.isSending = false,
  });

  @override
  State<NeuralSendButton> createState() => _NeuralSendButtonState();
}

class _NeuralSendButtonState extends State<NeuralSendButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NeuralSendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
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
        final double glow = widget.isActive ? _controller.value : 0.0;
        
        return GestureDetector(
          onTap: widget.isActive ? widget.onTap : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isActive ? AppColors.neonCyan : Colors.transparent,
              boxShadow: widget.isActive ? [
                BoxShadow(
                  color: AppColors.neonCyan.withOpacity(0.3 + (0.2 * glow)),
                  blurRadius: 8 + (12 * glow),
                  spreadRadius: 1 + (2 * glow),
                ),
                BoxShadow(
                  color: AppColors.electricBlue.withOpacity(0.2 * glow),
                  blurRadius: 20 * glow,
                  spreadRadius: 5 * glow,
                ),
              ] : [],
              border: Border.all(
                color: widget.isActive ? AppColors.neonCyan : AppColors.textSecondary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: widget.isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Icon(
                    Icons.arrow_upward_rounded,
                    color: widget.isActive ? Colors.black : AppColors.textSecondary.withOpacity(0.5),
                    size: 22,
                  ),
            ),
          ),
        );
      },
    );
  }
}
