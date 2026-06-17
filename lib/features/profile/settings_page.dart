import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/notification_api_service.dart';
import '../../services/notification_service.dart';
import '../../features/reminders/models/reminder.dart';
import 'widgets/profile_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  ReminderSound _defaultSound = ReminderSound.defaultSound;
  String _selectedCurrency = 'EGP';

  final List<String> _currencies = ['EGP', 'USD', 'EUR', 'SAR', 'AED'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            ProfileSubHeader(
              badge: 'PREFERENCES',
              title: 'Settings',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ProfileSectionTitle('Notifications'),
                    ProfileCard(
                      children: [
                        _switchTile(Icons.notifications_none_rounded, 'Push notifications',
                            'Bill reminders & alerts', _notificationsEnabled, (v) {
                          setState(() => _notificationsEnabled = v);
                          HapticFeedback.lightImpact();
                        }),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _switchTile(Icons.vibration_rounded, 'Vibration',
                            'Haptic feedback on alerts', _vibrationEnabled, (v) {
                          setState(() => _vibrationEnabled = v);
                          HapticFeedback.lightImpact();
                        }),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _actionTile(Icons.music_note_outlined, 'Default sound',
                            _defaultSound.label, _showSoundPicker),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _actionTile(Icons.notifications_active_outlined, 'Test notification',
                            'Send a sample alert', () async {
                          HapticFeedback.lightImpact();
                          await NotificationService().showTestNotification();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test notification sent'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const ProfileSectionTitle('Preferences'),
                    ProfileCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              _iconBox(Icons.attach_money_rounded),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Currency',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: ProfileColors.border),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedCurrency,
                                  underline: const SizedBox(),
                                  items: _currencies
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedCurrency = v);
                                      HapticFeedback.lightImpact();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const ProfileSectionTitle('Data & storage'),
                    ProfileCard(
                      children: [
                        _actionTile(Icons.cloud_download_outlined, 'Export data',
                            'Download as CSV', () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Export — coming soon')),
                          );
                        }),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _actionTile(Icons.delete_sweep_outlined, 'Clear cache',
                            'Free up storage', _showClearCacheDialog),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _actionTile(Icons.notifications_off_outlined, 'Clear notifications',
                            'Remove notification history', _showClearNotificationsDialog),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const ProfileSectionTitle('About'),
                    ProfileCard(
                      children: [
                        _infoTile(Icons.info_outline_rounded, 'App version', '1.0.0'),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _actionTile(Icons.description_outlined, 'Terms of service', '', () {}),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _actionTile(Icons.privacy_tip_outlined, 'Privacy policy', '', () {}),
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

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: ProfileColors.navy, size: 20),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeTrackColor: ProfileColors.navy),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14))),
          Text(value, style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Select sound',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ...ReminderSound.values.map((sound) => ListTile(
                  leading: Icon(sound.icon, color: ProfileColors.navy),
                  title: Text(sound.label),
                  trailing: _defaultSound == sound
                      ? const Icon(Icons.check_circle_rounded, color: ProfileColors.navy)
                      : null,
                  onTap: () {
                    setState(() => _defaultSound = sound);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showClearNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await NotificationApiService.instance.clearAll();
              NotificationService().clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications cleared'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear cache?'),
        content: const Text('Cached data will be removed. Your saved expenses stay intact.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared'), backgroundColor: Color(0xFF10B981)),
              );
            },
            child: const Text('Clear', style: TextStyle(color: ProfileColors.navy)),
          ),
        ],
      ),
    );
  }
}
