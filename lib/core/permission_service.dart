import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// OEM brand category — used to show device-specific autostart instructions.
enum OemBrand {
  xiaomi,   // MIUI / HyperOS — most aggressive killer
  huawei,   // EMUI / HarmonyOS
  oppo,     // ColorOS — includes Realme, OnePlus
  vivo,     // FuntouchOS / OriginOS
  samsung,  // One UI — moderate killer
  generic,  // Stock Android / unknown OEM — usually works without autostart
}

/// Handles Android-specific permissions and audio settings needed for reliable
/// alarm delivery. Operates ONLY on STREAM_ALARM — never touches notification
/// or ringtone volumes, so no OS settings are harmed.
class PermissionService {
  static const _channel =
      MethodChannel('com.example.siddha_kutumbakam_reminder/permissions');

  // Cache device info so we only query it once
  static Map<String, dynamic>? _deviceInfo;

  // ── Device Info ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_deviceInfo != null) return _deviceInfo!;
    if (!Platform.isAndroid) return {'brand': 'unknown', 'manufacturer': 'unknown', 'sdkInt': 0};
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      _deviceInfo = result ?? {};
      return _deviceInfo!;
    } catch (_) {
      return {'brand': 'unknown', 'manufacturer': 'unknown', 'sdkInt': 0};
    }
  }

  static Future<OemBrand> getOemBrand() async {
    final info = await getDeviceInfo();
    final brand = (info['brand'] as String? ?? '').toLowerCase();
    final mfr = (info['manufacturer'] as String? ?? '').toLowerCase();
    final combined = '$brand $mfr';
    if (combined.contains('xiaomi') || combined.contains('redmi') || combined.contains('poco')) {
      return OemBrand.xiaomi;
    }
    if (combined.contains('huawei') || combined.contains('honor')) return OemBrand.huawei;
    if (combined.contains('oppo') || combined.contains('realme') || combined.contains('oneplus')) {
      return OemBrand.oppo;
    }
    if (combined.contains('vivo')) return OemBrand.vivo;
    if (combined.contains('samsung')) return OemBrand.samsung;
    return OemBrand.generic;
  }

  /// Returns true if the device is an OEM that aggressively kills background apps.
  static Future<bool> isAggressiveOem() async {
    final brand = await getOemBrand();
    return brand != OemBrand.generic;
  }

  // ── Battery Optimization ────────────────────────────────────────────────────

  static Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestBatteryOptimizationExemption');
    } catch (_) {}
  }

  static Future<bool> isBatteryOptimizationExempt() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isBatteryOptimizationExempt') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Exact Alarm Permission ──────────────────────────────────────────────────

  static Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('canScheduleExactAlarms') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openExactAlarmSettings');
    } catch (_) {}
  }

  // ── OEM Autostart ───────────────────────────────────────────────────────────

  /// Tries to open the OEM-specific autostart / background permissions screen.
  /// Returns true if it was opened successfully.
  static Future<bool> openAutostartSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openAutostartSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Alarm Volume (STREAM_ALARM only) ───────────────────────────────────────

  static Future<int> getAlarmVolume() async {
    if (!Platform.isAndroid) return 7;
    try {
      return await _channel.invokeMethod<int>('getAlarmVolume') ?? 7;
    } catch (_) {
      return 7;
    }
  }

  static Future<int> getAlarmMaxVolume() async {
    if (!Platform.isAndroid) return 7;
    try {
      return await _channel.invokeMethod<int>('getAlarmMaxVolume') ?? 7;
    } catch (_) {
      return 7;
    }
  }

  static Future<void> setAlarmVolume(int volume) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setAlarmVolume', {'volume': volume});
    } catch (_) {}
  }

  static Future<void> openSoundSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openSoundSettings');
    } catch (_) {}
  }

  static Future<bool> isAlarmVolumeMuted() async {
    return (await getAlarmVolume()) == 0;
  }

  // ── Full Setup Check ────────────────────────────────────────────────────────

  /// Returns a map of which permissions/settings are correctly configured.
  static Future<AlarmSetupStatus> getSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final autostartFixed = prefs.getBool('autostart_fixed') ?? false;

    final results = await Future.wait([
      isBatteryOptimizationExempt(),
      canScheduleExactAlarms(),
      isAlarmVolumeMuted(),
      isAggressiveOem(),
      getOemBrand(),
    ]);
    return AlarmSetupStatus(
      batteryExempt: results[0] as bool,
      exactAlarmGranted: results[1] as bool,
      alarmVolumeMuted: results[2] as bool,
      isAggressiveOem: results[3] as bool,
      oemBrand: results[4] as OemBrand,
      autostartAcknowledged: autostartFixed,
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  static Future<bool> showBatteryOptimizationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PermissionDialog(
        icon: Icons.battery_full_rounded,
        iconColor: const Color(0xFF5E2A84),
        title: 'Keep Reminders Active',
        content:
            'To deliver reminders when your phone screen is off or the app is closed, '
            'allow this app to ignore battery restrictions.\n\n'
            'This uses the same system as your phone\'s built-in clock alarm.',
        confirmLabel: 'Allow',
        cancelLabel: 'Not Now',
      ),
    );
    if (result == true) {
      await requestBatteryOptimizationExemption();
      return true;
    }
    return false;
  }

  static Future<bool> showExactAlarmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PermissionDialog(
        icon: Icons.alarm_rounded,
        iconColor: const Color(0xFF5E2A84),
        title: 'Enable Precise Reminders',
        content:
            'Your device requires permission to schedule reminders at exact times.\n\n'
            'Please enable "Alarms & Reminders" for this app on the settings page that opens.',
        confirmLabel: 'Open Settings',
        cancelLabel: 'Skip',
      ),
    );
    if (result == true) {
      await openExactAlarmSettings();
      return true;
    }
    return false;
  }

  static Future<bool> showAlarmVolumeMutedDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _AlarmVolumeDialog(),
    );
    return result == true;
  }

  /// Shows OEM-specific autostart instructions.
  /// This is the most critical fix for Xiaomi, OPPO, Vivo, Huawei, Samsung.
  static Future<bool> showAutostartDialog(BuildContext context, OemBrand brand) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AutostartDialog(brand: brand),
    );
    if (result == true) {
      await openAutostartSettings();
      return true;
    }
    return false;
  }
}

