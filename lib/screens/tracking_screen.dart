import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../providers/trip_provider.dart';
import '../utils/constants.dart';
import '../widgets/map_widget.dart';
import '../widgets/distance_indicator.dart';
import '../widgets/tracking_status_card.dart';
import '../widgets/alert_level_indicator.dart';
import '../services/mapbox_service.dart';
import 'set_destination_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  /// Mapbox road-following route polyline
  List<LatLng>? _routePoints;

  /// Road distance from Mapbox (meters)
  double? _roadDistanceMeters;

  /// Timer to throttle route refetches
  Timer? _routeRefreshTimer;

  /// Last position used for route fetch, to avoid redundant calls
  LatLng? _lastRouteFetchPosition;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Fetch initial route after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRouteIfNeeded();
    });

    // Periodically refresh route every 30 seconds
    _routeRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchRouteIfNeeded();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _routeRefreshTimer?.cancel();
    super.dispose();
  }

  /// Fetch a Mapbox route if the position has changed significantly
  Future<void> _fetchRouteIfNeeded() async {
    final provider = context.read<TripProvider>();
    final tracking = provider.trackingData;
    final current = tracking.currentPosition;
    final dest = tracking.destination;

    if (current == null || dest == null) return;

    // Skip if position hasn't moved more than 200m from last fetch
    if (_lastRouteFetchPosition != null) {
      final movedMeters = const Distance().as(
        LengthUnit.Meter,
        _lastRouteFetchPosition!,
        current,
      );
      if (movedMeters < 200) return;
    }

    _lastRouteFetchPosition = current;

    final route = await MapboxService.getRoute(current, dest);
    if (!mounted) return;

    setState(() {
      if (route != null) {
        _routePoints = route.points;
        _roadDistanceMeters = route.distanceMeters;
      }
    });
  }

  void _stopTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Stop Tracking?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to stop tracking?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final tripProvider = context.read<TripProvider>();
              Navigator.pop(ctx);
              await tripProvider.stopTrip(cancel: true);
              if (mounted) nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Stop', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<TripProvider>(
          builder: (context, provider, _) {
            final tracking = provider.trackingData;
            final trip = provider.activeTrip;

            if (trip == null) {
              return const Center(child: Text('No active trip'));
            }

            // Trigger route refetch when position updates significantly
            if (tracking.currentPosition != null) {
              _fetchRouteIfNeeded();
            }

            return Stack(
              children: [
                // Map
                Positioned.fill(
                  child: MapWidget(
                    controller: _mapController,
                    center: tracking.currentPosition,
                    currentPosition: tracking.currentPosition,
                    destination: tracking.destination,
                    geofenceRadius: trip.destRadius,
                    showRoute: true,
                    zoom: _calculateZoom(tracking.distanceMeters),
                    routePoints: _routePoints,
                  ),
                ),

                Positioned(
                  right: 16,
                  bottom: 220,
                  child: _buildRecenterButton(tracking.currentPosition),
                ),

                // Top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(
                    trip.destinationName,
                    tracking.currentPosition,
                  ),
                ),

                // Bottom info panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildBottomPanel(tracking, provider),
                  ),
                ),

                // Alert indicator
                Positioned(
                  top: 80,
                  right: 16,
                  child: AlertLevelIndicator(
                    alertLevel: tracking.alertLevel,
                    size: 80,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecenterButton(LatLng? currentPosition) {
    return GestureDetector(
      onTap: () => _recenterToCurrent(currentPosition),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.my_location,
            color: AppColors.primary, size: 20),
      ),
    );
  }

  void _recenterToCurrent(LatLng? currentPosition) {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Current location unavailable'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final zoom = _mapController.camera.zoom == 0
        ? _calculateZoom(0)
        : _mapController.camera.zoom;
    _mapController.move(currentPosition, zoom);
  }

  Widget _buildTopBar(String destinationName, LatLng? currentPosition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withOpacity(0.95),
            AppColors.background.withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Active',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  destinationName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _openSearchAndStartTracking(currentPosition),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSearchAndStartTracking(LatLng? currentPosition) async {
    final result = await Navigator.push<Destination>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            SetDestinationScreen(currentPosition: currentPosition),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );

    if (result == null || !mounted) return;
    final success = await context.read<TripProvider>().startTrip(result);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Background location permission required'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      // Reset route state for new trip
      setState(() {
        _routePoints = null;
        _roadDistanceMeters = null;
        _lastRouteFetchPosition = null;
      });
      _fetchRouteIfNeeded();
    }
  }

  Widget _buildBottomPanel(tracking, TripProvider provider) {
    // Use road distance if available, otherwise haversine
    final displayDistance = _roadDistanceMeters ?? tracking.distanceMeters;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Distance indicator — shows road distance when available
          DistanceIndicator(
            distanceMeters: displayDistance,
            zone: tracking.zone,
          ),
          const SizedBox(height: 16),

          // Status card
          TrackingStatusCard(trackingData: tracking),
          const SizedBox(height: 16),

          if (provider.isAlarmRinging) ...[
            GestureDetector(
              onTap: () {
                provider.dismissAlarm();
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.warningGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Stop Alarm',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Stop button
          GestureDetector(
            onTap: () => _stopTrip(context),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.dangerGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Stop Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateZoom(double distanceMeters) {
    if (distanceMeters > 50000) return 8;
    if (distanceMeters > 10000) return 11;
    if (distanceMeters > 5000) return 12;
    if (distanceMeters > 2000) return 13;
    if (distanceMeters > 500) return 14;
    return 16;
  }
}
