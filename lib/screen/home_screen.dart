import 'package:flutter/material.dart';
import 'package:flutter_airpods/models/attitude.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nekoze_notify/actons/get-gyro.dart';
import 'package:nekoze_notify/main.dart';
import 'package:nekoze_notify/models/posture_measurement.dart';
import 'package:nekoze_notify/screen/personalize_screen.dart';
import 'package:nekoze_notify/services/calibration_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // キャリブレーションサービスのインスタンス
  final _calibrationService = CalibrationService();

  // 保存されたキャリブレーションデータ
  PostureMeasurement? _calibrationData;

  @override
  void initState() {
    super.initState();

    // 初期化時に保存されたデータがあれば読み込む
    _loadCalibrationData();
  }

  // 保存されたキャリブレーションデータを読み込む
  Future<void> _loadCalibrationData() async {
    final data = await _calibrationService.getCalibrationData();
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalizeScreen(),
                  ),
                ).then((_) {
                  // パーソナライズ画面から戻ってきたらデータを再読み込み
                  _loadCalibrationData();
                });
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

            // 現在のセンサー値表示
            const SizedBox(height: 20),
            const Text('現在のセンサー値:', style: TextStyle(fontWeight: FontWeight.bold)),
            Center(
              child: StreamBuilder<RotationRate>(
                stream: AirPodsMotionService.gyroStream(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<RotationRate> snapshot,
                ) {
                  if (snapshot.hasData) {
                    return Text(
                      "x: ${snapshot.data!.x},\n y: ${snapshot.data!.y},\n z: ${snapshot.data!.z}",
                    );
                  } else {
                    return const Text("AirPodsが接続されていません。");
                  }
                },
              ),
            ),
            Center(
              child: StreamBuilder<Attitude>(
                stream: AirPodsMotionService.attitudeStream(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<Attitude> snapshot,
                ) {
                  if (snapshot.hasData) {
                    return Text(
                      "pitch: ${snapshot.data!.pitch},\n roll: ${snapshot.data!.roll},\n yaw: ${snapshot.data!.yaw}",
                    );
                  } else {
                    return const Text("AirPodsが接続されていません。");
                  }
                },
              ),
            ),

            // キャリブレーションデータ表示（デバッグ用）
            if (_calibrationData != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                'デバッグ情報：保存されたキャリブレーションデータ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // ジャイロデータ
              Text(
                'ジャイロ: X=${_calibrationData!.gyro.x.toStringAsFixed(4)}, '
                'Y=${_calibrationData!.gyro.y.toStringAsFixed(4)}, '
                'Z=${_calibrationData!.gyro.z.toStringAsFixed(4)}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),

              // 姿勢データ
              Text(
                '姿勢: Roll=${_calibrationData!.attitude.roll.toStringAsFixed(4)}, '
                'Pitch=${_calibrationData!.attitude.pitch.toStringAsFixed(4)}, '
                'Yaw=${_calibrationData!.attitude.yaw.toStringAsFixed(4)}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),

              // タイムスタンプ
              Text(
                '計測日時: ${_calibrationData!.timestamp}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),

              // 再読み込みボタン
              TextButton(
                onPressed: _loadCalibrationData,
                child: const Text('キャリブレーションデータを再読み込み'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