// ── Data class for setup status ──────────────────────────────────────────────

class AlarmSetupStatus {
  final bool batteryExempt;
  final bool exactAlarmGranted;
  final bool alarmVolumeMuted;
  final bool isAggressiveOem;
  final OemBrand oemBrand;
  final bool autostartAcknowledged;

  const AlarmSetupStatus({
    required this.batteryExempt,
    required this.exactAlarmGranted,
    required this.alarmVolumeMuted,
    required this.isAggressiveOem,
    required this.oemBrand,
    required this.autostartAcknowledged,
  });

  /// True if all critical settings are correct for background alarm delivery.
  bool get isFullyConfigured =>
      batteryExempt && exactAlarmGranted && !alarmVolumeMuted &&
      (!isAggressiveOem || autostartAcknowledged);

  int get issueCount {
    int count = 0;
    if (!batteryExempt) count++;
    if (!exactAlarmGranted) count++;
    if (alarmVolumeMuted) count++;
    if (isAggressiveOem && !autostartAcknowledged) count++;
    return count;
  }
}

// ── Internal Widgets ─────────────────────────────────────────────────────────

class _PermissionDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;

  const _PermissionDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(icon, color: iconColor, size: 40),
      title: Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
      content: Text(content,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700], height: 1.5)),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5E2A84),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// OEM-specific autostart dialog with step-by-step instructions per brand.
class _AutostartDialog extends StatelessWidget {
  final OemBrand brand;
  const _AutostartDialog({required this.brand});

  String get _title => switch (brand) {
    OemBrand.xiaomi => 'Enable Autostart (Xiaomi)',
    OemBrand.huawei => 'Enable App Launch (Huawei)',
    OemBrand.oppo   => 'Enable Auto Launch (OPPO/Realme)',
    OemBrand.vivo   => 'Enable Background App (Vivo)',
    OemBrand.samsung => 'Disable Sleep (Samsung)',
    OemBrand.generic => 'Allow Background Activity',
  };

