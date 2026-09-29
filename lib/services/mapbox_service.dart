import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Service for map API interactions: OSM tiles and OSRM directions.
/// All APIs used are completely free and require no API key.
class MapboxService {
  MapboxService._();

  /// Free OpenStreetMap tile URL (OSM France community mirror).
  /// No API key required, no watermarks, reliable CDN.
  static String get tileUrlTemplate =>
      'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png';

  /// Subdomains for tile load balancing
  static List<String> get tileSubdomains => const ['a', 'b', 'c'];

  // ─── Directions API (OSRM – free, no key) ────────────────────────

  /// Fetch a driving route between [origin] and [destination]
  /// using the OSRM public routing API.
  ///
  /// Returns a [MapboxRoute] with polyline points, distance, and duration.
  /// Returns `null` on failure (no connectivity, bad response, etc.).
  static Future<MapboxRoute?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('MapService: OSRM API returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;

      if (routes == null || routes.isEmpty) {
        debugPrint('MapService: No routes returned');
        return null;
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as String?;
      final distance = (route['distance'] as num?)?.toDouble() ?? 0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 0;

      if (geometry == null) return null;

      // OSRM uses standard polyline encoding (precision 5)
      final points = _decodePolyline5(geometry);

      if (points.isEmpty) return null;

      return MapboxRoute(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } catch (e) {
      debugPrint('MapService: Route fetch failed: $e');
      return null;
    }
  }

  // ─── Polyline Decoder (precision 5 – standard Google/OSRM) ───────

  /// Decode an encoded polyline string with precision 5 (standard encoding
  /// used by Google Maps, OSRM, and most routing services).
  static List<LatLng> _decodePolyline5(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Precision 5: divide by 1e5
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

/// A decoded route.
class MapboxRoute {
  /// The list of LatLng points forming the route polyline.
  final List<LatLng> points;

  /// The road distance in meters.
  final double distanceMeters;

  /// The estimated drive duration in seconds.
  final double durationSeconds;

  const MapboxRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}
