import 'package:flutter/material.dart';

import 'src/dashboard_components.dart';
import 'src/error_message.dart';
import 'src/status_section.dart';
import 'wifi_platform.dart';
import 'wifi_status.dart';

class WifiDashboard extends StatefulWidget {
  const WifiDashboard({super.key, required this.wifiPlatform});

  final WifiPlatform wifiPlatform;

  @override
  State<WifiDashboard> createState() => _WifiDashboardState();
}

enum _DashboardAction { permission, wifiSettings, hotspotSettings }

class _WifiDashboardState extends State<WifiDashboard>
    with WidgetsBindingObserver {
  WifiStatus? _status;
  Object? _statusError;
  bool _isRefreshing = false;
  _DashboardAction? _activeAction;
  int _requestNumber = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void didUpdateWidget(covariant WifiDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wifiPlatform != widget.wifiPlatform) _refreshStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final requestNumber = ++_requestNumber;
    setState(() {
      _isRefreshing = true;
      _statusError = null;
    });

    try {
      final status = await widget.wifiPlatform.getStatus();
      if (!mounted || requestNumber != _requestNumber) return;
      setState(() {
        _status = status;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted || requestNumber != _requestNumber) return;
      setState(() {
        _statusError = error;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    if (_activeAction != null) return;
    setState(() => _activeAction = _DashboardAction.permission);
    try {
      final granted = await widget.wifiPlatform.requestWifiPermission();
      if (!mounted) return;
      if (!granted) {
        _showMessage('ยังไม่ได้รับอนุญาต แต่ยังทำขั้นตอนต่อไปได้');
      }
      await _refreshStatus();
    } catch (error) {
      if (mounted) _showMessage(friendlyWifiError(error));
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _openWifiSettings() {
    return _runSettingsAction(
      _DashboardAction.wifiSettings,
      widget.wifiPlatform.openWifiSettings,
    );
  }

  Future<void> _openHotspotSettings() {
    return _runSettingsAction(
      _DashboardAction.hotspotSettings,
      widget.wifiPlatform.openHotspotSettings,
    );
  }

  Future<void> _runSettingsAction(
    _DashboardAction action,
    Future<void> Function() callback,
  ) async {
    if (_activeAction != null) return;
    setState(() => _activeAction = action);
    try {
      await callback();
    } catch (error) {
      if (mounted) _showMessage(friendlyWifiError(error));
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ตัวช่วยแชร์ Wi-Fi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshStatus,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const IntroCard(),
                          const SizedBox(height: 24),
                          SectionHeader(
                            title: 'สถานะอุปกรณ์',
                            trailing: IconButton.filledTonal(
                              key: const Key('refresh_status_button'),
                              tooltip: 'ตรวจสอบสถานะอีกครั้ง',
                              onPressed: _isRefreshing ? null : _refreshStatus,
                              icon: _isRefreshing
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          StatusSection(
                            status: _status,
                            error: _statusError,
                            loading: _isRefreshing,
                            onRetry: _refreshStatus,
                          ),
                          if (_needsPermission) ...[
                            const SizedBox(height: 12),
                            PermissionCard(
                              loading:
                                  _activeAction == _DashboardAction.permission,
                              onPressed: _requestPermission,
                            ),
                          ],
                          const SizedBox(height: 28),
                          const SectionHeader(title: 'ทำตาม 3 ขั้นตอน'),
                          const SizedBox(height: 12),
                          _buildSteps(),
                          const SizedBox(height: 20),
                          const LimitationNotice(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSteps() {
    return Column(
      children: [
        StepCard(
          number: 1,
          icon: Icons.wifi_rounded,
          title: 'เชื่อมต่อ Wi-Fi ต้นทาง',
          description:
              'เลือกเครือข่ายที่ต้องการรับอินเทอร์เน็ต แล้วกลับมาที่แอปนี้',
          action: OutlinedButton.icon(
            key: const Key('open_wifi_settings_button'),
            onPressed: _activeAction == null ? _openWifiSettings : null,
            icon: _actionIcon(
              _DashboardAction.wifiSettings,
              Icons.settings_rounded,
            ),
            label: const Text('เปิดการตั้งค่า Wi-Fi'),
          ),
        ),
        const SizedBox(height: 12),
        StepCard(
          number: 2,
          icon: Icons.fact_check_outlined,
          title: 'ตรวจสอบการเชื่อมต่อ',
          description:
              'กลับมาดูสถานะด้านบนให้ขึ้นว่าเชื่อมต่อแล้ว ก่อนเปิดฮอตสปอต',
          action: TextButton.icon(
            key: const Key('step_refresh_button'),
            onPressed: _isRefreshing ? null : _refreshStatus,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('ตรวจสอบอีกครั้ง'),
          ),
        ),
        const SizedBox(height: 12),
        StepCard(
          number: 3,
          icon: Icons.cell_tower_rounded,
          title: 'เปิดฮอตสปอตในระบบ',
          description:
              'เปิด Mobile Hotspot ด้วยตัวเอง แล้วดูว่า Android ยังคงเชื่อมต่อ Wi-Fi อยู่หรือไม่',
          action: FilledButton.icon(
            key: const Key('open_hotspot_settings_button'),
            onPressed: _canOpenHotspotSettings && _activeAction == null
                ? _openHotspotSettings
                : null,
            icon: _actionIcon(
              _DashboardAction.hotspotSettings,
              Icons.open_in_new_rounded,
            ),
            label: const Text('เปิดการตั้งค่าฮอตสปอต'),
          ),
        ),
      ],
    );
  }

  bool get _needsPermission {
    final status = _status;
    return status != null &&
        status.permissionNeeded &&
        !status.permissionGranted;
  }

  bool get _canOpenHotspotSettings => _status?.canOpenHotspotSettings ?? true;

  Widget _actionIcon(_DashboardAction action, IconData icon) {
    if (_activeAction != action) return Icon(icon);
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
