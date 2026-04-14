import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/trip_provider.dart';
import '../utils/constants.dart';
import '../widgets/map_widget.dart';
import '../models/destination.dart';
import '../models/trip.dart';
import 'set_destination_screen.dart';
import 'tracking_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _loading = true;
  late AnimationController _fabController;
  late Animation<double> _fabScale;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _fabScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    _loadCurrentLocation();
    _startLocationPolling();
  }

  Future<void> _loadCurrentLocation() async {
    await _refreshCurrentLocation(recenter: true);
    if (!mounted) return;
    final provider = context.read<TripProvider>();
    if (provider.isTracking) {
      _navigateToTracking();
    }
  }

  void _startLocationPolling() {
    _locationTimer?.cancel();
    _locationTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      await _refreshCurrentLocation();
    });
  }

  Future<void> _refreshCurrentLocation({bool recenter = false}) async {
    final provider = context.read<TripProvider>();
    final pos = await provider.getCurrentLocation();
    if (!mounted) return;
    final shouldRecenter = recenter || (_currentPosition == null && pos != null);
    setState(() {
      _currentPosition = pos ?? _currentPosition;
      _loading = false;
    });
    if (shouldRecenter && pos != null) {
      final zoom = (_mapController.camera.zoom == 0
              ? 14
              : _mapController.camera.zoom)
          .toDouble();
      _mapController.move(pos, zoom);
    }
  }

  void _navigateToTracking() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TrackingScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _openDestinationSearch() async {
    final result = await Navigator.push<Destination>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            SetDestinationScreen(currentPosition: _currentPosition),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
    if (result != null && mounted) {
      _startQuickTrip(result);
    }
  }

  void _startQuickTrip(Destination destination) async {
    final provider = context.read<TripProvider>();
    final success = await provider.startTrip(destination);
    if (success && mounted) {
      _navigateToTracking();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission required'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(),

              // Map section
              Expanded(
                flex: 3,
                child: _buildMapSection(),
              ),

              // Recent trips
              Expanded(
                flex: 2,
                child: _buildRecentTripsSection(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_active_rounded,
              color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StopAlert',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Never miss your stop',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Search button
          _buildIconButton(Icons.search_rounded, () {
            _openDestinationSearch();
          }),
          const SizedBox(width: 8),
          // History button
          _buildIconButton(Icons.history_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          }),
          const SizedBox(width: 8),
          // Settings button
          _buildIconButton(Icons.settings_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildMapSection() {
    final provider = context.watch<TripProvider>();
    final displayPosition = provider.isTracking
        ? (provider.trackingData.currentPosition ?? _currentPosition)
        : _currentPosition;

    if (_loading && displayPosition == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            MapWidget(
              controller: _mapController,
              center: displayPosition,
              currentPosition: displayPosition,
              zoom: displayPosition != null ? 14 : 5,
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: _buildRecenterButton(),
            ),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: _recenterToCurrent,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.my_location,
            color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Future<void> _recenterToCurrent() async {
    final provider = context.read<TripProvider>();
    final trackedPosition = provider.isTracking
        ? provider.trackingData.currentPosition
        : null;

    // Recenter immediately using the best known location for a responsive tap.
    final immediateTarget = trackedPosition ?? _currentPosition;
    if (immediateTarget != null) {
      final zoom = (_mapController.camera.zoom == 0
              ? 14
              : _mapController.camera.zoom)
          .toDouble();
      _mapController.move(immediateTarget, zoom);
    }

    await _refreshCurrentLocation(recenter: true);

    if (!mounted) return;

    final latestTrackedPosition = provider.isTracking
        ? provider.trackingData.currentPosition
        : null;
    final target = latestTrackedPosition ?? _currentPosition;

    if (target == null) {
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

    final zoom = (_mapController.camera.zoom == 0
            ? 14
            : _mapController.camera.zoom)
        .toDouble();
    _mapController.move(target, zoom);
  }

  Widget _buildRecentTripsSection() {
    return Consumer<TripProvider>(
      builder: (context, provider, _) {
        final trips = provider.tripHistory;
        final activeTrip = provider.activeTrip;
        final nonActiveTrips = activeTrip == null
            ? trips
            : trips.where((trip) => trip.id != activeTrip.id).toList();
        final recentTrips = nonActiveTrips.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Trips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      );
                    },
                    child: Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: trips.isEmpty
                  ? _buildHistoryEmptyState()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (activeTrip != null)
                          _buildActiveTrackingCard(),
                        ...recentTrips.map(_buildRecentTripCard),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 48,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No trips yet',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start tracking and your trips will appear here',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTrackingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.navigation_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Active tracking in progress',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: _navigateToTracking,
            child: Text(
              'Open',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripCard(Trip trip) {
    final statusText = trip.status.name.toUpperCase();
    final isActive = trip.status.name == 'active';
    final statusColor = isActive
        ? AppColors.warning
        : trip.status.name == 'completed'
            ? AppColors.primary
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              trip.destinationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return ScaleTransition(
      scale: _fabScale,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openDestinationSearch,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}
