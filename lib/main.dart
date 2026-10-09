import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'core/clock.dart';
import 'data/photo_storage.dart';
import 'data/sqflite_entry_repository.dart';
import 'services/photo_picker.dart';
import 'services/photo_service.dart';
import 'services/settings_store.dart';
import 'state/timeline_controller.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/timeline/timeline_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('tr_TR');

  final settings = SettingsStore(await SharedPreferences.getInstance());
  final repository = await SqfliteEntryRepository.open(
    databaseFactory,
    p.join(await getDatabasesPath(), SqfliteEntryRepository.fileName),
  );
  final storage = await PhotoStorage.inDocuments();
  final service = PhotoService(
    repository: repository,
    storage: storage,
    picker: ImagePickerPhotoPicker(),
    settings: settings,
    clock: systemClock,
  );
  final controller = TimelineController(service: service, clock: systemClock);
  unawaited(controller.startup());

  runApp(
    OnePhotoApp(
      home: TimelineScreen(
        controller: controller,
        settingsBuilder: (_) => const SettingsScreen(),
      ),
    ),
  );
}
