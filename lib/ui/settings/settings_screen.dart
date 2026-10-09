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
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SettingsRow(
            onTap: _busy ? null : () => _toggle(!_enabled),
            label: Strings.reminderTitle,
            trailing: Switch(
              key: const ValueKey('reminder-switch'),
              value: _enabled,
              onChanged: _busy ? null : _toggle,
            ),
          ),
          const Divider(indent: AppDimens.gutter, endIndent: AppDimens.gutter),
          _SettingsRow(
            key: const ValueKey('reminder-time'),
            onTap: _busy ? null : _pickTime,
            label: Strings.reminderTime(_minutes),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.dayMuted,
            ),
          ),
          const _InfoCard(),
          if (!kReleaseMode && widget.onGenerateDemoData != null) ...[
            const SizedBox(height: 8),
            _SettingsRow(
              key: const ValueKey('demo-data'),
              onTap: _busy ? null : _generateDemoData,
              label: Strings.demoDataButton,
              trailing: const Icon(
                Icons.auto_awesome_motion,
                color: AppColors.dayMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 64px tall row with a label and a trailing control (mockup `.row`).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.body)),
              const SizedBox(width: 16),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Grey card with the local-only storage notice (ISKELET F6g).
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gutter,
        AppDimens.gutter,
        0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              Strings.storageInfo,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
