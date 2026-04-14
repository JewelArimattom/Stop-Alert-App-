import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';

class StopAlertApp extends StatelessWidget {
  const StopAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StopAlert Premium',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
