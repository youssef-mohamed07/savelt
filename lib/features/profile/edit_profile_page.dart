import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/profile_ui.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String? currentEmail;

  const EditProfilePage({
    super.key,
    required this.currentName,
    this.currentEmail,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail ?? '');
    _nameController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
  }

  void _checkChanges() {
    setState(() {
      _hasChanges = _nameController.text != widget.currentName ||
          _emailController.text != (widget.currentEmail ?? '');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            ProfileSubHeader(
              badge: 'ACCOUNT',
              title: 'Edit Profile',
              onBack: _handleBack,
              trailing: _hasChanges
                  ? TextButton(
                      onPressed: _saveChanges,
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: ProfileColors.navy,
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Center(child: profileAvatar(profileInitials(_nameController.text))),
                    const SizedBox(height: 28),
                    ProfileCard(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildField(
                          controller: _nameController,
                          label: 'Full name',
                          icon: Icons.person_outline_rounded,
                          hint: 'Enter your name',
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          hint: 'Your email',
                          enabled: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _hasChanges ? _saveChanges : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ProfileColors.navy,
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save changes',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: ProfileColors.navy, size: 20),
            filled: true,
            fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ProfileColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ProfileColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ProfileColors.navy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _handleBack() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _saveChanges() {
    HapticFeedback.lightImpact();
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }
}
