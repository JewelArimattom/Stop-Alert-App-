import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import '../services/map_cache_service.dart';

class MapWidget extends StatelessWidget {
  final MapController? controller;
  final LatLng? center;
  final LatLng? destination;
  final LatLng? currentPosition;
  final double zoom;
  final double? geofenceRadius;
  final Function(TapPosition, LatLng)? onTap;
  final bool showRoute;

  const MapWidget({
    super.key,
    this.controller,
    this.center,
    this.destination,
    this.currentPosition,
    this.zoom = 13,
    this.geofenceRadius,
    this.onTap,
    this.showRoute = false,
  });

  @override
  Widget build(BuildContext context) {
    final tileProvider = MapCacheService.tileProvider;
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center ?? const LatLng(20.5937, 78.9629),
          initialZoom: zoom,
          onTap: onTap,
          maxZoom: 18,
          minZoom: 3,
        ),
        children: [
          // Clean bright map tiles — no dark overlay
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.stopalert.app',
            tileProvider: tileProvider,
          ),

          // Geofence circle
          if (destination != null && geofenceRadius != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: destination!,
                  radius: geofenceRadius!,
                  useRadiusInMeter: true,
                  color: AppColors.primary.withOpacity(0.12),
                  borderColor: AppColors.primary.withOpacity(0.6),
                  borderStrokeWidth: 2.5,
                ),
              ],
            ),

          // Route line
          if (showRoute && currentPosition != null && destination != null)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [currentPosition!, destination!],
                  color: AppColors.primary.withOpacity(0.7),
                  strokeWidth: 4,
                  pattern: const StrokePattern.dotted(),
                ),
              ],
            ),

          // Markers
          MarkerLayer(
            markers: [
              // Current position marker
              if (currentPosition != null)
                Marker(
                  point: currentPosition!,
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),

              // Destination marker
              if (destination != null)
                Marker(
                  point: destination!,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
