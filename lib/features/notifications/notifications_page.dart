import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/notification_api_service.dart';

class NotificationColors {
  static const navy = Color(0xFF0D5DB8);
  static const bg = Color(0xFFF0F4FA);
  static const border = Color(0xFFE8EDF5);
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _api = NotificationApiService.instance;

  bool _loading = true;
  String? _error;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _api.fetchMy();
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _notifications = result.notifications;
        _unreadCount = result.unreadCount;
        _loading = false;
      });
    } else {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NotificationColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: NotificationColors.navy),
                ),
              )
            else if (_error != null)
              Expanded(child: _buildError())
            else if (_notifications.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: RefreshIndicator(
                  color: NotificationColors.navy,
                  onRefresh: _load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) =>
                        _buildTile(_notifications[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NotificationColors.border),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NotificationColors.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'INBOX',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: NotificationColors.navy,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NotificationColors.border),
                ),
                child: const Icon(Icons.more_horiz_rounded, size: 20),
              ),
              onSelected: (v) {
                if (v == 'read') _markAllRead();
                if (v == 'clear') _showClearDialog();
              },
              itemBuilder: (_) => [
                if (_unreadCount > 0)
                  const PopupMenuItem(
                    value: 'read',
                    child: Text('Mark all read'),
                  ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear all', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(backgroundColor: NotificationColors.navy),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: NotificationColors.navy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 42, color: NotificationColors.navy),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Expenses, reminders and alerts\nwill show up here from your account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(AppNotification n) {
    final icon = _iconForType(n.type);
    final color = _colorForType(n.type);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        await _api.deleteNotification(n.id);
        if (mounted) {
          setState(() {
            _notifications.removeWhere((x) => x.id == n.id);
            if (!n.isRead) _unreadCount = (_unreadCount - 1).clamp(0, 999);
          });
        }
      },
      child: GestureDetector(
        onTap: () async {
          if (!n.isRead) {
            HapticFeedback.lightImpact();
            await _api.markAsRead(n.id);
            if (mounted) {
              setState(() {
                final i = _notifications.indexWhere((x) => x.id == n.id);
                if (i != -1) {
                  _notifications[i] = n.copyWith(isRead: true);
                  _unreadCount = (_unreadCount - 1).clamp(0, 999);
                }
              });
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : NotificationColors.navy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: n.isRead ? NotificationColors.border : NotificationColors.navy.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: NotificationColors.navy.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: NotificationColors.navy,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(n.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'transaction':
        return Icons.receipt_long_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      case 'offer':
        return Icons.local_offer_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'transaction':
        return NotificationColors.navy;
      case 'reminder':
        return const Color(0xFFF59E0B);
      case 'offer':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  Future<void> _markAllRead() async {
    await _api.markAllAsRead();
    if (!mounted) return;
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
    });
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear all notifications?'),
        content: const Text('This removes all notifications from your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _api.clearAll();
              if (mounted) {
                setState(() {
                  _notifications = [];
                  _unreadCount = 0;
                });
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
