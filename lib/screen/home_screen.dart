import 'package:flutter/material.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nekoze_notify/actons/get-gryo.dart';
import 'package:nekoze_notify/main.dart';
import 'package:nekoze_notify/models/posture_data.dart';
import 'package:nekoze_notify/screen/personalize_screen.dart';
import 'package:nekoze_notify/services/posture_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // PostureServiceのインスタンス
  final _postureService = PostureService();

  // 保存されたキャリブレーションデータ
  PostureData? _calibrationData;

  @override
  void initState() {
    super.initState();

    // 保存されたキャリブレーションデータを取得
    _loadCalibrationData();
  }

  // キャリブレーションデータを読み込む
  Future<void> _loadCalibrationData() async {
    final data = await _postureService.getCalibrationData();
    setState(() {
      _calibrationData = data;
    });
  }

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
              onPressed: () async {
                // パーソナライズ画面に遷移
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalizeScreen(),
                  ),
                );

                // 画面に戻ってきたらキャリブレーションデータを再読み込み
                _loadCalibrationData();
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
            // 現在のジャイロ値を表示
            Center(
              child: Column(
                children: [
                  const Text(
                    "現在のジャイロ値:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<RotationRate>(
                    stream: AirPodsMotionService.gyroStream(),
                    builder: (BuildContext context,
                        AsyncSnapshot<RotationRate> snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                            "x: ${snapshot.data!.x.toStringAsFixed(4)},\n"
                            "y: ${snapshot.data!.y.toStringAsFixed(4)},\n"
                            "z: ${snapshot.data!.z.toStringAsFixed(4)}");
                      } else {
                        return const Text("Waiting for incoming data");
                      }
                    },
                  ),
                ],
              ),
            ),

            // 保存された基準値を表示（デバッグ用）
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "保存された基準値（デバッグ用）:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _loadCalibrationData,
                        tooltip: '再読み込み',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_calibrationData != null) ...[
                    Text(
                      "x: ${_calibrationData!.referencePosture.x.toStringAsFixed(4)},\n"
                      "y: ${_calibrationData!.referencePosture.y.toStringAsFixed(4)},\n"
                      "z: ${_calibrationData!.referencePosture.z.toStringAsFixed(4)}",
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "計測日時: ${_calibrationData!.calibrationTime.toString()}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ] else
                    const Text("キャリブレーションデータがありません"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
