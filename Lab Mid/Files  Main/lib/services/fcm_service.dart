import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _FcmLocalNotifications.instance.showFromMessage(message);
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _FcmLocalNotifications.instance.initialize();
    FirebaseMessaging.onMessage.listen((message) {
      _FcmLocalNotifications.instance.showFromMessage(message);
    });

    final token = await messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }
  }
}

class _FcmLocalNotifications {
  static final _FcmLocalNotifications instance = _FcmLocalNotifications._internal();
  _FcmLocalNotifications._internal();

  final fln.FlutterLocalNotificationsPlugin _local =
      fln.FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const androidSettings =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = fln.InitializationSettings(android: androidSettings);
    await _local.initialize(settings);
    final android = _local.resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      const channel = fln.AndroidNotificationChannel(
        'fcm_default',
        'FCM Notifications',
        description: 'Firebase Cloud Messaging notifications',
        importance: fln.Importance.max,
      );
      await android.createNotificationChannel(channel);
    }
    _initialized = true;
  }

  Future<void> showFromMessage(RemoteMessage message) async {
    await initialize();
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    const details = fln.NotificationDetails(
      android: fln.AndroidNotificationDetails(
        'fcm_default',
        'FCM Notifications',
        channelDescription: 'Firebase Cloud Messaging notifications',
        importance: fln.Importance.max,
        priority: fln.Priority.max,
      ),
    );
    await _local.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }
}
