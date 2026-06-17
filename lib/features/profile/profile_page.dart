import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/routes/app_routes.dart';
import 'edit_profile_page.dart';
import 'security_page.dart';
import 'settings_page.dart';
import 'help_page.dart';
import 'bloc/user_bloc.dart';
import 'bloc/user_event.dart';
import 'bloc/user_state.dart';
import 'widgets/profile_ui.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthApiService.instance;

  Future<void> _refreshUser() async {
    await _authService.getProfile();
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        final currentUser = _authService.currentUser;
        final displayName = currentUser?.displayName ?? userState.name;
        final email = currentUser?.email ?? userState.email ?? '';
        final initials = profileInitials(displayName);

        return Scaffold(
          backgroundColor: ProfileColors.bg,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainHeader(),
                  const SizedBox(height: 20),
                  _buildProfileHero(displayName, email, initials),
                  const SizedBox(height: 24),
                  const ProfileSectionTitle('Account'),
                  ProfileMenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Name & personal info',
                    onTap: () => _openEditProfile(context, displayName, email),
                  ),
                  const SizedBox(height: 10),
                  ProfileMenuTile(
                    icon: Icons.shield_outlined,
                    title: 'Security',
                    subtitle: 'Password & biometrics',
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFECFDF5),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SecurityPage()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const ProfileSectionTitle('App'),
                  ProfileMenuTile(
                    icon: Icons.tune_rounded,
                    title: 'Settings',
                    subtitle: 'Notifications & preferences',
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFF5F3FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ProfileMenuTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'FAQs and contact',
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFF0F9FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpPage()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileMenuTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    isDestructive: true,
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ProfileColors.navy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ACCOUNT',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: ProfileColors.navy,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Profile',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(String name, String email, String initials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ProfileColors.navy, ProfileColors.navyDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: ProfileColors.navy.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white,
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: ProfileColors.navy,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name.isNotEmpty ? name : 'User',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Smart Finance Tracker',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
    String displayName,
    String email,
  ) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          currentName: displayName,
          currentEmail: email,
        ),
      ),
    );
    if (result == null || result['name'] == null) return;
    try {
      await _authService.updateProfile(firstName: result['name']!);
      await _refreshUser();
      if (context.mounted) {
        context.read<UserBloc>().add(UpdateUserProfile(
              name: result['name']!,
              email: result['email'],
            ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
