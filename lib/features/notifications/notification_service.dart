import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    // Whole flow is guarded so a missing APNs/native config (e.g. iOS Simulator)
    // can never crash startup or freeze the UI.
    try {
      await requestPermissions();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      await _createNotificationChannel();

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }

      await saveTokenToFirestore();
    } catch (e) {
      debugPrint('NotificationService.initialize skipped: $e');
    }
  }

  Future<void> requestPermissions() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> saveTokenToFirestore() async {
    // On iOS, FCM.getToken() requires an APNs token first. Without one (e.g. the
    // Simulator, or before native push config is complete) it throws — so check
    // for the APNs token and skip gracefully instead of crashing.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _fcm.getAPNSToken();
      if (apnsToken == null) {
        debugPrint('APNs token unavailable — skipping FCM token fetch.');
        return;
      }
    }

    final String? token = await _fcm.getToken();
    final User? user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // 🔥 Unified ID
      'High Importance Notifications',
      description: 'Notifications for likes, replies, and updates',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? route,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // 🔥 Fixed: Must match channel registration
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: route,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // 🔥 Fixed: Match the channel explicitly
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data['route'], // Passes payload properly on foreground tap
      );
    }
  }


  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;

    if (payload != null && payload.isNotEmpty) {
      _navigatorKey?.currentState?.pushNamed(payload);
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final String? route = message.data['route'];

    if (route != null && route.isNotEmpty) {
      _navigatorKey?.currentState?.pushNamed(route);
    }
  }
}