  String get _steps => switch (brand) {
    OemBrand.xiaomi =>
      '1. Tap "Open Settings" below\n'
      '2. Find this app in the list\n'
      '3. Enable "Autostart" toggle\n\n'
      'Also go to: Settings → Battery & Performance → App battery saver → This app → No restrictions',
    OemBrand.huawei =>
      '1. Tap "Open Settings" below\n'
      '2. Find this app in the list\n'
      '3. Enable "Allow auto-launch"\n\n'
      'Also go to: Settings → Battery → App launch → This app → Manage manually → Enable all',
    OemBrand.oppo =>
      '1. Tap "Open Settings" below\n'
      '2. Find this app in the list\n'
      '3. Enable "Allow auto-start"\n\n'
      'Also go to: Settings → Battery → Background App Management → This app → Allow',
    OemBrand.vivo =>
      '1. Tap "Open Settings" below\n'
      '2. Find this app in the Startup Manager\n'
      '3. Enable the toggle for this app\n\n'
      'Also go to: Settings → More Settings → Accessibility → This app → Enable',
    OemBrand.samsung =>
      '1. Tap "Open Settings" below\n'
      '2. Scroll to this app in the battery list\n'
      '3. Tap it and select "Unrestricted"\n\n'
      'Also: Settings → Apps → This app → Battery → Unrestricted',
    OemBrand.generic =>
      'Go to Settings → Apps → This app → Battery and set it to "Unrestricted" or "No restrictions".',
  };

  String get _icon => switch (brand) {
    OemBrand.xiaomi  => '🔴',
    OemBrand.huawei  => '🔵',
    OemBrand.oppo    => '🟢',
    OemBrand.vivo    => '🔵',
    OemBrand.samsung => '🔵',
    OemBrand.generic => '📱',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Text(_icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(_title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your phone brand aggressively closes apps in the background. '
            'Without Autostart permission, reminders WON\'T play when the app is closed.\n',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange[800], fontSize: 12.5, height: 1.4),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5E2A84).withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5E2A84).withAlpha(40)),
            ),
            child: Text(
              _steps,
              style: const TextStyle(fontSize: 13, height: 1.7),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Later'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5E2A84),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}

/// Alarm volume slider dialog — user adjusts volume without leaving the app.
class _AlarmVolumeDialog extends StatefulWidget {
  const _AlarmVolumeDialog();

  @override
  State<_AlarmVolumeDialog> createState() => _AlarmVolumeDialogState();
}

class _AlarmVolumeDialogState extends State<_AlarmVolumeDialog> {
  double _current = 0;
  double _max = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cur = await PermissionService.getAlarmVolume();
    final max = await PermissionService.getAlarmMaxVolume();
    if (mounted) {
      setState(() {
        _current = cur.toDouble();
        _max = max.toDouble();
        _loading = false;
      });
    }
  }

  IconData get _volumeIcon {
    if (_current == 0) return Icons.volume_off_rounded;
    if (_current < _max / 2) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(Icons.volume_off_rounded, color: Colors.orange[700], size: 40),
      title: const Text('Alarm Volume is Muted',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your reminder audio won\'t play because alarm volume is 0.\n'
            'Adjust it below — only alarm volume is changed, '
            'notifications and ringtone are NOT affected.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5E2A84)),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_volumeIcon,
                    color: _current == 0 ? Colors.grey : const Color(0xFF5E2A84), size: 22),
                const SizedBox(width: 8),
                Text(
                  _current == 0 ? 'Muted' : '${((_current / _max) * 100).round()}%',
                  style: TextStyle(
                    color: _current == 0 ? Colors.grey : const Color(0xFF5E2A84),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF5E2A84),
                thumbColor: const Color(0xFF5E2A84),
                inactiveTrackColor: const Color(0xFF5E2A84).withAlpha(51),
                overlayColor: const Color(0xFF5E2A84).withAlpha(26),
                trackHeight: 4,
              ),
              child: Slider(
                value: _current,
                min: 0,
                max: _max,
                divisions: _max.toInt(),
                onChanged: (v) async {
                  setState(() => _current = v);
                  await PermissionService.setAlarmVolume(v.round());
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Silent', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Text('Loud', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep Muted'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5E2A84),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          onPressed: _current > 0 ? () => Navigator.pop(context, true) : null,
          child: const Text('Done'),
        ),
      ],
    );
  }
}
