import 'package:flutter/material.dart';

import 'wifi_dashboard.dart';
import 'wifi_platform.dart';

void main() {
  runApp(const MyApp());
}

/// Application root with an injectable platform implementation for tests.
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.wifiPlatform});

  final WifiPlatform? wifiPlatform;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF315EFB);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF8F9FD),
    );

    return MaterialApp(
      title: 'ตัวช่วยแชร์ Wi-Fi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: colorScheme.surfaceTint,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: colorScheme.surfaceContainerLowest,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: WifiDashboard(
        wifiPlatform: wifiPlatform ?? const MethodChannelWifiPlatform(),
      ),
    );
  }
}
