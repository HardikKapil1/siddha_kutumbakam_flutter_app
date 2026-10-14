import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:vibration/vibration.dart';
import 'reminder_state.dart';

/// Battery-efficient event-driven notification manager with OS-level scheduled reminders.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static void Function(String action)? onAction;

  static Future<void> init({void Function(String action)? onNotificationAction}) async {
    if (_initialized) return;
    onAction = onNotificationAction;

    tz_data.initializeTimeZones();
    try {
      final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offsetMs) {
          tz.setLocalLocation(loc);
          break;
        }
      }
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final actionId = response.actionId ?? response.payload;
        if (actionId != null) {
          onAction?.call(actionId);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );
    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    final actionId = response.actionId ?? response.payload;
    if (actionId != null) {
      onAction?.call(actionId);
    }
  }

  static Future<bool?> requestPermission() async {
    return await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Trigger physical device vibration using the vibration hardware
  static Future<void> triggerVibration() async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        final hasCustom = await Vibration.hasCustomVibrationsSupport();
        if (hasCustom == true) {
          await Vibration.vibrate(pattern: [0, 400, 200, 400], intensities: [0, 255, 0, 255]);
        } else {
          await Vibration.vibrate(duration: 500);
        }
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Remove/dismiss the ongoing controller notification from status bar & shade
  static Future<void> cancelOngoingController() async {
    await _plugin.cancel(999);
  }

  /// Cancel all scheduled OS-level reminder events (IDs 1000..1500)
  static Future<void> cancelAllScheduledReminders() async {
    for (int i = 1000; i < 1500; i++) {
      await _plugin.cancel(i);
    }
  }

  /// Synchronize OS-level exact alarm reminder schedule for the next 24 hours.
  /// This allows the Flutter app to remain completely idle while the OS wakes for reminders.
  static Future<void> syncOSSchedule(
    AppState state, {
    required String exhaleTitle,
    required String exhaleBody,
    String? tatasthaTitle,
    String? tatasthaBody,
    String? tasteTitle,
    String? tasteBody,
  }) async {
    // 1. Cancel previous schedule slots
    await cancelAllScheduledReminders();

    if (!state.backgroundUsageAllowed || state.isEffectivelyPaused()) {
      return;
    }

    final now = DateTime.now();
    int notifId = 1000;

    bool isTimeEligible(DateTime t) {
      if (t.isBefore(now)) return false;
      if (state.isNightTime(t)) return false;
      for (final p in state.meetingPauses) {
        if (p.isActive(t)) return false;
      }
      return true;
    }

    // Collect all times for both reminders so we can enforce no-overlap gaps
    final List<_ScheduledEvent> allEvents = [];

    // ── Gather Exhale times ──────────────────────────────────────────────────
    if (state.exhale.enabled) {
      final times = _generateScheduleTimes(state.exhale, now);
      for (final t in times) {
        if (isTimeEligible(t) && notifId < 1250) {
          allEvents.add(_ScheduledEvent(
            id: notifId++,
            time: t,
            title: exhaleTitle,
            body: exhaleBody,
            soundAsset: 'exhale', // raw resource name (no extension)
            mode: state.notificationMode,
          ));
        }
      }
    }

    // ── Gather Tatastha times ────────────────────────────────────────────────
    final finalTatasthaTitle = tatasthaTitle ?? tasteTitle ?? 'Tatastha';
    final finalTatasthaBody  = tatasthaBody  ?? tasteBody  ?? 'Mindful witness reminder';

    if (state.tatastha.enabled) {
      final times = _generateScheduleTimes(state.tatastha, now);
      for (final t in times) {
        if (isTimeEligible(t) && notifId < 1500) {
          // Enforce minimum gap from any existing event at the same second
          final minGapSec = (state.exhale.periodicSeconds < 60 || state.tatastha.periodicSeconds < 60) ? 3 : 35;
          DateTime adjusted = t;
          while (allEvents.any((e) => e.time.difference(adjusted).abs().inSeconds < minGapSec)) {
            adjusted = adjusted.add(Duration(seconds: minGapSec));
          }
          allEvents.add(_ScheduledEvent(
            id: notifId++,
            time: adjusted,
            title: finalTatasthaTitle,
            body: finalTatasthaBody,
            soundAsset: 'tatastha', // raw resource name (no extension)
            mode: state.notificationMode,
          ));
        }
      }
    }

    // ── Schedule all events with OS ──────────────────────────────────────────
    for (final event in allEvents) {
      await _scheduleZonedReminder(
        id: event.id,
        scheduledDate: event.time,
        title: event.title,
        body: event.body,
        mode: event.mode,
        soundAsset: event.soundAsset,
      );
    }
  }


  static List<DateTime> _generateScheduleTimes(ReminderConfig config, DateTime now) {
    final List<DateTime> results = [];
    final Random rng = Random();

    if (config.mode == ScheduleMode.periodic) {
      final sec = config.periodicSeconds > 0 ? config.periodicSeconds : 600;
      if (sec < 60) {
        // Fast test mode: schedule slots every `sec` seconds for the next 3 minutes
        DateTime next = now.add(Duration(seconds: sec));
        final limit = now.add(const Duration(minutes: 3));
        int count = 0;
        while (next.isBefore(limit) && count < 36) {
          results.add(next);
          next = next.add(Duration(seconds: sec));
          count++;
        }
      } else {
        final intervalMinutes = max(1, (sec / 60).round());
        // Generate up to 24 hours of periodic slots (up to 96 occurrences)
        DateTime next = now.add(Duration(minutes: intervalMinutes));
        final limit = now.add(const Duration(hours: 24));
        int count = 0;
        while (next.isBefore(limit) && count < 96) {
          results.add(next);
          next = next.add(Duration(minutes: intervalMinutes));
          count++;
        }
      }
    } else {
      // Random scheduling: distribute N random reminders per hour for the next 24 hours
      final int perHour = config.randomPerHour.clamp(1, 12);
      for (int h = 0; h < 24; h++) {
        final hourStart = DateTime(now.year, now.month, now.day, now.hour).add(Duration(hours: h));
        final List<int> minuteOffsets = [];
        while (minuteOffsets.length < perHour) {
          final m = rng.nextInt(56) + 2;
          if (!minuteOffsets.any((existing) => (existing - m).abs() < 4)) {
            minuteOffsets.add(m);
          }
        }
        minuteOffsets.sort();
        for (final m in minuteOffsets) {
          final t = hourStart.add(Duration(minutes: m));
          if (t.isAfter(now)) {
            results.add(t);
          }
        }
      }
    }
    return results;
  }

  // soundAsset: raw resource name without extension, e.g. 'exhale' or 'tatastha'
  static Future<void> _scheduleZonedReminder({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
    required NotificationMode mode,
    String soundAsset = 'exhale',
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    // Each sound asset gets its own alarm channel so Android OS plays distinct sounds
    final soundChannelId = 'sk_alarm_${soundAsset}_v10';
    final soundChannelName = '${soundAsset[0].toUpperCase()}${soundAsset.substring(1)} Alarm Reminders';

    AndroidNotificationDetails androidDetails;
    switch (mode) {
      case NotificationMode.silent:
        androidDetails = const AndroidNotificationDetails(
          'sk_silent_v10',
          'Silent Reminders',
          channelDescription: 'Silent pop-up reminders without vibration or sound',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          silent: true,
        );
        break;
      case NotificationMode.vibrationOnly:
        androidDetails = AndroidNotificationDetails(
          'sk_vibrate_v10',
          'Vibration Reminders',
          channelDescription: 'Vibration only reminders without audio',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
          category: AndroidNotificationCategory.alarm,
        );
        break;
      case NotificationMode.soundAndVibration:
        // Native AlarmClock system integration: plays raw sound resource on alarm stream,
        // wakes screen, and bypasses system Doze / silent modes even when app is killed.
        androidDetails = AndroidNotificationDetails(
          soundChannelId,
          soundChannelName,
          channelDescription: 'Native System Alarm Mindful Reminder',
          importance: Importance.max,   // HEADS-UP display wakes screen
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound(soundAsset),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
        );
        break;
    }

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: mode == NotificationMode.soundAndVibration,
        presentBadge: false,
        sound: mode == NotificationMode.soundAndVibration ? '$soundAsset.mp3' : null,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            tzDate,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (_) {}
      }
    }
  }

  /// Persistent Spotify-style ongoing controller notification pinned on status bar & lockscreen
  static Future<void> updateOngoingController({
    required String title,
    required String subtitle,
    required bool isPaused,
    bool isPlaying = false,
    required NotificationMode mode,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'sk_controller_v10',
      'Mindful Reminders Controller',
      channelDescription: 'Ongoing controller for mindful reminders with pause/resume actions',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: !isPaused,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      actions: <AndroidNotificationAction>[
        if (!isPaused)
          const AndroidNotificationAction(
            'pause',
            '▶ Pause',
            showsUserInterface: true,
            cancelNotification: false,
          )
        else
          const AndroidNotificationAction(
            'resume',
            '⏸ Resume',
            showsUserInterface: true,
            cancelNotification: false,
          ),
      ],
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentSound: false,
        presentBadge: false,
      ),
    );

    await _plugin.show(
      999, // Fixed persistent ID
      title,
      subtitle,
      details,
      payload: isPaused ? 'resume' : 'pause',
    );
  }

  /// Send an immediate reminder notification based on current settings.
  static Future<void> showReminder({
    required String title,
    required String body,
    required NotificationMode mode,
  }) async {
    AndroidNotificationDetails androidDetails;

    switch (mode) {
      case NotificationMode.silent:
        androidDetails = const AndroidNotificationDetails(
          'sk_silent_sync_v10',
          'Silent Reminders',
          channelDescription: 'Silent pop-up reminders without vibration or sound',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          silent: true,
        );
        break;
      case NotificationMode.vibrationOnly:
        androidDetails = AndroidNotificationDetails(
          'sk_vibrate_sync_v10',
          'Vibration Reminders',
          channelDescription: 'Vibration only reminders without audio',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400, 200, 400]),
        );
        triggerVibration();
        break;
      case NotificationMode.soundAndVibration:
        androidDetails = AndroidNotificationDetails(
          'sk_sound_sync_v10',
          'Sound Reminders',
          channelDescription: 'Sound only mindful reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: false,
        );
        break;
    }

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: mode == NotificationMode.soundAndVibration,
        presentBadge: false,
      ),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<void> scheduleTestAlarm(DateTime scheduledDate) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final androidDetails = AndroidNotificationDetails(
      'sk_alarm_exhale_v10',
      'Exhale Alarm Reminders',
      channelDescription: 'Native System Alarm Mindful Reminder',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('exhale'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentSound: true,
        presentBadge: false,
        sound: 'exhale.mp3',
      ),
    );

    try {
      await _plugin.zonedSchedule(
        9999, // test ID
        'Test Alarm ✅',
        'Your setup is correct! Alarms will work when the app is closed.',
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } catch (_) {}
  }
}

// Helper class for gap-enforcement between scheduled events
class _ScheduledEvent {
  final int id;
  final DateTime time;
  final String title;
  final String body;
  final String soundAsset;
  final NotificationMode mode;
  const _ScheduledEvent({
    required this.id,
    required this.time,
    required this.title,
    required this.body,
    required this.soundAsset,
    required this.mode,
  });
}
