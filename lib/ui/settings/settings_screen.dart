import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../services/reminder_service.dart';
import '../../services/settings_store.dart';
import '../../state/appearance_controller.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/l10n.dart';
import '../widgets/motion.dart';

/// Settings: theme (F9), language (F10), reminder (F7), storage note (F6g).
class SettingsScreen extends StatefulWidget {
  /// Creates the screen; [onGenerateDemoData] enables the debug tool.
  const SettingsScreen({
    super.key,
    required this.reminders,
    required this.appearance,
    this.onGenerateDemoData,
  });

  /// Reminder settings and scheduling.
  final ReminderService reminders;

  /// Theme and language choices.
  final AppearanceController appearance;

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
    final failed = context.strings.reminderFailed;
    setState(() => _busy = true);
    try {
      await action();
    } on Exception {
      _showMessage(failed);
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
    if (mounted) showMessageSnackBar(context, text);
  }

  Future<void> _toggle(bool on) => _run(() async {
    if (!on) return widget.reminders.disable();
    final granted = await widget.reminders.enable();
    if (!granted && mounted) {
      _showMessage(context.strings.notificationPermissionDenied);
    }
  });

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
      // The app shows times as 24h; the picker's keyboard mode only honours
      // the MediaQuery flag, so a 12h device would otherwise misread "07".
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
    final strings = context.strings;
    setState(() => _busy = true);
    try {
      final filled = await widget.onGenerateDemoData!();
      _showMessage(
        filled == null ? strings.demoDataNeedsEntry : strings.demoDataDone,
      );
    } on Exception catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final p = context.palette;
    final appearance = widget.appearance;
    var section = 0;
    // Sections slide in one after another.
    Widget staggered(Widget child) => EntranceAnimation(
      delay: Duration(milliseconds: 60 * section++),
      child: child,
    );
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListenableBuilder(
        listenable: appearance,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [
            staggered(
              _Section(
                title: s.appearanceSection,
                children: [
                  _ChoiceRow<ThemePreference>(
                    key: const ValueKey('theme-choice'),
                    selected: appearance.themePreference,
                    onChanged: appearance.setThemePreference,
                    options: [
                      (
                        ThemePreference.system,
                        s.themeSystem,
                        Icons.brightness_auto_rounded,
                      ),
                      (
                        ThemePreference.light,
                        s.themeLight,
                        Icons.light_mode_rounded,
                      ),
                      (
                        ThemePreference.dark,
                        s.themeDark,
                        Icons.dark_mode_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            staggered(
              _Section(
                title: s.languageSection,
                children: [
                  _ChoiceRow<AppLanguage>(
                    key: const ValueKey('language-choice'),
                    selected: appearance.language,
                    onChanged: appearance.setLanguage,
                    options: [
                      for (final l in AppLanguage.values)
                        (l, l.nativeName, Icons.translate_rounded),
                    ],
                  ),
                ],
              ),
            ),
            staggered(
              _Section(
                title: s.reminderSection,
                children: [
                  _SettingsRow(
                    onTap: _busy ? null : () => _toggle(!_enabled),
                    label: s.reminderTitle,
                    trailing: Switch(
                      key: const ValueKey('reminder-switch'),
                      value: _enabled,
                      onChanged: _busy ? null : _toggle,
                    ),
                  ),
                  Divider(indent: 16, endIndent: 16, color: p.outline),
                  _SettingsRow(
                    key: const ValueKey('reminder-time'),
                    onTap: _busy ? null : _pickTime,
                    label: s.reminderTime(_minutes),
                    trailing: Icon(Icons.chevron_right, color: p.dayMuted),
                  ),
                ],
              ),
            ),
            staggered(const _InfoCard()),
            if (!kReleaseMode && widget.onGenerateDemoData != null)
              staggered(
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _SettingsRow(
                    key: const ValueKey('demo-data'),
                    onTap: _busy ? null : _generateDemoData,
                    label: s.demoDataButton,
                    trailing: Icon(
                      Icons.auto_awesome_motion,
                      color: p.dayMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Titled rounded group of rows.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        12,
        AppDimens.gutter,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: AppText.section.copyWith(color: p.dayMuted),
            ),
          ),
          Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppDimens.cardRadius),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// Segmented choice filling the section width.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  final T selected;
  final ValueChanged<T> onChanged;
  final List<(T, String, IconData)> options;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<T>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity(vertical: 1)),
          segments: [
            for (final (value, label, icon) in options)
              ButtonSegment(
                value: value,
                label: Text(label, overflow: TextOverflow.ellipsis),
                icon: Icon(icon, size: 18),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (values) => onChanged(values.single),
        ),
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
              Expanded(
                child: Text(
                  label,
                  style: AppText.body.copyWith(
                    color: context.palette.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Card with the local-only storage notice (ISKELET F6g).
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gutter,
        AppDimens.gutter,
        0,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.info, size: 20, color: p.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.strings.storageInfo,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: p.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
