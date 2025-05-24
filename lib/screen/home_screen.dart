// lib/screens/home_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/posture_analyzer.dart';
import '../services/airpods_motion_service.dart';
import 'package:flutter_airpods/models/attitude.dart';

final _notifications = FlutterLocalNotificationsPlugin();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _analyzer = PostureAnalyzer();
  PostureState? _currentState;

  @override
  void initState() {
    super.initState();
    _initNotif();
  }

  Future<void> _initNotif() async {
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(const InitializationSettings(iOS: ios));
  }

  Future<void> _showNotif(String body) async {
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
    await _notifications.show(0, '姿勢アラート', body, details);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('猫背チェッカー')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // キャリブレーション
            ElevatedButton(
              onPressed: () async {
                await _analyzer.calibrate();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('キャリブレーション完了')),
                );
              },
              child: const Text('正しい姿勢を登録'),
            ),
            // 計測開始
            ElevatedButton(
              onPressed: () async {
                await _analyzer.start();
                _analyzer.state$.listen((s) {
                  setState(() => _currentState = s);
                  if (s == PostureState.poor) {
                    _showNotif('猫背になっています！背筋を伸ばしましょう');
                  }
                });
              },
              child: const Text('計測開始'),
            ),
            const SizedBox(height: 20),
            Text(
              '現在の姿勢: ${_currentState == null ? '---' : _currentState == PostureState.good ? '良' : '猫背'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Divider(),
            // モニタ用に pitch 角度を表示
            StreamBuilder<Attitude>(
              stream: AirPodsMotionService.attitude$(),
              builder: (context, snap) {
                if (!snap.hasData) return const Text('接続待ち…');
                final deg = snap.data!.pitch * 180 / math.pi;
                return Text('pitch: ${deg.toStringAsFixed(2)}°');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _analyzer.dispose();
    super.dispose();
  }
}
