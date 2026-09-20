import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Service for Mapbox API interactions: tiles and directions.
class MapboxService {
  MapboxService._();

  /// Mapbox public access token (can be overridden via --dart-define=MAPBOX_ACCESS_TOKEN=...)
  static String get accessToken {
    const envToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
    if (envToken.isNotEmpty) return envToken;
    return utf8.decode(base64.decode(
      'cGsuZXlKMUlqb2lhbVYzWld3ek1ETWlMQ0poSWpvaVkyMTFPVzE0TnpWdU1IRjBaako1Y1haMlpIbDFjREZxWVNKOS45RXBvek82ZTNQZXE3VmFpWE55VHVB',
    ));
  }

  /// Mapbox raster tile URL template for flutter_map's TileLayer
  static String get tileUrlTemplate =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=$accessToken';

  // ─── Directions API ──────────────────────────────────────────────

  /// Fetch a driving route between [origin] and [destination].
  ///
  /// Returns a [MapboxRoute] with polyline points, distance, and duration.
  /// Returns `null` on failure (no connectivity, bad response, etc.).
  static Future<MapboxRoute?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?geometries=polyline6&overview=full&access_token=$accessToken',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('MapboxService: Directions API returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;

      if (routes == null || routes.isEmpty) {
        debugPrint('MapboxService: No routes returned');
        return null;
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as String?;
      final distance = (route['distance'] as num?)?.toDouble() ?? 0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 0;

      if (geometry == null) return null;

      final points = _decodePolyline6(geometry);

      if (points.isEmpty) return null;

      return MapboxRoute(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } catch (e) {
      debugPrint('MapboxService: Route fetch failed: $e');
      return null;
    }
  }

  // ─── Polyline Decoder (precision 6) ──────────────────────────────

  /// Decode an encoded polyline string with precision 6 (Mapbox default
  /// when `geometries=polyline6` is specified).
  static List<LatLng> _decodePolyline6(String encoded) {
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

      // Precision 6: divide by 1e6
      points.add(LatLng(lat / 1e6, lng / 1e6));
    }

    return points;
  }
}

/// A decoded Mapbox route.
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
