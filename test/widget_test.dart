import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_repeater/main.dart';
import 'package:wifi_repeater/wifi_platform.dart';
import 'package:wifi_repeater/wifi_status.dart';

void main() {
  testWidgets('shows the current Wi-Fi state and the guided workflow', (
    tester,
  ) async {
    final platform = FakeWifiPlatform(
      status: connectedStatus(wifiName: 'Home 5G'),
    );

    await tester.pumpWidget(MyApp(wifiPlatform: platform));
    await tester.pumpAndSettle();

    expect(find.text('ตัวช่วยแชร์ Wi-Fi'), findsOneWidget);
    expect(find.text('เชื่อมต่อแล้ว'), findsOneWidget);
    expect(find.text('Home 5G'), findsOneWidget);
    expect(find.text('อาจใช้งานพร้อมกันได้'), findsOneWidget);
    expect(find.text('ทำตาม 3 ขั้นตอน'), findsOneWidget);
    expect(platform.statusRequests, 1);
  });

  testWidgets('opens Wi-Fi and hotspot settings from the guide', (
    tester,
  ) async {
    final platform = FakeWifiPlatform(status: connectedStatus());
    await tester.pumpWidget(MyApp(wifiPlatform: platform));
    await tester.pumpAndSettle();

    final wifiButton = find.byKey(const Key('open_wifi_settings_button'));
    await bringIntoView(tester, wifiButton);
    await tester.tap(wifiButton);
    await tester.pump();
    expect(platform.wifiSettingsRequests, 1);

    final hotspotButton = find.byKey(const Key('open_hotspot_settings_button'));
    await bringIntoView(tester, hotspotButton);
    await tester.tap(hotspotButton);
    await tester.pump();
    expect(platform.hotspotSettingsRequests, 1);
  });

  testWidgets('warns when Android has not validated Wi-Fi internet', (
    tester,
  ) async {
    final platform = FakeWifiPlatform(
      status: connectedStatus(wifiName: 'Cafe', wifiHasInternet: false),
    );
    await tester.pumpWidget(MyApp(wifiPlatform: platform));
    await tester.pumpAndSettle();

    expect(find.text('เชื่อมต่อแล้ว แต่ยังไม่มีเน็ต'), findsOneWidget);
    expect(
      find.textContaining('ตรวจสอบหน้าเข้าสู่ระบบหรือเราเตอร์'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the workflow usable when SSID permission is denied', (
    tester,
  ) async {
    final platform = FakeWifiPlatform(
      status: connectedStatus(permissionGranted: false),
      permissionResult: false,
    );
    await tester.pumpWidget(MyApp(wifiPlatform: platform));
    await tester.pumpAndSettle();

    final permissionButton = find.byKey(const Key('request_permission_button'));
    expect(permissionButton, findsOneWidget);
    await bringIntoView(tester, permissionButton);
    await tester.tap(permissionButton);
    await tester.pumpAndSettle();

    expect(platform.permissionRequests, 1);
    expect(
      find.text('ยังไม่ได้รับอนุญาต แต่ยังทำขั้นตอนต่อไปได้'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('open_wifi_settings_button')), findsOneWidget);
  });

  testWidgets('shows a recoverable error when the status request fails', (
    tester,
  ) async {
    final platform = FakeWifiPlatform(
      status: connectedStatus(),
      statusError: StateError('unavailable'),
    );
    await tester.pumpWidget(MyApp(wifiPlatform: platform));
    await tester.pumpAndSettle();

    expect(find.text('ตรวจสอบสถานะไม่ได้'), findsOneWidget);

    platform.statusError = null;
    await tester.tap(find.byKey(const Key('retry_status_button')));
    await tester.pumpAndSettle();

    expect(find.text('เชื่อมต่อแล้ว'), findsOneWidget);
    expect(platform.statusRequests, 2);
  });
}

Future<void> bringIntoView(WidgetTester tester, Finder target) async {
  final scrollView = find.byType(CustomScrollView);
  for (var attempt = 0; attempt < 12; attempt += 1) {
    final center = tester.getCenter(target);
    if (center.dy >= 80 && center.dy <= 520) return;
    await tester.drag(scrollView, Offset(0, center.dy > 520 ? -280 : 280));
    await tester.pumpAndSettle();
  }
  fail('Could not bring the target widget into the test viewport.');
}

WifiStatus connectedStatus({
  String? wifiName,
  bool permissionGranted = true,
  bool? wifiHasInternet = true,
}) {
  return WifiStatus(
    wifiConnected: true,
    wifiEnabled: true,
    wifiName: wifiName,
    wifiHasInternet: wifiHasInternet,
    permissionGranted: permissionGranted,
    permissionNeeded: !permissionGranted,
    canOpenHotspotSettings: true,
    concurrentModeSupported: true,
    sdkInt: 35,
  );
}

class FakeWifiPlatform implements WifiPlatform {
  FakeWifiPlatform({
    required this.status,
    this.permissionResult = true,
    this.statusError,
  });

  WifiStatus status;
  bool permissionResult;
  Object? statusError;
  int statusRequests = 0;
  int permissionRequests = 0;
  int wifiSettingsRequests = 0;
  int hotspotSettingsRequests = 0;

  @override
  Future<WifiStatus> getStatus() async {
    statusRequests += 1;
    final error = statusError;
    if (error != null) throw error;
    return status;
  }

  @override
  Future<void> openHotspotSettings() async {
    hotspotSettingsRequests += 1;
  }

  @override
  Future<void> openWifiSettings() async {
    wifiSettingsRequests += 1;
  }

  @override
  Future<bool> requestWifiPermission() async {
    permissionRequests += 1;
    return permissionResult;
  }
}
