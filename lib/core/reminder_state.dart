import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────
enum ScheduleMode { random, periodic }
enum NotificationMode { soundAndVibration, vibrationOnly, silent }
enum AppLanguage { english, hindi }

// ─── Pause Window ─────────────────────────────────────────────────────────────
class PauseWindow {
  final DateTime start;
  final DateTime end;
  const PauseWindow({required this.start, required this.end});

  bool isActive(DateTime now) =>
      !now.isBefore(start) && now.isBefore(end);

  Duration remainingTime(DateTime now) {
    if (!isActive(now)) return Duration.zero;
    return end.difference(now);
  }
}

// ─── Single Reminder Config ────────────────────────────────────────────────────
class ReminderConfig {
  bool enabled;
  ScheduleMode mode;
  int randomPerHour;      // for random mode (e.g. 6 times per hour)
  int periodicMinutes;    // for periodic mode in minutes (e.g. 10 minutes)
  List<PauseWindow> pauses;

  ReminderConfig({
    this.enabled = false,
    this.mode = ScheduleMode.random,
    this.randomPerHour = 6,
    this.periodicMinutes = 10,
    List<PauseWindow>? pauses,
  }) : pauses = pauses ?? [];

  bool isPaused(DateTime now) => pauses.any((p) => p.isActive(now));
}

// ─── App State (single source of truth, no DB) ────────────────────────────────
class AppState extends ChangeNotifier {
  // Reminders
  final exhale   = ReminderConfig();
  final tatastha = ReminderConfig();

  // Backward compatibility alias for taste
  ReminderConfig get taste => tatastha;

  // Master pause control (Pauses all reminders and sound)
  bool isMasterPaused = false;

  // Global meeting pause windows (applies to all reminders)
  final List<PauseWindow> meetingPauses = [];

  // Global settings
  NotificationMode notificationMode = NotificationMode.soundAndVibration;
  AppLanguage language = AppLanguage.english;

  // Night mode — don't run between these hours
  bool nightModeEnabled = true;
  int nightStartHour = 22; // 10 PM
  int nightEndHour   = 7;  // 7 AM

  // Background execution setting
  bool backgroundUsageAllowed = true;

  // Scheduler state
  Timer? _ticker;
  final Random _rng = Random();
  DateTime? _lastExhaleTime;
  DateTime? _lastTatasthaTime;

  // ── Init: load from SharedPrefs ─────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    isMasterPaused = prefs.getBool('master_paused') ?? false;
    backgroundUsageAllowed = prefs.getBool('bg_usage_allowed') ?? true;

    exhale.enabled         = prefs.getBool('exhale_enabled') ?? false;
    exhale.mode            = ScheduleMode.values[prefs.getInt('exhale_mode') ?? 0];
    exhale.randomPerHour   = prefs.getInt('exhale_per_hour') ?? 6;
    // Load periodicMinutes with backward compatibility
    if (prefs.containsKey('exhale_period_min')) {
      exhale.periodicMinutes = prefs.getInt('exhale_period_min') ?? 10;
    } else if (prefs.containsKey('exhale_period')) {
      final sec = prefs.getInt('exhale_period') ?? 600;
      exhale.periodicMinutes = (sec / 60).round().clamp(1, 1440);
    } else {
      exhale.periodicMinutes = 10;
    }

    tatastha.enabled       = prefs.getBool('tatastha_enabled') ??
        prefs.getBool('taste_enabled') ??
        false;
    tatastha.mode          = ScheduleMode.values[
        prefs.getInt('tatastha_mode') ?? prefs.getInt('taste_mode') ?? 0];
    tatastha.randomPerHour = prefs.getInt('tatastha_per_hour') ??
        prefs.getInt('taste_per_hour') ??
        6;
    if (prefs.containsKey('tatastha_period_min')) {
      tatastha.periodicMinutes = prefs.getInt('tatastha_period_min') ?? 10;
    } else if (prefs.containsKey('taste_period_min')) {
      tatastha.periodicMinutes = prefs.getInt('taste_period_min') ?? 10;
    } else if (prefs.containsKey('taste_period')) {
      final sec = prefs.getInt('taste_period') ?? 600;
      tatastha.periodicMinutes = (sec / 60).round().clamp(1, 1440);
    } else {
      tatastha.periodicMinutes = 10;
    }

    notificationMode = NotificationMode.values[prefs.getInt('notif_mode') ?? 0];
    language         = AppLanguage.values[prefs.getInt('language') ?? 0];
    nightModeEnabled = prefs.getBool('night_mode') ?? true;
    nightStartHour   = prefs.getInt('night_start') ?? 22;
    nightEndHour     = prefs.getInt('night_end') ?? 7;

