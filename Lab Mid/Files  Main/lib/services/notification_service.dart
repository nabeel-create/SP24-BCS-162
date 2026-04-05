import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notifications =
      fln.FlutterLocalNotificationsPlugin();
  final Map<int, Timer> _timers = {};

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    const androidSettings =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(settings);
    await _requestPermissions();
    await _setupChannels(reset: true);
  }

  Future<String> _soundKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('notification_sound') ?? 'default';
  }

  String _channelIdForSound(String soundKey) {
    return soundKey == 'beep' ? 'task_reminders_beep' : 'task_reminders_default';
  }

  Future<void> _setupChannels({bool reset = false}) async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    if (reset) {
      await androidPlugin.deleteNotificationChannel('task_reminders');
      await androidPlugin.deleteNotificationChannel('task_reminders_default');
      await androidPlugin.deleteNotificationChannel('task_reminders_beep');
    }

    const defaultChannel = fln.AndroidNotificationChannel(
      'task_reminders_default',
      'Task Reminders',
      description: 'Reminders for upcoming tasks',
      importance: fln.Importance.max,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    const beepChannel = fln.AndroidNotificationChannel(
      'task_reminders_beep',
      'Task Reminders (Beep)',
      description: 'Reminders for upcoming tasks',
      importance: fln.Importance.max,
      playSound: true,
      sound: fln.RawResourceAndroidNotificationSound('notify'),
      enableLights: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(defaultChannel);
    await androidPlugin.createNotificationChannel(beepChannel);
  }


  Future<bool> _requestPermissions() async {
    if (kIsWeb) return true;
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin>();
    final notifStatus = await Permission.notification.request();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final enabled = await androidPlugin?.areNotificationsEnabled() ?? false;
    return notifStatus.isGranted || enabled;
  }

  Future<bool> ensurePermissions() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.status;
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await androidPlugin?.areNotificationsEnabled() ?? false;
    if (status.isGranted || enabled) return true;
    return _requestPermissions();
  }


  Future<void> scheduleTaskReminder(Task task) async {
    if (kIsWeb) return;
    try {
      if (task.completed) return;
      final granted = await ensurePermissions();
      if (!granted) return;
      final now = DateTime.now();
      final scheduledDate = task.endDate;
      if (scheduledDate.isBefore(now)) {
        debugPrint('Skip notify (past): ${task.title} @ $scheduledDate');
        return;
      }

      final platformDetails = await _buildDetails();
      _scheduleInAppTimer(task.id.hashCode, scheduledDate, 'Task Due Soon', '${task.title} is due soon');

      await _notifications.zonedSchedule(
        task.id.hashCode,
        'Task Due Soon',
        '${task.title} is due soon',
        tz.TZDateTime.from(scheduledDate.toUtc(), tz.UTC),
        platformDetails,
        uiLocalNotificationDateInterpretation:
            fln.UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        androidScheduleMode: fln.AndroidScheduleMode.alarmClock,
      );
      debugPrint('Scheduled notify: ${task.title} @ $scheduledDate');
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    if (kIsWeb) return;
    try {
      _cancelInAppTimer(taskId.hashCode);
      await _notifications.cancel(taskId.hashCode);
    } catch (e) {
      debugPrint('Cancel notification error: $e');
    }
  }

  Future<fln.NotificationDetails> _buildDetails() async {
    final sound = await _soundKey();
    final channelId = _channelIdForSound(sound);
    final androidDetails = fln.AndroidNotificationDetails(
      channelId,
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks',
      importance: fln.Importance.max,
      priority: fln.Priority.max,
      playSound: true,
      enableVibration: true,
      visibility: fln.NotificationVisibility.public,
    );
    return fln.NotificationDetails(
      android: androidDetails,
      iOS: const fln.DarwinNotificationDetails(),
    );
  }

  void _scheduleInAppTimer(int id, DateTime when, String title, String body) {
    _cancelInAppTimer(id);
    final delay = when.difference(DateTime.now());
    if (delay.isNegative) return;
    if (delay > const Duration(hours: 24)) return; // avoid very long timers
    _timers[id] = Timer(delay, () async {
      try {
        final details = await _buildDetails();
        await _notifications.show(id, title, body, details);
      } catch (_) {}
    });
  }

  void _cancelInAppTimer(int id) {
    _timers.remove(id)?.cancel();
  }
}
