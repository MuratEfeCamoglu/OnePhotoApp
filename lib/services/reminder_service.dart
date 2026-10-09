import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/strings.dart';
import 'settings_store.dart';

/// Platform side of the daily reminder; faked in tests.
abstract interface class ReminderScheduler {
  /// Asks for notification permission; `true` when granted.
  Future<bool> requestPermission();

  /// Schedules the daily notification at [minutes] after local midnight
  /// with texts from [strings], replacing any earlier schedule.
  Future<void> scheduleDaily(int minutes, Strings strings);

  /// Cancels the daily notification.
  Future<void> cancel();
}

/// Turns the reminder setting into scheduled notifications (ISKELET F7).
class ReminderService {
  /// Creates the service on top of persisted [settings].
  ReminderService({
    required this._settings,
    required this._scheduler,
    this._strings = Strings.tr,
  });

  final SettingsStore _settings;
  final ReminderScheduler _scheduler;
  Strings _strings;

  /// Switches the notification language and reschedules if needed.
  Future<void> setStrings(Strings strings) async {
    if (identical(strings, _strings)) return;
    _strings = strings;
    await restore();
  }

  /// Whether the reminder is on.
  bool get enabled => _settings.reminderEnabled;

  /// Reminder time as minutes after midnight.
  int get minutes => _settings.reminderMinutes;

  /// Re-applies a stored "on" setting at launch, e.g. after a time zone
  /// change; reboots are handled by the plugin's boot receiver.
  Future<void> restore() async {
    if (enabled) await _scheduler.scheduleDaily(minutes, _strings);
  }

  /// Turns the reminder on; returns `false` (and stays off) when the
  /// notification permission is refused (F7b).
  Future<bool> enable() async {
    final granted = await _scheduler.requestPermission();
    await _settings.setReminderEnabled(granted);
    if (granted) await _scheduler.scheduleDaily(minutes, _strings);
    return granted;
  }

  /// Turns the reminder off.
  Future<void> disable() async {
    await _settings.setReminderEnabled(false);
    await _scheduler.cancel();
  }

  /// Stores a new time and reschedules if the reminder is on.
  Future<void> setTime(int newMinutes) async {
    await _settings.setReminderMinutes(newMinutes);
    if (enabled) await _scheduler.scheduleDaily(newMinutes, _strings);
  }
}

/// [ReminderScheduler] built on flutter_local_notifications.
class LocalNotificationScheduler implements ReminderScheduler {
  /// Creates the scheduler; call [initialize] before use.
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _notificationId = 1;
  static const _channelId = 'daily_reminder';

  final FlutterLocalNotificationsPlugin _plugin;
  final _ready = Completer<void>();

  /// Loads time zones and the plugin; [onTap] runs when a notification is
  /// tapped while the app is alive. Other calls wait until this finishes.
  Future<void> initialize({VoidCallback? onTap}) async {
    try {
      await _initialize(onTap);
    } finally {
      _ready.complete();
    }
  }

  Future<void> _initialize(VoidCallback? onTap) async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Exception catch (e) {
      // tz.local stays UTC; the schedule instant is still correct today,
      // only DST shifts would drift it by an hour.
      if (kDebugMode) debugPrint('Local time zone unavailable: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onTap?.call(),
    );
  }

  @override
  Future<bool> requestPermission() async {
    await _ready.future;
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<void> scheduleDaily(int minutes, Strings strings) async {
    await cancel();
    await _ready.future;
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: strings.reminderNotificationTitle,
      body: strings.reminderNotificationBody,
      scheduledDate: at,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          strings.reminderChannelName,
          channelDescription: strings.reminderChannelDescription,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Inexact is enough (±15 min) and needs no exact alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancel() async {
    await _ready.future;
    await _plugin.cancel(id: _notificationId);
  }
}
