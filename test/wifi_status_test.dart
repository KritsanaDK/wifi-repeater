import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_repeater/wifi_status.dart';

void main() {
  group('WifiStatus.fromMap', () {
    test('parses the Android bridge payload', () {
      final status = WifiStatus.fromMap(<Object?, Object?>{
        'wifiConnected': true,
        'wifiEnabled': true,
        'wifiName': 'Home 5G',
        'wifiHasInternet': true,
        'permissionGranted': true,
        'permissionNeeded': false,
        'canOpenHotspotSettings': true,
        'concurrentModeSupported': true,
        'sdkInt': 35,
      });

      expect(status.wifiConnected, isTrue);
      expect(status.wifiEnabled, isTrue);
      expect(status.visibleWifiName, 'Home 5G');
      expect(status.wifiHasInternet, isTrue);
      expect(status.permissionGranted, isTrue);
      expect(status.permissionNeeded, isFalse);
      expect(status.canOpenHotspotSettings, isTrue);
      expect(status.concurrentModeSupported, isTrue);
      expect(status.sdkInt, 35);
    });

    test('uses safe defaults for a partial payload', () {
      final status = WifiStatus.fromMap(<Object?, Object?>{
        'wifiEnabled': false,
      });

      expect(status.wifiConnected, isFalse);
      expect(status.wifiEnabled, isFalse);
      expect(status.visibleWifiName, isNull);
      expect(status.wifiHasInternet, isNull);
      expect(status.permissionGranted, isFalse);
      expect(status.permissionNeeded, isTrue);
      expect(status.canOpenHotspotSettings, isTrue);
      expect(status.concurrentModeSupported, isNull);
      expect(status.sdkInt, isNull);
    });

    test('accepts legacy aliases and numeric booleans', () {
      final status = WifiStatus.fromMap(<Object?, Object?>{
        'isWifiConnected': 1,
        'ssid': 'Cafe',
        'hasWifiPermission': 1,
        'supportsConcurrentWifiAndHotspot': 0,
      });

      expect(status.wifiConnected, isTrue);
      expect(status.visibleWifiName, 'Cafe');
      expect(status.permissionGranted, isTrue);
      expect(status.permissionNeeded, isFalse);
      expect(status.concurrentModeSupported, isFalse);
    });
  });

  group('WifiStatus.visibleWifiName', () {
    test('removes quotes added around an SSID', () {
      const status = WifiStatus(
        wifiConnected: true,
        wifiEnabled: true,
        wifiName: '"Home Wi-Fi"',
        permissionGranted: true,
        permissionNeeded: false,
        canOpenHotspotSettings: true,
      );

      expect(status.visibleWifiName, 'Home Wi-Fi');
    });

    test('preserves quotes that are part of the SSID', () {
      const status = WifiStatus(
        wifiConnected: true,
        wifiEnabled: true,
        wifiName: 'Cafe "Guest"',
        permissionGranted: true,
        permissionNeeded: false,
        canOpenHotspotSettings: true,
      );

      expect(status.visibleWifiName, 'Cafe "Guest"');
    });

    test('hides blank and unknown SSIDs', () {
      const blank = WifiStatus(
        wifiConnected: true,
        wifiEnabled: true,
        wifiName: '   ',
        permissionGranted: true,
        permissionNeeded: false,
        canOpenHotspotSettings: true,
      );
      const unknown = WifiStatus(
        wifiConnected: true,
        wifiEnabled: true,
        wifiName: '<unknown ssid>',
        permissionGranted: true,
        permissionNeeded: false,
        canOpenHotspotSettings: true,
      );

      expect(blank.visibleWifiName, isNull);
      expect(unknown.visibleWifiName, isNull);
    });
  });
}
