import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../engines/distance_engine.dart';
import '../models/destination.dart';
import '../services/mapbox_service.dart';
import '../utils/constants.dart';
import '../widgets/map_widget.dart';

class SetDestinationScreen extends StatefulWidget {
  final LatLng? currentPosition;

  const SetDestinationScreen({super.key, this.currentPosition});

  @override
  State<SetDestinationScreen> createState() => _SetDestinationScreenState();
}

class _SearchResult {
  final String title;
  final String subtitle;
  final String? category;
  final LatLng position;
  final double? distanceMeters;

  const _SearchResult({
    required this.title,
    required this.subtitle,
    this.category,
    required this.position,
    this.distanceMeters,
  });
}

class _SetDestinationScreenState extends State<SetDestinationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<_SearchResult> _searchResults = [];
  bool _searching = false;
  LatLng? _selectedPosition;
  double _radius = 500;
  bool _showDetails = false;
  List<LatLng> _routePoints = [];
  double? _roadDistance;
  double? _roadDuration;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _fetchRoutePreview(LatLng dest) async {
    if (widget.currentPosition == null) return;
    final route = await MapboxService.getRoute(widget.currentPosition!, dest);
    if (mounted && _selectedPosition == dest) {
      setState(() {
        if (route != null) {
          _routePoints = route.points;
          _roadDistance = route.distanceMeters;
          _roadDuration = route.durationSeconds;
        } else {
          _routePoints = [widget.currentPosition!, dest];
        }
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = position;
      _showDetails = true;
      _routePoints = [];
      _roadDistance = null;
      _roadDuration = null;
      if (_nameController.text.isEmpty || _nameController.text == 'Selected Point') {
        _nameController.text = 'Selected Location';
      }
    });
    _fetchRoutePreview(position);
  }

  void _confirmDestination() {
    if (_selectedPosition == null) return;

    final name = _nameController.text.trim().isEmpty
        ? 'Destination'
        : _nameController.text.trim();

    final destination = Destination(
      id: const Uuid().v4(),
      name: name,
      latitude: _selectedPosition!.latitude,
      longitude: _selectedPosition!.longitude,
      radius: _radius,
    );

    Navigator.pop(context, destination);
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchLocations(query);
    });
  }

  Future<void> _searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);

    try {
      // 1. Try Photon API first for fuzzy autocomplete & proximity ranking
      final queryParams = <String, String>{
        'q': trimmed,
        'limit': '10',
      };
      if (widget.currentPosition != null) {
        queryParams['lat'] = widget.currentPosition!.latitude.toString();
        queryParams['lon'] = widget.currentPosition!.longitude.toString();
      }

      final photonUri = Uri.https('photon.komoot.io', '/api/', queryParams);
      final photonResponse = await http.get(
        photonUri,
        headers: {'User-Agent': 'StopAlert/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (photonResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(photonResponse.bodyBytes)) as Map<String, dynamic>;
        final features = data['features'] as List? ?? [];

        if (features.isNotEmpty) {
          final results = <_SearchResult>[];
          for (final f in features) {
            final geom = f['geometry'] as Map<String, dynamic>?;
            final coords = geom?['coordinates'] as List?;
            final props = f['properties'] as Map<String, dynamic>?;

            if (coords != null && coords.length >= 2 && props != null) {
              final lon = (coords[0] as num).toDouble();
              final lat = (coords[1] as num).toDouble();
              final pos = LatLng(lat, lon);

              final name = props['name']?.toString() ??
                  props['street']?.toString() ??
                  props['city']?.toString() ??
                  '';
              if (name.isEmpty) continue;

              final parts = <String>[];
              if (props['city'] != null && props['city'] != name) {
                parts.add(props['city'].toString());
              } else if (props['district'] != null && props['district'] != name) {
                parts.add(props['district'].toString());
              }
              if (props['state'] != null) parts.add(props['state'].toString());
              if (props['country'] != null) parts.add(props['country'].toString());
              final subtitle = parts.join(', ');

              final type = props['type']?.toString() ??
                  props['osm_key']?.toString() ??
                  props['osm_value']?.toString();

              double? dist;
              if (widget.currentPosition != null) {
                dist = DistanceEngine.calculateDistance(widget.currentPosition!, pos);
              }

              results.add(_SearchResult(
                title: name,
                subtitle: subtitle.isNotEmpty ? subtitle : 'Near your search',
                category: type,
                position: pos,
                distanceMeters: dist,
              ));
            }
          }

          if (results.isNotEmpty && mounted) {
            setState(() {
              _searchResults = results;
              _searching = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to Nominatim fallback
    }

    // Fallback to Nominatim if Photon has no results or errors
    try {
      final nominatimUri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': trimmed,
        'format': 'jsonv2',
        'limit': '6',
        'addressdetails': '1',
      });
      final nomResponse = await http.get(
        nominatimUri,
        headers: {'User-Agent': 'StopAlert/1.0 (stopalert app)'},
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (nomResponse.statusCode == 200) {
        final data = jsonDecode(nomResponse.body) as List;
        final results = <_SearchResult>[];
        for (final item in data) {
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          final title = item['name']?.toString() ?? item['display_name']?.toString() ?? '';
          if (lat == null || lon == null || title.isEmpty) continue;

          final pos = LatLng(lat, lon);
          double? dist;
          if (widget.currentPosition != null) {
            dist = DistanceEngine.calculateDistance(widget.currentPosition!, pos);
          }

          results.add(_SearchResult(
            title: title,
            subtitle: item['display_name']?.toString() ?? '',
            category: item['type']?.toString(),
            position: pos,
            distanceMeters: dist,
          ));
        }

        setState(() {
          _searchResults = results;
          _searching = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
    }
  }

  void _selectSearchResult(_SearchResult result) {
    setState(() {
      _selectedPosition = result.position;
      _nameController.text = result.title;
      _showDetails = true;
      _searchResults = [];
      _routePoints = [];
      _roadDistance = null;
      _roadDuration = null;
    });
    _searchFocus.unfocus();
    _mapController.move(result.position, 15);
    _fetchRoutePreview(result.position);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _searching = false;
    });
    _searchFocus.unfocus();
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.location_on_rounded;
    final cat = category.toLowerCase();
    if (cat.contains('station') || cat.contains('railway') || cat.contains('train')) {
      return Icons.train_rounded;
    }
    if (cat.contains('bus') || cat.contains('transit')) {
      return Icons.directions_bus_rounded;
    }
    if (cat.contains('aeroway') || cat.contains('airport') || cat.contains('flight')) {
      return Icons.flight_rounded;
    }
    if (cat.contains('hospital') || cat.contains('clinic') || cat.contains('pharmacy')) {
      return Icons.local_hospital_rounded;
    }
    if (cat.contains('restaurant') || cat.contains('food') || cat.contains('cafe')) {
      return Icons.restaurant_rounded;
    }
    if (cat.contains('school') || cat.contains('university') || cat.contains('college')) {
      return Icons.school_rounded;
    }
    if (cat.contains('hotel') || cat.contains('motel') || cat.contains('lodging')) {
      return Icons.hotel_rounded;
    }
    if (cat.contains('city') || cat.contains('town') || cat.contains('village') || cat.contains('suburb')) {
      return Icons.location_city_rounded;
    }
    return Icons.place_rounded;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Edge-to-edge Mapbox map
            Positioned.fill(
              child: MapWidget(
                controller: _mapController,
                center: widget.currentPosition,
                currentPosition: widget.currentPosition,
                destination: _selectedPosition,
                geofenceRadius: _selectedPosition != null ? _radius : null,
                zoom: widget.currentPosition != null ? 14 : 6,
                onTap: _onMapTap,
                showRoute: _selectedPosition != null && widget.currentPosition != null,
                routePoints: _routePoints.isNotEmpty ? _routePoints : null,
                isDarkMode: false,
              ),
            ),

            // Floating Search Bar
            Positioned(
              top: 68,
              left: 16,
              right: 16,
              child: _buildSearchBar(),
            ),

            // Autocomplete Results Panel
            if (_searchResults.isNotEmpty)
              Positioned(
                top: 130,
                left: 16,
                right: 16,
                child: _buildSearchResults(),
              ),

            // Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

            // Floating recenter button
            Positioned(
              right: 16,
              bottom: _showDetails ? 290 : 24,
              child: _buildRecenterButton(),
            ),

            // Map tap hint if no destination picked
            if (_selectedPosition == null && _searchResults.isEmpty)
              Positioned(
                bottom: 24,
                left: 24,
                right: 76,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Search a place or tap anywhere on the map',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Bottom details sheet
            if (_showDetails && _selectedPosition != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomSheet(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchFocus.hasFocus ? AppColors.primary : AppColors.borderLight,
          width: _searchFocus.hasFocus ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search city, station, hotel, street...',
          hintStyle: TextStyle(
            color: AppColors.textMuted.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _searchFocus.hasFocus ? AppColors.primary : AppColors.textMuted,
            size: 22,
          ),
          suffixIcon: _searching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : (_searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    )
                  : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 6),
            shrinkWrap: true,
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.borderLight.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return InkWell(
                onTap: () => _selectSearchResult(result),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(result.category),
                          color: AppColors.primary,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (result.distanceMeters != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDistance(result.distanceMeters!),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return GestureDetector(
      onTap: _recenterToCurrent,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  void _recenterToCurrent() {
    if (widget.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Current location unavailable'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    _mapController.move(widget.currentPosition!, 15);
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                border: Border.all(color: AppColors.borderLight, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Set Destination',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Destination title with pin
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : 'Selected Location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_selectedPosition!.latitude.toStringAsFixed(4)}, ${_selectedPosition!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Accurate road distance & ETA indicator
          if (_roadDistance != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${(_roadDistance! / 1000).toStringAsFixed(1)} km by road',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (_roadDuration != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ~${(_roadDuration! / 60).round()} min',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 14),

          // Rename field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Edit stop name (optional)...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Alert radius slider
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Wake-up Alert Radius',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_radius.toInt()} m',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _radius,
              min: 100,
              max: 2000,
              divisions: 19,
              onChanged: (value) {
                setState(() => _radius = value);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Start tracking button
          GestureDetector(
            onTap: _confirmDestination,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 16,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Start Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
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
}
