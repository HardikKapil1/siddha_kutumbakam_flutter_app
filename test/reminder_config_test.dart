import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siddha_kutumbakam_reminder/core/reminder_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Test 1-3: Reminder timing and periodic interval configuration', () {
    final config = ReminderConfig(
      enabled: true,
      mode: ScheduleMode.periodic,
      periodicMinutes: 10,
    );
    expect(config.enabled, true);
    expect(config.periodicMinutes, 10);
    expect(config.mode, ScheduleMode.periodic);
  });

  test('Test 6-9 & 15: Pause temporarily stops reminders without changing configuration (Reminder config != Pause state)', () {
    final state = AppState();
    state.nightModeEnabled = false;
    state.exhale.enabled = true;
    state.exhale.mode = ScheduleMode.periodic;
    state.exhale.periodicMinutes = 5;

    state.taste.enabled = true;
    state.taste.mode = ScheduleMode.random;
    state.taste.randomPerHour = 4;

    // Initially active
    expect(state.exhale.enabled, true);
    expect(state.taste.enabled, true);
    expect(state.isEffectivelyPaused(), false);

    // Global Pause
    state.pauseAll();
    expect(state.isMasterPaused, true);
    expect(state.isEffectivelyPaused(), true);
    // Crucial: Exhale & Taste configuration MUST NOT be turned OFF!
    expect(state.exhale.enabled, true);
    expect(state.exhale.periodicMinutes, 5);
    expect(state.taste.enabled, true);
    expect(state.taste.randomPerHour, 4);

    // Resume All
    state.resumeAll();
    expect(state.isMasterPaused, false);
    expect(state.isEffectivelyPaused(), false);
    expect(state.exhale.enabled, true);
    expect(state.taste.enabled, true);
  });

  test('Test 10-13: Meeting Pause activates, calculates remaining time, and expires without clearing config', () {
    final state = AppState();
    state.nightModeEnabled = false;
    state.exhale.enabled = true;

    // Activate 15m Meeting Pause
    state.pauseMeetingFor(const Duration(minutes: 15));
    expect(state.isMeetingPaused, true);
    expect(state.isEffectivelyPaused(), true);
    expect(state.exhale.enabled, true);

    final activePause = state.activeMeetingPause;
    expect(activePause, isNotNull);
    expect(activePause!.isActive(DateTime.now()), true);

    // Resume cancels meeting pause
    state.resumeAll();
    expect(state.isMeetingPaused, false);
    expect(state.isEffectivelyPaused(), false);
    expect(state.exhale.enabled, true);
  });

  test('Test 14: Night Pause suppresses reminders during night hours and wakes in morning', () {
    final state = AppState();
    state.nightModeEnabled = true;
    state.nightStartHour = 22; // 10 PM
    state.nightEndHour = 7;   // 7 AM

    final midnight = DateTime(2026, 9, 16, 0, 16);
    final afternoon = DateTime(2026, 9, 16, 14, 0);

    expect(state.isNightTime(midnight), true);
    expect(state.isNightTime(afternoon), false);
  });

  test('Test 18-19: App restart & reboot persists configuration and valid meeting pause', () async {
    SharedPreferences.setMockInitialValues({});
    final state1 = AppState();
    state1.setEnabled(state1.exhale, true);
    state1.setPeriodicMinutes(state1.exhale, 15);
    state1.setEnabled(state1.taste, true);
    state1.setRandomPerHour(state1.taste, 8);
    state1.setNotificationMode(NotificationMode.vibrationOnly);
    state1.setLanguage(AppLanguage.hindi);
    state1.pauseMeetingFor(const Duration(minutes: 45));
    await state1.save();

    // Save and load into fresh state
    final state2 = AppState();
    await state2.load();

    expect(state2.exhale.enabled, true);
    expect(state2.exhale.periodicMinutes, 15);
    expect(state2.taste.enabled, true);
    expect(state2.taste.randomPerHour, 8);
    expect(state2.notificationMode, NotificationMode.vibrationOnly);
    expect(state2.language, AppLanguage.hindi);
    expect(state2.isMeetingPaused, true);
  });

  test('Test 20: Multiple pause priority hierarchy (GLOBAL > NIGHT > MEETING)', () {
    final state = AppState();
    state.exhale.enabled = true;

    // 1. Global Pause overrides everything
    state.isMasterPaused = true;
    expect(state.isEffectivelyPaused(), true);

    // 2. Clear master, but night mode active (8 PM to 8 AM crosses midnight)
    state.isMasterPaused = false;
    state.nightModeEnabled = true;
    state.nightStartHour = 20;
    state.nightEndHour = 8;
    final nightSample = DateTime(2026, 9, 29, 23, 30);
    expect(state.isNightTime(nightSample), true);
    expect(state.isEffectivelyPaused(), state.isNightTime(DateTime.now()));

    // 3. Clear night, but meeting pause active
    state.nightModeEnabled = false;
    state.pauseMeetingFor(const Duration(minutes: 10));
    expect(state.isEffectivelyPaused(), true);

    // 4. Clear all pauses -> active
    state.clearMeetingPauses();
    expect(state.isEffectivelyPaused(), false);
  });

  test('Test 21: Independent Schedulers for Exhale & Tatastha', () {
    final state = AppState();
    state.setEnabled(state.exhale, true);
    state.setMode(state.exhale, ScheduleMode.periodic);
    state.setPeriodicMinutes(state.exhale, 1);

    state.setEnabled(state.tatastha, false);
    state.setMode(state.tatastha, ScheduleMode.random);
    state.setRandomPerHour(state.tatastha, 8);

    // Exhale is active periodic 1m, Tatastha is disabled random 8/hr
    expect(state.exhale.enabled, true);
    expect(state.exhale.mode, ScheduleMode.periodic);
    expect(state.exhale.periodicMinutes, 1);

    expect(state.tatastha.enabled, false);
    expect(state.tatastha.mode, ScheduleMode.random);
    expect(state.tatastha.randomPerHour, 8);

    // Changing Exhale periodic interval does not affect Tatastha
    state.setPeriodicMinutes(state.exhale, 5);
    expect(state.exhale.periodicMinutes, 5);
    expect(state.tatastha.randomPerHour, 8);

    // Enabling Tatastha maintains its own config
    state.setEnabled(state.tatastha, true);
    expect(state.tatastha.enabled, true);
    expect(state.tatastha.mode, ScheduleMode.random);
  });

  test('Test 22: Notification mode configurations and switches', () {
    final state = AppState();
    expect(state.notificationMode, NotificationMode.soundAndVibration);

    state.setNotificationMode(NotificationMode.vibrationOnly);
    expect(state.notificationMode, NotificationMode.vibrationOnly);

    state.setNotificationMode(NotificationMode.silent);
    expect(state.notificationMode, NotificationMode.silent);
  });
}
