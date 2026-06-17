import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/profile_ui.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I add a new expense?',
      'answer': 'Tap the + button on the home screen, then scan a receipt, use voice input, or enter manually.',
    },
    {
      'question': 'How do I set up reminders?',
      'answer': 'Go to Reminders from the home screen. Tap + to create a reminder with title, amount, and date.',
    },
    {
      'question': 'Can I export my data?',
      'answer': 'Go to Settings > Data & storage > Export data to download your expenses as CSV.',
    },
    {
      'question': 'How do I change my password?',
      'answer': 'Profile > Security > Change password. Enter your current password and set a new one.',
    },
    {
      'question': 'Is my data secure?',
      'answer': 'Your data is encrypted and stored securely using industry-standard practices.',
    },
    {
      'question': 'How do I delete my account?',
      'answer': 'Profile > Security > Delete account. This action is permanent.',
    },
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            ProfileSubHeader(
              badge: 'SUPPORT',
              title: 'Help',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSupportCard(),
                    const SizedBox(height: 24),
                    Text(
                      'FAQs',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_faqs.length, (i) => _buildFaqItem(i)),
                    const SizedBox(height: 20),
                    const ProfileSectionTitle('Quick links'),
                    ProfileCard(
                      children: [
                        _quickLink(Icons.play_circle_outline_rounded, 'Video tutorials'),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _quickLink(Icons.menu_book_outlined, 'User guide'),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _quickLink(Icons.bug_report_outlined, 'Report a bug'),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _quickLink(Icons.lightbulb_outline_rounded, 'Suggest a feature'),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ProfileColors.navy, ProfileColors.navyDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ProfileColors.navy.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Need help?',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Our team is ready to assist you',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _contactBtn(Icons.email_outlined, 'Email', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening email…')),
                  );
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _contactBtn(Icons.chat_bubble_outline_rounded, 'Chat', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat — coming soon')),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index) {
    final faq = _faqs[index];
    final expanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProfileColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: ProfileColors.navy,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          title: Text(
            faq['question']!,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          trailing: AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: ProfileColors.navy),
          ),
          onExpansionChanged: (v) {
            setState(() => _expandedIndex = v ? index : null);
            HapticFeedback.selectionClick();
          },
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq['answer']!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLink(IconData icon, String title) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title — coming soon')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: ProfileColors.navy, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
