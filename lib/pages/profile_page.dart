import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/reminder_state.dart';
import '../core/language.dart';

class ProfilePage extends StatelessWidget {
  final AppState state;
  const ProfilePage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        final l = L(state.language);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(l)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _infoCard(l),
                  const SizedBox(height: 18),
                  _motivationCard(l),
                  const SizedBox(height: 18),
                  _linksCard(l),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '${l.version}  •  ${l.appName}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header(L l) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B8A6B), Color(0xFF2D1B4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2.5),
            ),
            child: const CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(l.sadhak,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(l.sadhakSub,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _infoCard(L l) {
    return _card(
      children: [
        _infoTile(Icons.person_outline_rounded, const Color(0xFF6A3DE8),
            l.name, l.sadhak),
        _divider(),
        _infoTile(Icons.email_outlined, const Color(0xFF1B8A6B), l.email,
            'user@example.com'),
        _divider(),
        _infoTile(Icons.info_outline_rounded, const Color(0xFF5E2A84),
            l.about, l.aboutText),
      ],
    );
  }

  Widget _motivationCard(L l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1B4E), Color(0xFF5E2A84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E2A84).withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.stayHealthy,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(l.quote,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Image.asset('assets/images/app_logo.jpeg',
                height: 36, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  Widget _linksCard(L l) {
    return _card(
      children: [
        _linkTile(Icons.privacy_tip_outlined, const Color(0xFF1B8A6B), l.privacy),
        _divider(),
        _linkTile(Icons.description_outlined, const Color(0xFF6A3DE8), l.terms),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _infoTile(IconData icon, Color color, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: const Color(0xFF1C0F3E))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(IconData icon, Color color, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: const Color(0xFF1C0F3E))),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 18, endIndent: 18, color: Colors.grey.shade100);
}
