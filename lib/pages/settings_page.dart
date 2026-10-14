import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/reminder_state.dart';
import '../core/language.dart';
import '../core/audio_service.dart';
import '../core/notification_service.dart';
import '../core/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  final AppState state;
  final AudioService? audio;
  final ValueChanged<int>? onNavigateTab;

  const SettingsPage({
    super.key,
    required this.state,
    this.audio,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        final l = L(state.language);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Device Setup (alarm health card) ────────────────────
                  const DeviceSetupCard(),
                  const SizedBox(height: 18),
                  // ── Background Usage Status ────────────────────────────
                  _backgroundUsageCard(context, l),
                  const SizedBox(height: 18),
                  // ── Exhale Config ──────────────────────────────────
                  _reminderCard(context, l, l.exhaleConfig, state.exhale,
                      Icons.air_rounded, const Color(0xFF6A3DE8)),
                  const SizedBox(height: 18),
                  // ── Tatastha Config ────────────────────────────────
                  _reminderCard(context, l, l.tatasthaConfig, state.tatastha,
                      Icons.spa_rounded, const Color(0xFF1B8A6B)),
                  const SizedBox(height: 18),
                  // ── Notification Mode ──────────────────────────────
                  _sectionCard(child: _notifModeSection(l)),
                  const SizedBox(height: 18),
                  // ── Night Mode ─────────────────────────────────────
                  _sectionCard(child: _nightModeSection(context, l)),
                  const SizedBox(height: 18),
                  // ── Language ───────────────────────────────────────
                  _sectionCard(child: _languageSection(l)),
                  const SizedBox(height: 18),
                  // ── Meeting Pause ──────────────────────────────────
                  _sectionCard(child: _meetingPauseSection(context, l)),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Background Usage Status Card ────────────────────────────────────────────
  Widget _backgroundUsageCard(BuildContext context, L l) {
    final isBgOn = state.backgroundUsageAllowed;
    return _sectionCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isBgOn ? const Color(0xFF1B8A6B) : const Color(0xFFE65100))
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBgOn ? Icons.shield_rounded : Icons.warning_amber_rounded,
              color: isBgOn ? const Color(0xFF1B8A6B) : const Color(0xFFE65100),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBgOn ? l.backgroundActive : l.backgroundOff,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isBgOn
                        ? const Color(0xFF2D1B4E)
                        : const Color(0xFFE65100),
                  ),
                ),
                Text(
                  isBgOn
                      ? 'App can run reminders in background'
                      : 'Tap to enable background reminders',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
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

  // ── Meeting pause section ───────────────────────────────────────────────────
  Widget _meetingPauseSection(BuildContext context, L l) {
    final active = state.activeMeetingPause;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconBox(Icons.event_busy_rounded, const Color(0xFF6A3DE8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.meetingPause,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(l.meetingSub,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _divider(),
        const SizedBox(height: 12),
        if (active != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6A3DE8).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFF6A3DE8).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pause_circle_filled_rounded,
                    color: Color(0xFF6A3DE8), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.activePause,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D1B4E))),
                      Text(
                        '${l.pauseUntil} ${DateFormat('hh:mm a').format(active.end)} (${active.remainingTime(now).inMinutes} ${l.minUnit})',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF6A3DE8)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    state.resumeAll();
                    if (audio != null) {
                      audio!.playMindfulChime(state);
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF6A3DE8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(l.resumeNow,
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _label(l.quickPause),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickPauseBtn(l.pause15m, const Duration(minutes: 15)),
            _quickPauseBtn(l.pause30m, const Duration(minutes: 30)),
            _quickPauseBtn(l.pause1h, const Duration(hours: 1)),
            _quickPauseBtn(l.pause2h, const Duration(hours: 2)),
            GestureDetector(
              onTap: () => _addPause(context, l),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A3DE8).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF6A3DE8).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Color(0xFF6A3DE8), size: 16),
                    const SizedBox(width: 4),
                    Text(l.addPause,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6A3DE8))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickPauseBtn(String label, Duration duration) {
    return GestureDetector(
      onTap: () {
        audio?.stop();
        state.pauseMeetingFor(duration);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          '+$label',
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D1B4E)),
        ),
      ),
    );
  }

  // ── Reminder config card ──────────────────────────────────────────────────────
  Widget _reminderCard(BuildContext context, L l, String title,
      ReminderConfig config, IconData icon, Color accent) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(icon, accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Switch.adaptive(
                value: config.enabled,
                onChanged: (v) {
                  if (!v) {
                    audio?.stop();
                  }
                  state.setEnabled(config, v);
                },
                activeColor: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 8),
          _label(l.playMode),
          const SizedBox(height: 6),
          _modeOption(
              l.randomly, l.randomSub, ScheduleMode.random, config, accent),
          if (config.mode == ScheduleMode.random) ...[
            const SizedBox(height: 8),
            _randomDropdown(config, accent),
          ],
          const SizedBox(height: 6),
          _modeOption(l.periodically, l.periodicSub, ScheduleMode.periodic,
              config, accent),
          if (config.mode == ScheduleMode.periodic) ...[
            const SizedBox(height: 8),
            _periodicRow(context, l, config, accent),
          ],
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              _label(l.pausePeriods),
              const Spacer(),
              _chip(l.addPause, accent,
                  onTap: () => _addPause(context, l, specific: config)),
            ],
          ),
          const SizedBox(height: 8),
          if (config.pauses.isEmpty)
            Text(l.noPauses,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade500))
          else
            ...config.pauses
                .asMap()
                .entries
                .map((e) => _pauseTile(e, config, accent)),
        ],
      ),
    );
  }

  // ── Notification mode section ────────────────────────────────────────────────
  Widget _notifModeSection(L l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconBox(Icons.notifications_outlined, const Color(0xFF5E2A84)),
            const SizedBox(width: 12),
            Text(l.notifMode,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        _notifOption(
          l.soundVibrate,
          Icons.volume_up_rounded,
          NotificationMode.soundAndVibration,
          const Color(0xFF6A3DE8),
        ),
        const SizedBox(height: 8),
        _notifOption(
          l.vibrateOnly,
          Icons.vibration_rounded,
          NotificationMode.vibrationOnly,
          const Color(0xFF1B8A6B),
        ),
        const SizedBox(height: 8),
        _notifOption(
          l.silentMode,
          Icons.notifications_off_outlined,
          NotificationMode.silent,
          Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _notifOption(
      String label, IconData icon, NotificationMode value, Color accent) {
    final selected = state.notificationMode == value;
    return GestureDetector(
      onTap: () {
        state.setNotificationMode(value);
        if (value == NotificationMode.vibrationOnly ||
            value == NotificationMode.soundAndVibration) {
          NotificationService.triggerVibration();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : Colors.grey.shade300,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? accent : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? accent : Colors.black87)),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: accent, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Night mode section ───────────────────────────────────────────────────────
  Widget _nightModeSection(BuildContext context, L l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconBox(Icons.bedtime_outlined, const Color(0xFF2D1B4E)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.nightMode,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(l.nightModeSub,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Switch.adaptive(
              value: state.nightModeEnabled,
              onChanged: state.setNightMode,
              activeColor: const Color(0xFF2D1B4E),
            ),
          ],
        ),
        if (state.nightModeEnabled) ...[
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _timeButton(
                  context,
                  label: l.nightStart,
                  hour: state.nightStartHour,
                  onPicked: (h) =>
                      state.setNightHours(h, state.nightEndHour),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeButton(
                  context,
                  label: l.nightEnd,
                  hour: state.nightEndHour,
                  onPicked: (h) =>
                      state.setNightHours(state.nightStartHour, h),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _timeButton(BuildContext context,
      {required String label,
      required int hour,
      required ValueChanged<int> onPicked}) {
    final display =
        TimeOfDay(hour: hour, minute: 0).format(context);
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
        );
        if (picked != null) onPicked(picked.hour);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D1B4E).withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF2D1B4E).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: Color(0xFF2D1B4E)),
                const SizedBox(width: 6),
                Text(display,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D1B4E))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Language section ─────────────────────────────────────────────────────────
  Widget _languageSection(L l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconBox(Icons.language_rounded, const Color(0xFF1B8A6B)),
            const SizedBox(width: 12),
            Text(l.language,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _langButton(AppLanguage.english, l.english)),
            const SizedBox(width: 12),
            Expanded(child: _langButton(AppLanguage.hindi, l.hindi)),
          ],
        ),
      ],
    );
  }

  Widget _langButton(AppLanguage lang, String label) {
    final selected = state.language == lang;
    final accent = const Color(0xFF1B8A6B);
    return GestureDetector(
      onTap: () => state.setLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? accent : Colors.grey.shade300, width: 1.5),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade700)),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _modeOption(String title, String sub, ScheduleMode value,
      ReminderConfig config, Color accent) {
    final selected = config.mode == value;
    return GestureDetector(
      onTap: () => state.setMode(config, value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? accent.withOpacity(0.4) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? accent : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? accent : Colors.black87)),
                  Text(sub,
                      style: GoogleFonts.poppins(
                          fontSize: 11.5, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodicRow(
      BuildContext context, L l, ReminderConfig config, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: [1, 2, 5, 10, 15, 20, 30, 45, 60]
                  .contains(config.periodicMinutes)
              ? config.periodicMinutes
              : 15,
          items: const [
            DropdownMenuItem(value: 1, child: Text('Every 1 minute')),
            DropdownMenuItem(value: 2, child: Text('Every 2 minutes')),
            DropdownMenuItem(value: 5, child: Text('Every 5 minutes')),
            DropdownMenuItem(value: 10, child: Text('Every 10 minutes')),
            DropdownMenuItem(value: 15, child: Text('Every 15 minutes')),
            DropdownMenuItem(value: 20, child: Text('Every 20 minutes')),
            DropdownMenuItem(value: 30, child: Text('Every 30 minutes')),
            DropdownMenuItem(value: 45, child: Text('Every 45 minutes')),
            DropdownMenuItem(value: 60, child: Text('Every 1 hour')),
          ],
          onChanged: (v) {
            if (v != null) state.setPeriodicMinutes(config, v);
          },
        ),
      ),
    );
  }

  Widget _randomDropdown(ReminderConfig config, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: config.randomPerHour.clamp(1, 12),
          items: List.generate(12, (index) {
            final val = index + 1;
            return DropdownMenuItem(
              value: val,
              child: Text('$val time${val == 1 ? '' : 's'} per hour'),
            );
          }),
          onChanged: (v) {
            if (v != null) state.setRandomPerHour(config, v);
          },
        ),
      ),
    );
  }

  Widget _pauseTile(
      MapEntry<int, PauseWindow> e, ReminderConfig config, Color accent) {
    final p = e.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.pause_circle_outline_rounded, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(p.start),
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text('until ${DateFormat('hh:mm a').format(p.end)}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            onPressed: () => state.removePause(config, e.key),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700));
  }

  Widget _divider() => Divider(color: Colors.grey.shade100, height: 1);

  Widget _chip(String label, Color accent, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
      ),
    );
  }

  Future<void> _addPause(BuildContext context, L l,
      {ReminderConfig? specific}) async {
    final now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);
    TimeOfDay start = TimeOfDay.fromDateTime(now);
    TimeOfDay end =
        TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));

    final chosenDate = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: date,
    );
    if (chosenDate == null || !context.mounted) return;
    date = chosenDate;

    final chosenStart =
        await showTimePicker(context: context, initialTime: start);
    if (chosenStart == null || !context.mounted) return;
    start = chosenStart;

    final chosenEnd =
        await showTimePicker(context: context, initialTime: end);
    if (chosenEnd == null || !context.mounted) return;
    end = chosenEnd;

    DateTime s =
        DateTime(date.year, date.month, date.day, start.hour, start.minute);
    DateTime e =
        DateTime(date.year, date.month, date.day, end.hour, end.minute);
    if (!e.isAfter(s)) e = e.add(const Duration(days: 1));

    final targets = specific == null
        ? [state.exhale, state.tatastha]
        : [specific];
    for (final t in targets) {
      state.addPause(t, s, e);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Device Setup Health Card
// Shows each permission/setting with a green ✓ or red ✗ + fix button
// ──────────────────────────────────────────────────────────────────────────────
class DeviceSetupCard extends StatefulWidget {
  const DeviceSetupCard({super.key});

  @override
  State<DeviceSetupCard> createState() => _DeviceSetupCardState();
}

class _DeviceSetupCardState extends State<DeviceSetupCard> {
  static const _purple = Color(0xFF5E2A84);
  AlarmSetupStatus? _status;
  bool _loading = true;
  bool _testScheduled = false;
  int _testCountdown = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final status = await PermissionService.getSetupStatus();
    if (mounted) setState(() { _status = status; _loading = false; });
  }

  Future<void> _scheduleTestAlarm() async {
    // Schedules a test notification 30 seconds from now using the alarm channel.
    // This lets the user close the app and verify the sound fires correctly.
    final testTime = DateTime.now().add(const Duration(seconds: 30));
    await NotificationService.scheduleTestAlarm(testTime);
    setState(() { _testScheduled = true; _testCountdown = 30; });
    // Count down so user knows when to expect the alarm
    _countdownTick();
  }

  void _countdownTick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _testCountdown <= 0) return;
      setState(() => _testCountdown--);
      if (_testCountdown > 0) _countdownTick();
      else setState(() => _testScheduled = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final allGood = s?.isFullyConfigured == true && !(s?.isAggressiveOem == true);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allGood
              ? [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)]
              : [const Color(0xFFFFF3E0), const Color(0xFFFFF8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allGood
              ? const Color(0xFF1B8A6B).withAlpha(80)
              : Colors.orange.withAlpha(100),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                allGood ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: allGood ? const Color(0xFF1B8A6B) : Colors.orange[800],
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Alarm Setup',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D1B4E)),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _purple))
              else
                GestureDetector(
                  onTap: _refresh,
                  child: Icon(Icons.refresh_rounded,
                      size: 20, color: Colors.grey[500]),
                ),
            ],
          ),
          if (_loading) ...
            [const SizedBox(height: 12)]
          else if (s != null) ...[
            const SizedBox(height: 14),
            _row(
              ok: s.batteryExempt,
              label: 'Battery unrestricted',
              fixLabel: 'Fix',
              onFix: () async {
                await PermissionService.showBatteryOptimizationDialog(context);
                _refresh();
              },
            ),
            _row(
              ok: s.exactAlarmGranted,
              label: 'Exact alarms allowed',
              fixLabel: 'Enable',
              onFix: () async {
                await PermissionService.showExactAlarmDialog(context);
                _refresh();
              },
            ),
            _row(
              ok: !s.alarmVolumeMuted,
              label: 'Alarm volume is on',
              fixLabel: 'Set Volume',
              onFix: () async {
                await PermissionService.showAlarmVolumeMutedDialog(context);
                _refresh();
              },
            ),
            if (s.isAggressiveOem)
              _row(
                ok: s.autostartAcknowledged,
                label: 'Autostart (${_brandName(s.oemBrand)})',
                fixLabel: s.autostartAcknowledged ? 'Review' : 'How to fix',
                onFix: () async {
                  await PermissionService.showAutostartDialog(context, s.oemBrand);
                  if (!s.autostartAcknowledged && mounted) {
                    final fixed = await _askIfFixed(context);
                    if (fixed == true) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('autostart_fixed', true);
                      _refresh();
                    }
                  }
                },
              ),
            const Divider(height: 24),
            // Test alarm button
            Center(
              child: _testScheduled
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_rounded,
                                color: _purple, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Close the app now! Alarm in ${_testCountdown}s',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _purple),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swipe the app away completely, then listen.',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: _scheduleTestAlarm,
                      icon: const Icon(Icons.alarm_add_rounded, size: 18),
                      label: const Text('Test Alarm in 30s'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _purple,
                        side: const BorderSide(color: _purple),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Tap test alarm. Close app. If alarm plays, everything works!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 10.5, color: Colors.grey[500]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row({
    required bool ok,
    required String label,
    required String fixLabel,
    required VoidCallback onFix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? const Color(0xFF1B8A6B) : Colors.red[400],
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: ok ? const Color(0xFF2D1B4E) : Colors.grey[800]),
            ),
          ),
          GestureDetector(
            onTap: onFix,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ok ? Colors.grey[300] : _purple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                fixLabel,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ok ? Colors.black54 : Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _askIfFixed(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Did you enable it?'),
        content: const Text(
          'Did you successfully enable Autostart (or Unrestricted battery) for this app in your device settings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No / Not sure'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _purple),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, I enabled it'),
          ),
        ],
      ),
    );
  }

  String _brandName(OemBrand brand) => switch (brand) {
    OemBrand.xiaomi  => 'Xiaomi/MIUI',
    OemBrand.huawei  => 'Huawei/EMUI',
    OemBrand.oppo    => 'OPPO/Realme',
    OemBrand.vivo    => 'Vivo',
    OemBrand.samsung => 'Samsung',
    OemBrand.generic => 'Device',
  };
}
