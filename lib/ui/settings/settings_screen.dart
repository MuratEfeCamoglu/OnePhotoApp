import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../services/reminder_service.dart';
import '../widgets/error_snackbar.dart';

/// Settings: daily reminder (F7) and storage notice (F6g).
class SettingsScreen extends StatefulWidget {
  /// Creates the screen; [onGenerateDemoData] enables the debug tool.
  const SettingsScreen({
    super.key,
    required this.reminders,
    this.onGenerateDemoData,
  });

  /// Reminder settings and scheduling.
  final ReminderService reminders;

  /// Fills the last 365 days with demo photos; returns the filled count
  /// or `null` when no photo exists yet. Shown only outside release mode.
  final Future<int?> Function()? onGenerateDemoData;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _enabled = widget.reminders.enabled;
  late int _minutes = widget.reminders.minutes;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Exception {
      _showMessage(Strings.reminderFailed);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _enabled = widget.reminders.enabled;
          _minutes = widget.reminders.minutes;
        });
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggle(bool on) => _run(() async {
    if (!on) return widget.reminders.disable();
    final granted = await widget.reminders.enable();
    if (!granted) _showMessage(Strings.notificationPermissionDenied);
  });

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
      // Turkish uses 24h; the picker's keyboard mode only honours the
      // MediaQuery flag, so a 12h device would otherwise misread "07".
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _run(
      () => widget.reminders.setTime(picked.hour * 60 + picked.minute),
    );
  }

  Future<void> _generateDemoData() async {
    setState(() => _busy = true);
    try {
      final filled = await widget.onGenerateDemoData!();
      _showMessage(
        filled == null ? Strings.demoDataNeedsEntry : Strings.demoDataDone,
      );
    } on Exception catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settingsTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            key: const ValueKey('reminder-switch'),
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text(Strings.reminderTitle),
            value: _enabled,
            onChanged: _busy ? null : _toggle,
          ),
          ListTile(
            key: const ValueKey('reminder-time'),
            leading: const Icon(Icons.schedule),
            title: Text(Strings.reminderTime(_minutes)),
            enabled: !_busy,
            onTap: _pickTime,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.dayMuted),
            title: Text(
              Strings.storageInfo,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          if (!kReleaseMode && widget.onGenerateDemoData != null)
            ListTile(
              key: const ValueKey('demo-data'),
              leading: const Icon(Icons.auto_awesome_motion_outlined),
              title: const Text(Strings.demoDataButton),
              enabled: !_busy,
              onTap: _generateDemoData,
            ),
        ],
      ),
    );
  }
}
