import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/tracking_state.dart';

class DistanceIndicator extends StatefulWidget {
  final double distanceMeters;
  final TrackingZone zone;

  const DistanceIndicator({
    super.key,
    required this.distanceMeters,
    required this.zone,
  });

  @override
  State<DistanceIndicator> createState() => _DistanceIndicatorState();
}

class _DistanceIndicatorState extends State<DistanceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getZoneColor() {
    switch (widget.zone) {
      case TrackingZone.far:
        return AppColors.info;
      case TrackingZone.mid:
        return AppColors.primary;
      case TrackingZone.near:
        return AppColors.warning;
      case TrackingZone.veryClose:
      case TrackingZone.arrived:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getZoneColor();
    final shouldPulse = widget.zone == TrackingZone.near ||
        widget.zone == TrackingZone.veryClose ||
        widget.zone == TrackingZone.arrived;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = shouldPulse ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Helpers.formatDistance(widget.distanceMeters),
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Helpers.getZoneName(widget.zone.name.toUpperCase()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
