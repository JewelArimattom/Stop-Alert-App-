import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

class MapCacheService {
  static const String _cacheKey = 'stopalert_tiles';
  static final CacheManager _cacheManager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 4000,
    ),
  );

  static Future<void> initialize() async {
    // Cache manager is lazy-initialized; this keeps parity with other services.
  }

  static TileProvider get tileProvider => _CachedTileProvider(
        cacheManager: _cacheManager,
      );
}

class _CachedTileProvider extends TileProvider {
  final BaseCacheManager cacheManager;
  final bool silenceExceptions;

  _CachedTileProvider({
    required this.cacheManager,
    this.silenceExceptions = true,
    super.headers,
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _CachedTileImageProvider(
      url: getTileUrl(coordinates, options),
      headers: headers,
      cacheManager: cacheManager,
      silenceExceptions: silenceExceptions,
    );
  }
}

@immutable
class _CachedTileImageProvider extends ImageProvider<_CachedTileImageProvider> {
  final String url;
  final Map<String, String> headers;
  final BaseCacheManager cacheManager;
  final bool silenceExceptions;

  const _CachedTileImageProvider({
    required this.url,
    required this.headers,
    required this.cacheManager,
    required this.silenceExceptions,
  });

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1,
      debugLabel: url,
      informationCollector: () => [DiagnosticsProperty('URL', url)],
    );
  }

  Future<Codec> _loadAsync(
    _CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final file = await cacheManager.getSingleFile(url, headers: headers);
      final bytes = await file.readAsBytes();
      final buffer = await ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (err) {
      if (!silenceExceptions) rethrow;
      final buffer = await ImmutableBuffer.fromUint8List(
        TileProvider.transparentImage,
      );
      return decode(buffer);
    }
  }

  @override
  SynchronousFuture<_CachedTileImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _CachedTileImageProvider && url == other.url);

  @override
  int get hashCode => url.hashCode;
}
