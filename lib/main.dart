import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'engines/background_engine.dart';
import 'services/map_cache_service.dart';
import 'providers/trip_provider.dart';
import 'providers/settings_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI style — light theme: dark icons on pearl white
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFFF5F7F2),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Initialize services
  await StorageService.initialize();
  await BackgroundEngine.initialize();
  await MapCacheService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      ],
      child: const StopAlertApp(),
    ),
  );
}
