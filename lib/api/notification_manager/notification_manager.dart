import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:safelattice/api/database_manager/database_manager.dart';
import 'package:safelattice/data/models/event.dart';
import 'package:safelattice/data/models/user.dart';
import 'package:safelattice/data/utils/global_data.dart';
import 'package:safelattice/presentation/screens/event_screen.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  static final _fcm = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _onMessageStream;
  StreamSubscription<RemoteMessage>? _onMessageOpenStream;
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationManager() => _instance;

  NotificationManager._internal();

  Future<String?> getFcmToken() async {
    return Platform.isAndroid ? await _fcm.getToken() : null;
  }

  Future<bool> notifyUsers(
      {required List<SlUser> users, required Event event}) async {
    List<String> fcmTokens =
        await DatabaseManager().getFcmTokensForUsers(users: users);

    if (fcmTokens.isEmpty) return false;

    fcmTokens
        .removeWhere((token) => token == GlobalData().currentUser!.fcmToken);

    const postUrl = 'https://fcm.googleapis.com/fcm/send';

    Map<dynamic, dynamic> jsonData = event.toJson();
    jsonData.addAll({"click_action": "FLUTTER_NOTIFICATION_CLICK"});

    final data = {
      "registration_ids": fcmTokens,
      "priority": "high",
      "notification": {
        "title": 'Emergency Alert!',
        "body":
            '${event.initiatedUser.username} initiated an emergency alert. Click to view.',
      },
      "data": jsonData,
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization':
          'key=AAAAQMvxnsQ:APA91bEVPASrXS8kYqYF3NGvHWx83iThB7x0xIPNpVhxW4O9ARvCmOgfQufFztikocHlFSMkclOssFfjq8e7--GDloYOAuMWLp37avoovzMkfv_lxmYlib8jKnuBW1XHCDDD77j7-Bn9'
    };

    final response = await http.post(
      Uri.parse(postUrl),
      body: json.encode(data),
      encoding: Encoding.getByName('utf-8'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      debugPrint('Notification successfully pushed.');
      return true;
    } else {
      debugPrint('Notification push unsuccessful.');
      return false;
    }
  }

  Future<void> initFcm() async {
    String? newToken = await NotificationManager().getFcmToken() ?? "";

    await DatabaseManager().updateFcmToken(
        fbId: GlobalData().currentUser!.fbUserId!, newToken: newToken);

    _onMessageStream = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        handleRemoteNotification(message);
      },
    );

    _onMessageOpenStream = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        handleRemoteNotification(message);
      },
    );

    FirebaseMessaging.onBackgroundMessage(handleBackgroundNotification);
  }

  Future<void> disposeFcm() async {
    await _onMessageStream?.cancel();
    await _onMessageOpenStream?.cancel();
  }

  Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('mipmap/launcher_icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (message) {
      if (GlobalData().currentUser != null) {
        Event newEvent = Event.fromJson(json: json.decode(message.payload!));

        Navigator.push(
            GlobalData().navigatorKey.currentContext!,
            MaterialPageRoute(
                builder: (context) => EventScreen(event: newEvent)));
      }
    });
  }

  Future<void> pushLocalNotification(
      {required String title, required String message, String? payload}) async {
    if (Platform.isAndroid) {
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails('safe_lattice_notification_channel',
              'safe_lattice_notification_channel',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker');

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await _flutterLocalNotificationsPlugin
          .show(0, title, message, notificationDetails, payload: payload);
    }
  }

  Future<void> handleRemoteNotification(RemoteMessage message) async {
    if (GlobalData().currentUser != null) {
      Event newEvent = Event.fromJson(json: message.data);

      Navigator.push(
          GlobalData().navigatorKey.currentContext!,
          MaterialPageRoute(
              builder: (context) => EventScreen(event: newEvent)));
    }
  }
}

Future<void> handleBackgroundNotification(RemoteMessage message) async {
  Event newEvent = Event.fromJson(json: message.data);

  NotificationManager().pushLocalNotification(
    title: "Emergency Alert!",
    message:
        "${newEvent.initiatedUser.username} initiated an emergency alert. Click to view.",
    payload: json.encode(message.data),
  );
}
