import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bloc/reminder_bloc.dart';
import 'bloc/reminder_event.dart';
import 'bloc/reminder_state.dart';
import 'models/reminder.dart';
import 'widgets/reminder_form_sheet.dart';
import 'widgets/reminder_tile.dart';
import 'widgets/reminder_ui_helpers.dart';

class RemindersPage extends StatefulWidget {
  final ReminderBloc? reminderBloc;

  const RemindersPage({super.key, this.reminderBloc});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  ReminderBloc get _bloc =>
      widget.reminderBloc ?? context.read<ReminderBloc>();

  @override
  Widget build(BuildContext context) {
    if (widget.reminderBloc != null) {
      return BlocProvider.value(
        value: widget.reminderBloc!,
        child: _buildScaffold(),
      );
    }

    try {
      context.read<ReminderBloc>();
      return _buildScaffold();
    } catch (_) {
      return BlocProvider(
        create: (_) => ReminderBloc(),
        child: _buildScaffold(),
      );
    }
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: ReminderColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode ? null : _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ReminderColors.border),
                ),
                child: const Icon(Icons.close_rounded, size: 20),
              ),
            ),
            Expanded(
              child: Text(
                '${_selectedIds.length} selected',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            BlocBuilder<ReminderBloc, ReminderState>(
              builder: (context, state) {
                if (state is! ReminderLoaded) return const SizedBox(width: 48);
                final allSelected =
                    _selectedIds.length == state.reminders.length;
                return TextButton(
                  onPressed: () {
                    setState(() {
                      if (allSelected) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds
                          ..clear()
                          ..addAll(state.reminders.map((r) => r.id));
                      }
                    });
                  },
                  child: Text(
                    allSelected ? 'None' : 'All',
                    style: GoogleFonts.inter(
                      color: ReminderColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
            if (_selectedIds.isNotEmpty)
              IconButton(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
          ],
        ),
      );
    }

    return ReminderPageHeader(
      onBack: () => Navigator.pop(context),
      trailing: BlocBuilder<ReminderBloc, ReminderState>(
        builder: (context, state) {
          if (state is! ReminderLoaded || state.reminders.isEmpty) {
            return const SizedBox(width: 48);
          }
          return IconButton(
            onPressed: () => setState(() => _isSelectionMode = true),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ReminderColors.border),
              ),
              child: const Icon(Icons.checklist_rounded,
                  size: 20, color: Color(0xFF64748B)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is ReminderLoading || state is ReminderInitial) {
          return const Center(
            child: CircularProgressIndicator(color: ReminderColors.navy),
          );
        }

        if (state is ReminderError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.read<ReminderBloc>().add(const LoadReminders()),
                    style: FilledButton.styleFrom(
                      backgroundColor: ReminderColors.navy,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! ReminderLoaded) {
          return const SizedBox.shrink();
        }

        final reminders = state.reminders;
        if (reminders.isEmpty) return _buildEmptyState();

        final now = DateTime.now();
        final active = reminders.where((r) => r.enabled).toList();
        final inactive = reminders.where((r) => !r.enabled).toList();
        final upcoming = reminders
            .where((r) => r.enabled && !r.date.isBefore(now))
            .length;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            ReminderSummaryCard(
              activeCount: active.length,
              totalCount: reminders.length,
              upcomingCount: upcoming,
            ),
            if (active.isNotEmpty) ...[
              _sectionLabel('Active'),
              ...active.map((r) => _buildDismissible(r)),
            ],
            if (inactive.isNotEmpty) ...[
              _sectionLabel('Paused'),
              ...inactive.map((r) => _buildDismissible(r)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDismissible(Reminder reminder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Dismissible(
        key: Key('reminder_${reminder.id}'),
        direction:
            _isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
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
        confirmDismiss: (_) async {
          final confirmed = await _confirmDelete(reminder.title);
          if (confirmed == true) {
            _bloc.add(DeleteReminder(reminder.id));
          }
          return false;
        },
        child: ReminderTile(
          reminder: reminder,
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedIds.contains(reminder.id),
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (_selectedIds.contains(reminder.id)) {
                  _selectedIds.remove(reminder.id);
                  if (_selectedIds.isEmpty) _isSelectionMode = false;
                } else {
                  _selectedIds.add(reminder.id);
                }
              });
            } else {
              showReminderFormSheet(context, bloc: _bloc, existing: reminder);
            }
          },
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _selectedIds.add(reminder.id);
            });
          },
          onToggle: (v) => _bloc.add(ToggleReminder(reminder.id)),
          onSelectChanged: (selected) {
            setState(() {
              if (selected) {
                _selectedIds.add(reminder.id);
              } else {
                _selectedIds.remove(reminder.id);
                if (_selectedIds.isEmpty) _isSelectionMode = false;
              }
            });
          },
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
                gradient: LinearGradient(
                  colors: [
                    ReminderColors.navy.withValues(alpha: 0.15),
                    ReminderColors.navy.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 42, color: ReminderColors.navy),
            ),
            const SizedBox(height: 20),
            Text(
              'No reminders yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track bills, subscriptions & payments\nso you never miss a due date.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openAddSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add reminder'),
              style: FilledButton.styleFrom(
                backgroundColor: ReminderColors.navy,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: _openAddSheet,
          backgroundColor: ReminderColors.navy,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Add reminder',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _openAddSheet() {
    HapticFeedback.lightImpact();
    showReminderFormSheet(context, bloc: _bloc);
  }

  Future<bool?> _confirmDelete(String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete reminder?'),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    final bloc = _bloc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete reminders?'),
        content: Text('Delete ${_selectedIds.length} selected reminders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(DeleteMultipleReminders(_selectedIds.toList()));
              setState(() {
                _selectedIds.clear();
                _isSelectionMode = false;
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