    // Restore Meeting Pauses across reboots (Test 19)
    final storedMeetingPauses = prefs.getStringList('meeting_pauses') ?? [];
    final now = DateTime.now();
    meetingPauses.clear();
    for (final raw in storedMeetingPauses) {
      final parts = raw.split(':');
      if (parts.length == 2) {
        final start = DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[0]) ?? 0);
        final end = DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[1]) ?? 0);
        if (end.isAfter(now)) {
          meetingPauses.add(PauseWindow(start: start, end: end));
        }
      }
    }

    notifyListeners();
    _restartScheduler();
  }

  // ── Save to SharedPrefs ─────────────────────────────────────────────────────
  Future<void> save() => _save();

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('master_paused', isMasterPaused);
    await prefs.setBool('bg_usage_allowed', backgroundUsageAllowed);

    await prefs.setBool('exhale_enabled', exhale.enabled);
    await prefs.setInt('exhale_mode', exhale.mode.index);
    await prefs.setInt('exhale_per_hour', exhale.randomPerHour);
    await prefs.setInt('exhale_period_min', exhale.periodicMinutes);

    await prefs.setBool('tatastha_enabled', tatastha.enabled);
    await prefs.setInt('tatastha_mode', tatastha.mode.index);
    await prefs.setInt('tatastha_per_hour', tatastha.randomPerHour);
    await prefs.setInt('tatastha_period_min', tatastha.periodicMinutes);
    // Also store taste keys for backward compatibility
    await prefs.setBool('taste_enabled', tatastha.enabled);
    await prefs.setInt('taste_mode', tatastha.mode.index);

    await prefs.setInt('notif_mode', notificationMode.index);
    await prefs.setInt('language', language.index);
    await prefs.setBool('night_mode', nightModeEnabled);
    await prefs.setInt('night_start', nightStartHour);
    await prefs.setInt('night_end', nightEndHour);

    final meetingEntries = meetingPauses
        .map((p) => '${p.start.millisecondsSinceEpoch}:${p.end.millisecondsSinceEpoch}')
        .toList();
    await prefs.setStringList('meeting_pauses', meetingEntries);
  }

  // ── Setters ─────────────────────────────────────────────────────────────────
  void setBackgroundUsage(bool v) {
    backgroundUsageAllowed = v;
    _update();
  }

  void resumeAll() {
    isMasterPaused = false;
    meetingPauses.clear();
    // If night mode is active (e.g. user is testing/awake during night hours), disable night mode so reminders run
    if (isNightTime()) {
      nightModeEnabled = false;
    }
    _lastExhaleTime = DateTime.now();
    _lastTatasthaTime = DateTime.now();
    _update();
  }

  void pauseAll() {
    isMasterPaused = true;
    _update();
  }

  void toggleMasterPause() {
    if (isEffectivelyPaused()) {
      resumeAll();
    } else {
      pauseAll();
    }
  }

  void setMasterPaused(bool v) {
    isMasterPaused = v;
    if (!v) {
      _lastExhaleTime = DateTime.now();
      _lastTatasthaTime = DateTime.now();
    }
    _update();
  }

  void setEnabled(ReminderConfig c, bool v) {
    c.enabled = v;
    if (v) {
      if (identical(c, exhale)) {
        _lastExhaleTime = DateTime.now();
      } else {
        _lastTatasthaTime = DateTime.now();
      }
    }
    _update();
  }

  void setMode(ReminderConfig c, ScheduleMode m) {
    c.mode = m;
    if (identical(c, exhale)) {
      _lastExhaleTime = DateTime.now();
    } else {
      _lastTatasthaTime = DateTime.now();
    }
    _update();
  }

  void setRandomPerHour(ReminderConfig c, int v) {
    c.randomPerHour = v.clamp(1, 60);
    if (identical(c, exhale)) {
      _lastExhaleTime = DateTime.now();
    } else {
      _lastTatasthaTime = DateTime.now();
    }
    _update();
  }

  void setPeriodicMinutes(ReminderConfig c, int v) {
    c.periodicMinutes = v.clamp(1, 1440);
    if (identical(c, exhale)) {
      _lastExhaleTime = DateTime.now();
    } else {
      _lastTatasthaTime = DateTime.now();
    }
    _update();
  }

  // ── Meeting Pause Management ────────────────────────────────────────────────
  void pauseMeetingFor(Duration duration) {
    final now = DateTime.now();
    meetingPauses.add(PauseWindow(start: now, end: now.add(duration)));
    _update();
  }

  void addMeetingPause(DateTime s, DateTime e) {
    meetingPauses.add(PauseWindow(start: s, end: e));
    _update();
  }

  void removeMeetingPause(int index) {
    if (index >= 0 && index < meetingPauses.length) {
      meetingPauses.removeAt(index);
      _update();
    }
  }

  void clearMeetingPauses() {
    meetingPauses.clear();
    _update();
  }

  PauseWindow? get activeMeetingPause {
    final now = DateTime.now();
    for (final p in meetingPauses) {
      if (p.isActive(now)) return p;
    }
    return null;
  }

  bool get isMeetingPaused => activeMeetingPause != null;

  void addPause(ReminderConfig c, DateTime s, DateTime e) {
    c.pauses.add(PauseWindow(start: s, end: e));
    _update();
  }

  void removePause(ReminderConfig c, int i) {
    if (i >= 0 && i < c.pauses.length) {
      c.pauses.removeAt(i);
      _update();
    }
  }

  void setNotificationMode(NotificationMode m) {
    notificationMode = m;
    _update();
  }

  void setLanguage(AppLanguage l) {
    language = l;
    _update();
  }

  void setNightMode(bool v) {
    nightModeEnabled = v;
    _update();
  }

  void setNightHours(int start, int end) {
    nightStartHour = start;
    nightEndHour = end;
    _update();
  }

  void _update() {
    _save();
    _restartScheduler();
    notifyListeners();
  }

  // ── Active checks ───────────────────────────────────────────────────────────
  bool isNightTime([DateTime? time]) {
    if (!nightModeEnabled) return false;
    final now = time ?? DateTime.now();
    final h = now.hour;
    if (nightStartHour == nightEndHour) {
      // e.g. 0 to 0 (disabled) or full day
      return false;
    }
    if (nightStartHour > nightEndHour) {
      // crosses midnight e.g. 22–7
      return h >= nightStartHour || h < nightEndHour;
    }
    return h >= nightStartHour && h < nightEndHour;
  }

  bool isEffectivelyPaused() {
    if (isMasterPaused) return true;
    final now = DateTime.now();
    if (isNightTime(now)) return true;
    if (isMeetingPaused) return true;
    return false;
  }

  // ── Scheduler (fires callbacks when it's time to remind) ────────────────────
  VoidCallback? onExhale;
  VoidCallback? onTatastha;
  VoidCallback? onBothReminders;
  VoidCallback? get onTaste => onTatastha;
  set onTaste(VoidCallback? cb) => onTatastha = cb;

  void _restartScheduler() {
    _ticker?.cancel();
    _ticker = null;

    if (isMasterPaused) return;

    final hasActive = exhale.enabled || tatastha.enabled;
    if (!hasActive) return;

    // Initialize trigger times if not set
    final now = DateTime.now();
    _lastExhaleTime ??= now;
    _lastTatasthaTime ??= now;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = DateTime.now();

      // Check global suppressions
      if (isMasterPaused || isNightTime(current) || isMeetingPaused) {
        return;
      }

      final canExhale = exhale.enabled && !exhale.isPaused(current);
      final canTatastha = tatastha.enabled && !tatastha.isPaused(current);

      final shouldExhale = canExhale && _shouldTrigger(exhale, _lastExhaleTime, current);
      final shouldTatastha = canTatastha && _shouldTrigger(tatastha, _lastTatasthaTime, current);

      if (shouldExhale && shouldTatastha) {
        _lastExhaleTime = current;
        _lastTatasthaTime = current;
        if (onBothReminders != null) {
          onBothReminders!.call();
        } else {
          onExhale?.call();
          Future.delayed(const Duration(seconds: 4), () {
            if (!isEffectivelyPaused() && tatastha.enabled) {
              onTatastha?.call();
            }
          });
        }
      } else if (shouldExhale) {
        _lastExhaleTime = current;
        onExhale?.call();
      } else if (shouldTatastha) {
        _lastTatasthaTime = current;
        onTatastha?.call();
      }
    });
  }

  bool _shouldTrigger(ReminderConfig config, DateTime? lastTrigger, DateTime now) {
    if (lastTrigger == null) return true;

    if (config.mode == ScheduleMode.periodic) {
      final intervalMinutes = max(1, config.periodicMinutes);
      final elapsedSeconds = now.difference(lastTrigger).inSeconds;
      return elapsedSeconds >= (intervalMinutes * 60);
    } else {
      // Random mode: spread N triggers per hour across 3600 seconds
      // Minimum gap of 60 seconds between consecutive random triggers
      final elapsedSeconds = now.difference(lastTrigger).inSeconds;
      if (elapsedSeconds < 60) return false;

      // Guaranteed upper bound so it never starves (at most 2x average gap)
      final avgGapSeconds = 3600 / max(1, config.randomPerHour);
      if (elapsedSeconds >= (avgGapSeconds * 2)) {
        return true;
      }

      final prob = config.randomPerHour / 3600.0;
      return _rng.nextDouble() < prob;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
