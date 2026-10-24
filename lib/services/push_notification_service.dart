import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'appwrite_service.dart';

/// Registers each signed-in Android app with Appwrite Messaging and displays
/// FCM alerts while the app is in the foreground.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _channelId = 'deep_care_updates';
  static const _channelName = 'Deep Care updates';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  VoidCallback? _onNotificationTap;
  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> initialize({required VoidCallback onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_initialized) return;
    if (_initializing != null) return _initializing;

    _initializing = _initializeAndroid();
    await _initializing;
    _initializing = null;
  }

  Future<void> _initializeAndroid() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notifications were not permitted.');
        return;
      }

      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (_) => _onNotificationTap?.call(),
      );
      final androidNotifications = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidNotifications?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Booking and care service alerts.',
          importance: Importance.high,
        ),
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (_) => _onNotificationTap?.call(),
      );
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _onNotificationTap?.call();

      // Appwrite targets use the FCM registration token.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await _registerToken(token);
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(_registerToken);
      _initialized = true;
    } on Object catch (error) {
      debugPrint('Phone notifications could not start: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await AppwriteService.instance.registerPushTarget(token);
    } on Object catch (error) {
      debugPrint('Could not register this device with Appwrite: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
      title: notification.title ?? 'Deep Care update',
      body: notification.body ?? 'There is an update to your care booking.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Booking and care service alerts.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['type']?.toString(),
    );
  }
}
