import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nekoze_notify/nekoze_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeNotifications();
  runApp(const ProviderScope(child: NekozeApp()));
}

Future<void> _initializeNotifications() async {
  const DarwinInitializationSettings darwinSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  const InitializationSettings initSettings = InitializationSettings(
    iOS: darwinSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}
