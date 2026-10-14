import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/reminder_state.dart';
import '../core/language.dart';
import '../core/audio_service.dart';
import '../core/notification_service.dart';

class HomePage extends StatelessWidget {
  final AppState state;
  final AudioService audio;
  final ValueChanged<int>? onNavigateTab;

  const HomePage({
    super.key,
    required this.state,
    required this.audio,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final l = L(state.language);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 750;

    return isWide ? _wideLayout(context, l) : _mobileLayout(context, l);
  }

  // ── Mobile layout ────────────────────────────────────────────────────────────
  Widget _mobileLayout(BuildContext context, L l) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _heroBabaCard(context, l)),
        SliverToBoxAdapter(child: _masterPauseCard(context, l)),
        SliverToBoxAdapter(child: _statusMasterBanner(context, l)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              l.mindfulReminders,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D1B4E),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _reminderCard(
                context,
                l,
                title: l.exhale,
                subtitle: l.exhaleSubtitle,
                icon: Icons.air_rounded,
                colors: const [Color(0xFF6A3DE8), Color(0xFF9B6DFF)],
                config: state.exhale,
                isPlayingSound: audio.isPlayingExhale,
                onTestPlay: () => audio.playExhale(state),
              ),
              const SizedBox(height: 16),
              _reminderCard(
                context,
                l,
                title: l.tatastha,
                subtitle: l.tatasthaSubtitle,
                icon: Icons.spa_rounded,
                colors: const [Color(0xFF1B8A6B), Color(0xFF34C99A)],
                config: state.tatastha,
                isPlayingSound: audio.isPlayingTatastha,
                onTestPlay: () => audio.playTatastha(state),
              ),
              const SizedBox(height: 20),
              _meetingPauseCard(context, l),
              const SizedBox(height: 16),
              _nightPauseCard(context, l),
              const SizedBox(height: 20),
              _tipCard(l),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Desktop/Web layout ───────────────────────────────────────────────────────
  Widget _wideLayout(BuildContext context, L l) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _masterPauseCard(context, l),
                _statusMasterBanner(context, l),
                const SizedBox(height: 20),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Baba Image Card (guaranteed full head visible on web/desktop) ──
                      Expanded(
                        flex: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D1B4E), Color(0xFF4A1E70)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2D1B4E).withOpacity(0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    'assets/images/baba.jpeg',
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xCC1A0A2E),
                                  ),
                                  child: Text(
                                    l.tagline,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // ── Reminders and Actions ──
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l.mindfulReminders,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D1B4E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _reminderCard(
                              context,
                              l,
                              title: l.exhale,
                              subtitle: l.exhaleSubtitle,
                              icon: Icons.air_rounded,
                              colors: const [
                                Color(0xFF6A3DE8),
                                Color(0xFF9B6DFF),
                              ],
                              config: state.exhale,
                              isPlayingSound: audio.isPlayingExhale,
                              onTestPlay: () => audio.playExhale(state),
                            ),
                            const SizedBox(height: 16),
                            _reminderCard(
                              context,
                              l,
                              title: l.tatastha,
                              subtitle: l.tatasthaSubtitle,
                              icon: Icons.spa_rounded,
                              colors: const [
                                Color(0xFF1B8A6B),
                                Color(0xFF34C99A),
                              ],
                              config: state.tatastha,
                              isPlayingSound: audio.isPlayingTatastha,
                              onTestPlay: () => audio.playTatastha(state),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _meetingPauseCard(context, l)),
                                const SizedBox(width: 16),
                                Expanded(child: _nightPauseCard(context, l)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _tipCard(l),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Baba Card (Guaranteed uncropped head on every platform) ──────────────
  Widget _heroBabaCard(BuildContext context, L l) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B4E), Color(0xFF4A1E70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1B4E).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1F0C38),
              constraints: const BoxConstraints(
                maxHeight: 290,
                minHeight: 200,
              ),
              width: double.infinity,
              child: Image.asset(
                'assets/images/baba.jpeg',
                width: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Icon(Icons.spa_rounded, color: Colors.white70, size: 64),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xEB1A0A2E),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.self_improvement_rounded,
                    color: Color(0xFF34C99A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.tagline,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Master Pause / Resume Card (after hero image on home page) ──────────────
  Widget _masterPauseCard(BuildContext context, L l) {
    final isPaused = state.isEffectivelyPaused();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: () {
          if (!isPaused) {
            audio.stop();
            state.pauseAll();
          } else {
            state.resumeAll();
            audio.playMindfulChime(state);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPaused
                  ? [const Color(0xFF1B8A6B), const Color(0xFF34C99A)]
                  : [const Color(0xFFE53935), const Color(0xFFFF6B6B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isPaused
                        ? const Color(0xFF1B8A6B)
                        : const Color(0xFFE53935))
                    .withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isPaused ? l.resumeNow : l.masterPause,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Background Usage Status Card (shown in Settings page) ───────────────────
  Widget _backgroundUsageCard(BuildContext context, L l) {
    final isBgOn = state.backgroundUsageAllowed;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isBgOn ? Colors.white : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBgOn ? Colors.grey.shade200 : const Color(0xFFFF9800),
          width: isBgOn ? 1.0 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBgOn ? Icons.shield_rounded : Icons.warning_amber_rounded,
            color: isBgOn ? const Color(0xFF1B8A6B) : const Color(0xFFE65100),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBgOn ? l.backgroundActive : l.backgroundOff,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isBgOn
                        ? const Color(0xFF2D1B4E)
                        : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
          if (!isBgOn)
            ElevatedButton(
              onPressed: () async {
                await NotificationService.requestPermission();
                state.setBackgroundUsage(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                l.allowBackground,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600),
              ),
            )
          else
            Switch.adaptive(
              value: state.backgroundUsageAllowed,
              onChanged: state.setBackgroundUsage,
              activeColor: const Color(0xFF1B8A6B),
            ),
        ],
      ),
    );
  }

  // ── Status Banner (Active vs Paused) ──────────────────────────────────────────
  Widget _statusMasterBanner(BuildContext context, L l) {
    final isNight = state.isNightTime();
    final meetingPause = state.activeMeetingPause;
    final isMaster = state.isMasterPaused;
    final isAnyPaused = state.isEffectivelyPaused();

    if (!isAnyPaused) return const SizedBox.shrink();

    String title = l.statusPaused;
    String sub = '';
    Color bannerColor = const Color(0xFFFF9800);
    IconData icon = Icons.pause_circle_outline_rounded;

    if (isMaster) {
      sub = l.statusPaused;
      bannerColor = const Color(0xFFE53935);
      icon = Icons.pause_circle_filled_rounded;
    } else if (meetingPause != null) {
      final now = DateTime.now();
      title = l.activePause;
      sub =
          '${l.pauseUntil} ${DateFormat('hh:mm a').format(meetingPause.end)} (${meetingPause.remainingTime(now).inMinutes} ${l.minUnit})';
      bannerColor = const Color(0xFF6A3DE8);
      icon = Icons.event_busy_rounded;
    } else if (isNight) {
      title = l.nightActive;
      sub = l.nightModeSub;
      bannerColor = const Color(0xFF2D1B4E);
      icon = Icons.bedtime_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withOpacity(0.35), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: bannerColor,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              state.resumeAll();
              audio.playMindfulChime(state);
            },
            style: TextButton.styleFrom(
              backgroundColor: bannerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l.resumeNow,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Meeting Pause Card ──────────────────────────────────────────────────────
  Widget _meetingPauseCard(BuildContext context, L l) {
    final active = state.activeMeetingPause;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A3DE8).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: active != null
              ? const Color(0xFF6A3DE8).withOpacity(0.4)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A3DE8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Color(0xFF6A3DE8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.meetingPause,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D1B4E),
                      ),
                    ),
                    Text(
                      active != null
                          ? '${l.pauseUntil} ${DateFormat('hh:mm a').format(active.end)}'
                          : l.meetingSub,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: active != null
                            ? const Color(0xFF6A3DE8)
                            : Colors.grey.shade600,
                        fontWeight: active != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => onNavigateTab?.call(1),
                icon: const Icon(Icons.tune_rounded, size: 14),
                label: Text(
                  l.configure,
                  style: GoogleFonts.poppins(fontSize: 11.5),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6A3DE8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick action chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _homeQuickPauseChip(
                label: '+15 ${l.minUnit}',
                onTap: () {
                  audio.stop();
                  state.pauseMeetingFor(const Duration(minutes: 15));
                },
              ),
              _homeQuickPauseChip(
                label: '+30 ${l.minUnit}',
                onTap: () {
                  audio.stop();
                  state.pauseMeetingFor(const Duration(minutes: 30));
                },
              ),
              _homeQuickPauseChip(
                label: '+${l.pause1h}',
                onTap: () {
                  audio.stop();
                  state.pauseMeetingFor(const Duration(hours: 1));
                },
              ),
              if (active != null)
                GestureDetector(
                  onTap: () {
                    state.resumeAll();
                    audio.playMindfulChime(state);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A3DE8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l.resumeNow,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _homeQuickPauseChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D1B4E),
          ),
        ),
      ),
    );
  }

  // ── Night Pause Card ────────────────────────────────────────────────────────
  Widget _nightPauseCard(BuildContext context, L l) {
    final isNightActive = state.isNightTime();
    final startStr =
        TimeOfDay(hour: state.nightStartHour, minute: 0).format(context);
    final endStr =
        TimeOfDay(hour: state.nightEndHour, minute: 0).format(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1B4E).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isNightActive
              ? const Color(0xFF2D1B4E).withOpacity(0.4)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B4E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bedtime_rounded,
              color: Color(0xFF2D1B4E),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => onNavigateTab?.call(1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l.nightMode,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D1B4E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isNightActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D1B4E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    state.nightModeEnabled
                        ? '$startStr – $endStr'
                        : l.reminderOff,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Switch.adaptive(
            value: state.nightModeEnabled,
            onChanged: (v) {
              if (v && state.isNightTime()) {
                audio.stop();
              }
              state.setNightMode(v);
            },
            activeColor: const Color(0xFF2D1B4E),
          ),
        ],
      ),
    );
  }

  // ── Independent Mindful Reminder Card ───────────────────────────────────────
  Widget _reminderCard(
    BuildContext context,
    L l, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required ReminderConfig config,
    required bool isPlayingSound,
    required Future<void> Function() onTestPlay,
  }) {
    final enabled = config.enabled;

    String intervalDesc = '';
    if (config.mode == ScheduleMode.periodic) {
      intervalDesc = '${config.periodicMinutes} ${l.minUnit}';
    } else {
      intervalDesc = '${config.randomPerHour}/hr';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: enabled ? colors[0].withOpacity(0.35) : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Icon + Title/Subtitle + Independent Switch ──
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: enabled
                        ? colors
                        : [Colors.grey.shade300, Colors.grey.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C0F3E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Completely independent switch for this reminder
              Switch.adaptive(
                value: enabled,
                onChanged: (v) {
                  if (!v && isPlayingSound) {
                    audio.stop();
                  }
                  state.setEnabled(config, v);
                },
                activeColor: colors[0],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 10),
          // ── Bottom Row: Status Badge & Interval info + Independent Play/Stop Audio Button ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: enabled
                            ? colors[0].withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        enabled ? l.reminderOn : l.reminderOff,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: enabled ? colors[0] : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        intervalDesc,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Independent Audio Play / Stop Button
              GestureDetector(
                onTap: () async {
                  if (isPlayingSound) {
                    await audio.stop();
                  } else {
                    await onTestPlay();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPlayingSound
                        ? const Color(0xFFE53935)
                        : colors[0].withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPlayingSound
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: isPlayingSound ? Colors.white : colors[0],
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPlayingSound ? l.stopSound : l.playSound,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isPlayingSound ? Colors.white : colors[0],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tip card ─────────────────────────────────────────────────────────────────
  Widget _tipCard(L l) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3EEFF), Color(0xFFE8F9F4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD0FF), width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6A3DE8).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              color: Color(0xFF6A3DE8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.tipText,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF3D2070),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
