import 'package:flutter/material.dart';
import '../models/tracking_state.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TrackingStatusCard extends StatelessWidget {
  final TrackingData trackingData;

  const TrackingStatusCard({
    super.key,
    required this.trackingData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Speed and Mode row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                icon: Icons.speed_rounded,
                label: 'Speed',
                value: Helpers.formatSpeed(trackingData.speedMps),
                color: AppColors.info,
              ),
              _buildModeChip(trackingData.travelMode),
              _buildInfoChip(
                icon: Icons.timer_rounded,
                label: 'ETA',
                value: trackingData.eta != null
                    ? Helpers.formatETA(trackingData.eta!)
                    : '--:--',
                color: AppColors.warning,
              ),
            ],
          ),

          if (trackingData.isIdle) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause_circle_outline,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Idle - GPS paused to save battery',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip(TravelMode mode) {
    final isStationary = mode == TravelMode.stationary;
    final icon = isStationary
        ? Icons.pause_circle_outline_rounded
        : Icons.directions_transit_rounded;
    final label = isStationary ? 'Idle' : 'Travelling';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.background, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }
}
