import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nekoze_notify/main.dart';
import 'package:nekoze_notify/screen/personalize_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _showPostureNotification() async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(iOS: iosDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '猫背通知',
      '猫背になっています！正しい姿勢で作業を心がけましょう！',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: ユーザーが座り始めたことを通知したので、ジャイロ値を1分おきに取ってくる関数を実装する
              },
              child: const Text('作業を開始する'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalizeScreen(),
                  ),
                );
              },
              child: const Text(
                'パーソナライズ画面に移動(デバッグ時のみ)',
              ), // TODO: 後々、アプリを最初に起動した時にのみ開くように実装
            ),
            ElevatedButton(
              onPressed: () {
                _showPostureNotification();
              },
              child: Text('通知を出す'),
            ),
          ],
        ),
      ),
    );
  }
}
