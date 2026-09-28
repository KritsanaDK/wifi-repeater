import 'package:flutter/material.dart';

import '../wifi_status.dart';
import 'error_message.dart';

class StatusSection extends StatelessWidget {
  const StatusSection({
    super.key,
    required this.status,
    required this.error,
    required this.loading,
    required this.onRetry,
  });

  final WifiStatus? status;
  final Object? error;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == null && loading) return const _StatusLoadingCard();
    if (status == null && error != null) {
      return _StatusErrorCard(error: error!, onRetry: onRetry);
    }
    final currentStatus = status;
    if (currentStatus == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          _InlineError(onRetry: onRetry),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final connection = _ConnectionCard(status: currentStatus);
            final capability = _CapabilityCard(status: currentStatus);
            if (constraints.maxWidth < 560) {
              return Column(
                children: [connection, const SizedBox(height: 12), capability],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: connection),
                  const SizedBox(width: 12),
                  Expanded(child: capability),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.tertiaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: colors.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ดูชื่อ Wi-Fi (ไม่บังคับ)',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onTertiaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Android จัดชื่อ Wi-Fi เป็นข้อมูลที่เกี่ยวข้องกับตำแหน่ง จึงต้องขอสิทธิ์ตำแหน่ง แอปใช้สิทธิ์นี้เพื่อแสดงชื่อเครือข่ายเท่านั้น',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onTertiaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('request_permission_button'),
              onPressed: loading ? null : onPressed,
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('อนุญาตเพื่อดูชื่อ Wi-Fi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.status});

  final WifiStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    late final String title;
    late final String description;
    late final IconData icon;
    late final Color accent;

    if (status.wifiConnected && status.wifiHasInternet == false) {
      title = 'เชื่อมต่อแล้ว แต่ยังไม่มีเน็ต';
      description =
          '${status.visibleWifiName ?? 'เครือข่าย Wi-Fi'} • ตรวจสอบหน้าเข้าสู่ระบบหรือเราเตอร์';
      icon = Icons.wifi_find_rounded;
      accent = const Color(0xFF9A5A00);
    } else if (status.wifiConnected) {
      title = 'เชื่อมต่อแล้ว';
      description =
          status.visibleWifiName ??
          (status.permissionNeeded && !status.permissionGranted
              ? 'อนุญาตสิทธิ์ด้านล่าง หากต้องการดูชื่อเครือข่าย'
              : 'เชื่อมต่อกับเครือข่าย Wi-Fi');
      icon = Icons.wifi_rounded;
      accent = const Color(0xFF16794A);
    } else if (!status.wifiEnabled) {
      title = 'Wi-Fi ปิดอยู่';
      description = 'เปิด Wi-Fi และเลือกเครือข่ายต้นทาง';
      icon = Icons.wifi_off_rounded;
      accent = colors.error;
    } else {
      title = 'ยังไม่เชื่อมต่อ';
      description = 'เลือกเครือข่าย Wi-Fi ต้นทางก่อน';
      icon = Icons.wifi_find_rounded;
      accent = colors.error;
    }

    return _InfoCard(
      eyebrow: 'การเชื่อมต่อ',
      title: title,
      description: description,
      icon: icon,
      accent: accent,
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({required this.status});

  final WifiStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final supported = status.concurrentModeSupported;
    late final String title;
    late final String description;
    late final IconData icon;
    late final Color accent;

    if (supported == true) {
      title = 'อาจใช้งานพร้อมกันได้';
      description = 'ฮาร์ดแวร์รองรับ แต่ Android ยังเป็นผู้ตัดสิน';
      icon = Icons.device_hub_rounded;
      accent = const Color(0xFF16794A);
    } else if (supported == false) {
      title = 'ไม่รองรับโหมดพร้อมกัน';
      description = 'เครื่องอาจตัด Wi-Fi เมื่อเปิดฮอตสปอต';
      icon = Icons.link_off_rounded;
      accent = colors.error;
    } else {
      title = 'ขึ้นอยู่กับอุปกรณ์';
      description = status.sdkInt == null
          ? 'Android ไม่เปิดเผยความสามารถนี้อย่างแน่นอน'
          : 'Android API ${status.sdkInt} • ต้องทดลองในหน้าตั้งค่า';
      icon = Icons.help_outline_rounded;
      accent = colors.tertiary;
    }

    return _InfoCard(
      eyebrow: 'Wi-Fi + ฮอตสปอต',
      title: title,
      description: description,
      icon: icon,
      accent: accent,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    eyebrow,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLoadingCard extends StatelessWidget {
  const _StatusLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('กำลังตรวจสอบสถานะอุปกรณ์…')),
          ],
        ),
      ),
    );
  }
}

class _StatusErrorCard extends StatelessWidget {
  const _StatusErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 30),
            const SizedBox(height: 10),
            Text(
              'ตรวจสอบสถานะไม่ได้',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              friendlyWifiError(error),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('retry_status_button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(Icons.sync_problem_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'อัปเดตสถานะไม่สำเร็จ',
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
          ],
        ),
      ),
    );
  }
}
