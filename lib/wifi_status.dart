/// A platform-neutral snapshot of the Android Wi-Fi state.
class WifiStatus {
  const WifiStatus({
    required this.wifiConnected,
    required this.wifiEnabled,
    required this.permissionGranted,
    required this.permissionNeeded,
    required this.canOpenHotspotSettings,
    this.wifiName,
    this.wifiHasInternet,
    this.concurrentModeSupported,
    this.sdkInt,
  });

  final bool wifiConnected;
  final bool wifiEnabled;
  final String? wifiName;

  /// Whether Android has validated internet access over the Wi-Fi network.
  /// `null` means that the platform could not determine it.
  final bool? wifiHasInternet;

  /// Optional permission used only to reveal the connected Wi-Fi name.
  final bool permissionGranted;
  final bool permissionNeeded;
  final bool canOpenHotspotSettings;

  /// Android's best-effort capability report. `null` means unknown.
  /// A `true` value still cannot guarantee Wi-Fi internet sharing.
  final bool? concurrentModeSupported;
  final int? sdkInt;

  String? get visibleWifiName {
    final value = wifiName?.trim();
    if (value == null ||
        value.isEmpty ||
        value.toLowerCase() == '<unknown ssid>') {
      return null;
    }
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  factory WifiStatus.fromMap(Map<Object?, Object?> map) {
    final permissionGranted = _bool(map, const [
      'permissionGranted',
      'hasWifiPermission',
    ], fallback: false);

    return WifiStatus(
      wifiConnected: _bool(map, const [
        'wifiConnected',
        'isWifiConnected',
      ], fallback: false),
      wifiEnabled: _bool(map, const ['wifiEnabled'], fallback: true),
      wifiName: _string(map, const ['wifiName', 'ssid']),
      wifiHasInternet: _nullableBool(map, const [
        'wifiHasInternet',
        'wifiInternetAvailable',
      ]),
      permissionGranted: permissionGranted,
      permissionNeeded: _bool(map, const [
        'permissionNeeded',
      ], fallback: !permissionGranted),
      canOpenHotspotSettings: _bool(map, const [
        'canOpenHotspotSettings',
      ], fallback: true),
      concurrentModeSupported: _nullableBool(map, const [
        'concurrentModeSupported',
        'supportsConcurrentWifiAndHotspot',
      ]),
      sdkInt: _int(map, const ['sdkInt']),
    );
  }

  static Object? _value(
    Map<Object?, Object?> map,
    Iterable<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      if (map.containsKey(key)) return map[key];
    }
    return null;
  }

  static bool _bool(
    Map<Object?, Object?> map,
    Iterable<String> keys, {
    required bool fallback,
  }) {
    return _nullableBool(map, keys) ?? fallback;
  }

  static bool? _nullableBool(Map<Object?, Object?> map, Iterable<String> keys) {
    final value = _value(map, keys);
    if (value is bool) return value;
    if (value is num) return value != 0;
    return null;
  }

  static String? _string(Map<Object?, Object?> map, Iterable<String> keys) {
    final value = _value(map, keys);
    return value is String ? value : null;
  }

  static int? _int(Map<Object?, Object?> map, Iterable<String> keys) {
    final value = _value(map, keys);
    return value is num ? value.toInt() : null;
  }
}
