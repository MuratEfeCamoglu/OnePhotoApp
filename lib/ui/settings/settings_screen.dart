import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';

/// Settings: storage notice (ISKELET F6g).
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settingsTitle)),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.dayMuted),
            title: Text(
              Strings.storageInfo,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
