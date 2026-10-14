import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/reminder_state.dart';
import 'core/audio_service.dart';
import 'core/notification_service.dart';
import 'core/permission_service.dart';
import 'core/language.dart';
import 'widgets/app_header.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/profile_page.dart';

class SiddhaKutumbakamApp extends StatefulWidget {
  const SiddhaKutumbakamApp({super.key});

  @override
  State<SiddhaKutumbakamApp> createState() => _SiddhaKutumbakamAppState();
}

class _SiddhaKutumbakamAppState extends State<SiddhaKutumbakamApp>
    with WidgetsBindingObserver {
  final AppState _appState = AppState();
  final AudioService _audio = AudioService();
  int _index = 0;
  bool _appInForeground = true;
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ── App came to foreground ──
      // Cancel all OS-scheduled reminders; the in-app timer handles everything.
      _appInForeground = true;
      NotificationService.cancelAllScheduledReminders();
      // Re-check alarm volume in case user muted it while app was in background.
      // Only warn if sound mode is active and reminders are running.
      if (_appState.notificationMode == NotificationMode.soundAndVibration &&
          (_appState.exhale.enabled || _appState.tatastha.enabled)) {
        PermissionService.isAlarmVolumeMuted().then((muted) {
          if (muted && mounted) {
            PermissionService.showAlarmVolumeMutedDialog(context);
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // ── App going to background ──
      // Schedule OS alarms so audio/notifications fire even when app is dead.
      // We only do this in 'paused' to prevent race conditions. If we do it in
      // 'detached', the OS kills the process mid-execution, which results in
      // the app cancelling previous alarms but dying before creating new ones.
      _appInForeground = false;
      _scheduleOSReminders();
    } else if (state == AppLifecycleState.detached || state == AppLifecycleState.hidden || state == AppLifecycleState.inactive) {
      _appInForeground = false;
      // Do NOT schedule or cancel OS reminders here. Let the background task survive.
    }
    _updateNotificationController();
  }

  /// Schedule OS-level exact alarms (only called when app is background/killed).
  void _scheduleOSReminders() {
    final l = L(_appState.language);
    NotificationService.syncOSSchedule(
      _appState,
      exhaleTitle: l.exhaleNotifTitle,
      exhaleBody: l.exhaleNotifBody,
      tatasthaTitle: l.tatasthaNotifTitle,
      tatasthaBody: l.tatasthaNotifBody,
    );
  }

  Future<void> _init() async {
    await NotificationService.init(
      onNotificationAction: (action) {
        if (action == 'pause') {
          _audio.stop();
          _appState.pauseAll();
        } else if (action == 'resume') {
          _appState.resumeAll();
          _audio.playMindfulChime(_appState);
        }
      },
    );
    await NotificationService.requestPermission();

    // Wire audio to state scheduler callbacks
    // NOTE: do NOT call audio.attach() here — that would create duplicate callbacks.
    // All reminder logic is wired below directly.

    // Listen to state and audio changes to update or cancel the persistent notification controller
    _appState.addListener(_updateNotificationController);
    _audio.addListener(_updateNotificationController);

    // ── Exhale reminder ──────────────────────────────────────────────────────
    _appState.onExhale = () async {
      if (_appState.isEffectivelyPaused()) return;
      final l = L(_appState.language);
      final mode = _appState.notificationMode;

      if (mode == NotificationMode.soundAndVibration) {
        // Sound mode: play audio only, NO notification popup
        await _audio.enqueueSound(ActiveAudio.exhale, 'assets/audio/exhale.mp3');
      } else if (mode == NotificationMode.vibrationOnly) {
        // Vibration mode: vibrate + show notification
        await NotificationService.triggerVibration();
        await NotificationService.showReminder(
          title: l.exhaleNotifTitle,
          body: l.exhaleNotifBody,
          mode: mode,
        );
      } else if (mode == NotificationMode.silent) {
        // Silent mode: notification only, no sound/vibration
        await NotificationService.showReminder(
          title: l.exhaleNotifTitle,
          body: l.exhaleNotifBody,
          mode: mode,
        );
      }
    };

    // ── Tatastha reminder ────────────────────────────────────────────────────
    _appState.onTatastha = () async {
      if (_appState.isEffectivelyPaused()) return;
      final l = L(_appState.language);
      final mode = _appState.notificationMode;

      if (mode == NotificationMode.soundAndVibration) {
        // Sound mode: play audio only, NO notification popup
        await _audio.enqueueSound(ActiveAudio.tatastha, 'assets/audio/tatastha.mp3');
      } else if (mode == NotificationMode.vibrationOnly) {
        await NotificationService.triggerVibration();
        await NotificationService.showReminder(
          title: l.tatasthaNotifTitle,
          body: l.tatasthaNotifBody,
          mode: mode,
        );
      } else if (mode == NotificationMode.silent) {
        await NotificationService.showReminder(
          title: l.tatasthaNotifTitle,
          body: l.tatasthaNotifBody,
          mode: mode,
        );
      }
    };

    // ── Both reminders fire at same time → sequential audio in random order, no overlap ──────
    _appState.onBothReminders = () async {
      if (_appState.isEffectivelyPaused()) return;
      final l = L(_appState.language);
      final mode = _appState.notificationMode;

      if (mode == NotificationMode.soundAndVibration) {
        // Randomize audio sequence so Exhale or Tatastha plays first, followed sequentially by the other
        final exhaleFirst = Random().nextBool();
        if (exhaleFirst) {
          await _audio.enqueueSound(ActiveAudio.exhale, 'assets/audio/exhale.mp3');
          _audio.queueNext(ActiveAudio.tatastha, 'assets/audio/tatastha.mp3');
        } else {
          await _audio.enqueueSound(ActiveAudio.tatastha, 'assets/audio/tatastha.mp3');
          _audio.queueNext(ActiveAudio.exhale, 'assets/audio/exhale.mp3');
        }
      } else if (mode == NotificationMode.vibrationOnly) {
        await NotificationService.triggerVibration();
        await NotificationService.showReminder(
          title: '${l.exhale} • ${l.tatastha}',
          body: l.exhaleNotifBody,
          mode: mode,
        );
      } else if (mode == NotificationMode.silent) {
        await NotificationService.showReminder(
          title: '${l.exhale} • ${l.tatastha}',
          body: l.exhaleNotifBody,
          mode: mode,
        );
      }
    };

    await _appState.load();
    _updateNotificationController();

    // Request critical permissions after a short delay so the UI is fully loaded.
    // We only show these dialogs once per app session.
    if (!_permissionsRequested && mounted) {
      _permissionsRequested = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _requestCriticalPermissions();
      });
    }
  }

  /// Requests all permissions needed for reliable background alarm delivery.
  /// Steps: battery exemption → exact alarm → volume check → OEM autostart.
  Future<void> _requestCriticalPermissions() async {
    // 1. Battery optimization — most important, blocks alarms on all Android versions
    final isBatteryExempt = await PermissionService.isBatteryOptimizationExempt();
    if (!isBatteryExempt && mounted) {
      await PermissionService.showBatteryOptimizationDialog(context);
    }

    // 2. Exact alarm permission — required on Android 12+ (API 31+)
    final canExact = await PermissionService.canScheduleExactAlarms();
    if (!canExact && mounted) {
      await PermissionService.showExactAlarmDialog(context);
    }

    // 3. Alarm volume check — if alarm is muted, reminders will be silent.
    // Only warn when sound mode is active and at least one reminder is enabled.
    if (_appState.notificationMode == NotificationMode.soundAndVibration &&
        (_appState.exhale.enabled || _appState.tatastha.enabled)) {
      final muted = await PermissionService.isAlarmVolumeMuted();
      if (muted && mounted) {
        await PermissionService.showAlarmVolumeMutedDialog(context);
      }
    }

    // 4. OEM Autostart — CRITICAL for Xiaomi/OPPO/Vivo/Huawei/Samsung.
    // These manufacturers kill all background apps and their AlarmManager entries
    // when the app is swiped from recents, unless autostart permission is granted.
    // This cannot be requested programmatically — user must enable it manually.
    final brand = await PermissionService.getOemBrand();
    if (brand != OemBrand.generic && mounted) {
      await PermissionService.showAutostartDialog(context, brand);
    }
  }


  void _updateNotificationController() {
    final l = L(_appState.language);
    final hasActiveReminders =
        _appState.exhale.enabled || _appState.tatastha.enabled;
    final isNight = _appState.isNightTime();
    final isMeeting = _appState.isMeetingPaused;
    final isBgAllowed = _appState.backgroundUsageAllowed;

    // OS-level scheduling only when app is not in foreground.
    // When foreground, in-app timer handles everything — no OS popups.
    if (!_appInForeground) {
      _scheduleOSReminders();
    } else {
      // Cancel any stale OS reminders so they don't fire as popups while we're open.
      NotificationService.cancelAllScheduledReminders();
    }

    // Requirement: Ongoing controller should not be seen when background is off, during sleep time, or during meeting time
    if (!isBgAllowed || isNight || isMeeting || !hasActiveReminders) {
      NotificationService.cancelOngoingController();
      return;
    }

    final isPaused = _appState.isEffectivelyPaused();
    final isPlaying = _audio.isPlaying;

    String subtitle = isPaused
        ? l.persistentNotifPaused
        : (isPlaying ? l.persistentNotifPlaying : l.persistentNotifActive);

    NotificationService.updateOngoingController(
      title: l.persistentNotifTitle,
      subtitle: subtitle,
      isPaused: isPaused,
      isPlaying: isPlaying,
      mode: _appState.notificationMode,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audio.removeListener(_updateNotificationController);
    _appState.removeListener(_updateNotificationController);
    _audio.dispose();
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_appState, _audio]),
      builder: (_, __) {
        final l = L(_appState.language);
        final pages = [
          HomePage(
            state: _appState,
            audio: _audio,
            onNavigateTab: (i) => setState(() => _index = i),
          ),
          SettingsPage(
            state: _appState,
            audio: _audio,
            onNavigateTab: (i) => setState(() => _index = i),
          ),
          ProfilePage(state: _appState),
        ];

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Siddha Kutumbakam',
          theme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme(),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5E2A84),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F3FA),
          ),
          home: Scaffold(
            backgroundColor: const Color(0xFFF5F3FA),
            body: Column(
              children: [
                // ── Global Common Header on Every Page ──
                AppHeader(
                  state: _appState,
                  audio: _audio,
                  selectedIndex: _index,
                  onNavigate: (i) => setState(() => _index = i),
                ),
                // ── Page Content ──
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: pages,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBar(
                backgroundColor: Colors.white,
                elevation: 0,
                selectedIndex: _index,
                onDestinationSelected: (v) => setState(() => _index = v),
                indicatorColor: const Color(0xFF5E2A84).withOpacity(0.12),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined, color: Colors.grey),
                    selectedIcon:
                        const Icon(Icons.home_rounded, color: Color(0xFF5E2A84)),
                    label: l.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.tune_outlined, color: Colors.grey),
                    selectedIcon:
                        const Icon(Icons.tune_rounded, color: Color(0xFF5E2A84)),
                    label: l.settings,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline_rounded,
                        color: Colors.grey),
                    selectedIcon: const Icon(Icons.person_rounded,
                        color: Color(0xFF5E2A84)),
                    label: l.profile,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

