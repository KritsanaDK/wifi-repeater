import 'package:flutter/services.dart';

import 'wifi_status.dart';

/// Operations the dashboard needs from its Android host.
abstract interface class WifiPlatform {
  Future<WifiStatus> getStatus();

  Future<bool> requestWifiPermission();

  Future<void> openWifiSettings();

  Future<void> openHotspotSettings();
}

/// Android implementation backed by the app's single method channel.
class MethodChannelWifiPlatform implements WifiPlatform {
  const MethodChannelWifiPlatform([
    this._channel = const MethodChannel(channelName),
  ]);

  static const channelName = 'com.example.wifi_repeater/wifi';

  final MethodChannel _channel;

  @override
  Future<WifiStatus> getStatus() async {
    final result = await _channel.invokeMethod<Object?>('getStatus');
    if (result is! Map) {
      throw PlatformException(
        code: 'invalid_status',
        message: 'Android returned an invalid Wi-Fi status.',
      );
    }
    return WifiStatus.fromMap(Map<Object?, Object?>.from(result));
  }

  @override
  Future<bool> requestWifiPermission() async {
    final result = await _channel.invokeMethod<Object?>(
      'requestWifiPermission',
    );
    if (result is bool) return result;
    if (result is Map) {
      return result['granted'] == true || result['permissionGranted'] == true;
    }
    return false;
  }

  @override
  Future<void> openWifiSettings() {
    return _channel.invokeMethod<void>('openWifiSettings');
  }

  @override
  Future<void> openHotspotSettings() {
    return _channel.invokeMethod<void>('openHotspotSettings');
  }
}
