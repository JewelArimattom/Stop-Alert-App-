import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import '../services/map_cache_service.dart';
import '../services/mapbox_service.dart';

class MapWidget extends StatelessWidget {
  final MapController? controller;
  final LatLng? center;
  final LatLng? destination;
  final LatLng? currentPosition;
  final double zoom;
  final double? geofenceRadius;
  final Function(TapPosition, LatLng)? onTap;
  final bool showRoute;
  final bool isDarkMode;

  /// Road-following route points from Mapbox Directions API.
  /// When provided, these are used instead of a straight line.
  final List<LatLng>? routePoints;

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
    this.isDarkMode = false,
    this.routePoints,
  });

  @override
  Widget build(BuildContext context) {
    final tileProvider = MapCacheService.tileProvider;

    // Build the polyline points: use Mapbox route if available, else straight line
    final List<LatLng> polylinePoints;
    if (routePoints != null && routePoints!.isNotEmpty) {
      polylinePoints = routePoints!;
    } else if (currentPosition != null && destination != null) {
      polylinePoints = [currentPosition!, destination!];
    } else {
      polylinePoints = [];
    }

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
          // Mapbox streets tile layer — premium look
          TileLayer(
            urlTemplate: MapboxService.tileUrlTemplate,
            userAgentPackageName: 'com.stopalert.app',
            tileProvider: tileProvider,
            maxZoom: 18,
            // No color filter needed — Mapbox streets-v12 looks great natively
          ),

          // Geofence circle with green glow
          if (destination != null && geofenceRadius != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: destination!,
                  radius: geofenceRadius!,
                  useRadiusInMeter: true,
                  color: AppColors.primary.withOpacity(0.10),
                  borderColor: AppColors.primary.withOpacity(0.5),
                  borderStrokeWidth: 2.0,
                ),
              ],
            ),

          // Route polyline — road-following green line
          if (showRoute && polylinePoints.length >= 2)
            PolylineLayer(
              polylines: [
                // Glow / shadow layer
                Polyline(
                  points: polylinePoints,
                  color: AppColors.primary.withOpacity(0.18),
                  strokeWidth: 10,
                ),
                // Main solid route line
                Polyline(
                  points: polylinePoints,
                  color: AppColors.primary,
                  strokeWidth: 4.5,
                ),
              ],
            ),

          // Markers
          MarkerLayer(
            markers: [
              // Current position marker — blue dot with pulse ring
              if (currentPosition != null)
                Marker(
                  point: currentPosition!,
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.info.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Destination marker — green pin badge
              if (destination != null)
                Marker(
                  point: destination!,
                  width: 50,
                  height: 50,
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
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
