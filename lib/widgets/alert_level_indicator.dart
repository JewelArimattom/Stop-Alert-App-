
import 'package:flutter/material.dart';
import '../models/tracking_state.dart';
import '../utils/constants.dart';

class AlertLevelIndicator extends StatefulWidget {
  final AlertLevel alertLevel;
  final double size;

  const AlertLevelIndicator({
    super.key,
    required this.alertLevel,
    this.size = 120,
  });

  @override
  State<AlertLevelIndicator> createState() => _AlertLevelIndicatorState();
}

class _AlertLevelIndicatorState extends State<AlertLevelIndicator>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ringController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.alertLevel) {
      case AlertLevel.none:
        return AppColors.textMuted;
      case AlertLevel.notification:
        return AppColors.info;
      case AlertLevel.sound:
        return AppColors.warning;
      case AlertLevel.alarm:
        return AppColors.danger;
    }
  }

  IconData _getIcon() {
    switch (widget.alertLevel) {
      case AlertLevel.none:
        return Icons.location_searching;
      case AlertLevel.notification:
        return Icons.notifications_active;
      case AlertLevel.sound:
        return Icons.volume_up_rounded;
      case AlertLevel.alarm:
        return Icons.alarm_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final isActive = widget.alertLevel != AlertLevel.none;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding rings
          if (isActive)
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: RingPainter(
                    color: color,
                    progress: _ringController.value,
                    rings: widget.alertLevel == AlertLevel.alarm ? 3 : 2,
                  ),
                );
              },
            ),

          // Glow effect
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Container(
                width: widget.size * 0.45,
                height: widget.size * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(
                    isActive ? 0.15 + _glowController.value * 0.1 : 0.08,
                  ),
                  border: Border.all(
                    color: color.withOpacity(isActive ? 0.6 : 0.2),
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withOpacity(
                                0.3 + _glowController.value * 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  _getIcon(),
                  color: color,
                  size: widget.size * 0.2,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

class RingPainter extends CustomPainter {
  final Color color;
  final double progress;
  final int rings;

  RingPainter({
    required this.color,
    required this.progress,
    this.rings = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < rings; i++) {
      final offset = i / rings;
      final ringProgress = (progress + offset) % 1.0;
      final radius = maxRadius * 0.3 + (maxRadius * 0.7) * ringProgress;
      final opacity = (1.0 - ringProgress) * 0.5;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RingPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
