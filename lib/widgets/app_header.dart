import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/reminder_state.dart';
import '../core/language.dart';
import '../core/audio_service.dart';

/// Common Header widget shared across all pages and platforms.
/// Displays App Logo, Current Page Status / Navigation Tabs, and Master Pause/Resume Button.
class AppHeader extends StatelessWidget {
  final AppState state;
  final AudioService? audio;
  final int selectedIndex;
  final ValueChanged<int>? onNavigate;

  const AppHeader({
    super.key,
    required this.state,
    this.audio,
    required this.selectedIndex,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final l = L(state.language);
    final isPaused = state.isEffectivelyPaused();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 450;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D1B4E).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 14 : 20,
                vertical: isCompact ? 10 : 12,
              ),
              child: Row(
                children: [
                  // ── App Logo ──
                  GestureDetector(
                    onTap: () => onNavigate?.call(0),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5E2A84).withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5E2A84).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/app_logo.jpeg',
                          width: isCompact ? 38 : 44,
                          height: isCompact ? 38 : 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.spa_rounded,
                            color: Color(0xFF5E2A84),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 10 : 14),

                  // ── App Title & Mindful Tagline/Status ──
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onNavigate?.call(0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.appName,
                            style: GoogleFonts.poppins(
                              fontSize: isCompact ? 15.5 : 17.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D1B4E),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPaused
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF1B8A6B),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  isPaused ? l.statusPaused : l.mindfulReminders,
                                  style: GoogleFonts.poppins(
                                    fontSize: isCompact ? 11 : 12,
                                    fontWeight: FontWeight.w500,
                                    color: isPaused
                                        ? const Color(0xFFE53935)
                                        : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
