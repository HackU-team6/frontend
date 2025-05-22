import 'package:flutter/material.dart';
import 'package:nekoze_notify/actons/get-gyro.dart';
import 'package:nekoze_notify/services/calibration_service.dart';

class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({super.key});

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  // キャリブレーションサービスのインスタンス
  final _calibrationService = CalibrationService();

  // キャリブレーションの状態
  CalibrationStatus _status = CalibrationStatus.notStarted;

  // 進行状況（0.0〜1.0）
  double _progress = 0.0;

  // ステータスメッセージ
  String _statusMessage = '';

  // 保存されたキャリブレーションデータ
  Map<String, dynamic> _calibrationData = {};

  @override
  void initState() {
    super.initState();

    // キャリブレーションの状態を監視
    _calibrationService.statusStream.listen((status) {
      setState(() {
        _status = status;

        // 状態に応じてメッセージを更新
        switch (status) {
          case CalibrationStatus.notStarted:
            _statusMessage = '';
            break;
          case CalibrationStatus.inProgress:
            _statusMessage = '計測中...';
            break;
          case CalibrationStatus.completed:
            _statusMessage = '計測完了！正しい姿勢が保存されました。';
            _loadCalibrationData(); // 保存されたデータを読み込む
            break;
          case CalibrationStatus.error:
            _statusMessage = 'エラーが発生しました。AirPodsが接続されているか確認してください。';
            break;
        }
      });
    });

    // 進行状況を監視
    _calibrationService.progressStream.listen((progress) {
      setState(() {
        _progress = progress;
      });
    });

    // 初期化時に保存されたデータがあれば読み込む
    _loadCalibrationData();
  }

  @override
  void dispose() {
    _calibrationService.dispose();
    super.dispose();
  }

  // キャリブレーションを開始
  void _startCalibration() {
    // 既に計測中なら何もしない
    if (_status == CalibrationStatus.inProgress) return;

    // 進行状況をリセット
    setState(() {
      _progress = 0.0;
      _statusMessage = '';
    });

    // キャリブレーションを開始
    _calibrationService.startCalibration(
      gyroStream: AirPodsMotionService.gyroStream(),
      attitudeStream: AirPodsMotionService.attitudeStream(),
      durationInSeconds: 5,
    );
  }

  // 保存されたキャリブレーションデータを読み込む
  Future<void> _loadCalibrationData() async {
    final data = await _calibrationService.getCalibrationData();
    setState(() {
      _calibrationData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('姿勢をパーソナライズ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'リラックスした“正しい姿勢”で座り、\n「計測開始」を押して 5 秒間キープしてください。',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // 進行状況インジケーター（計測中のみ表示）
            if (_status == CalibrationStatus.inProgress)
              Column(
                children: [
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text('${(_progress * 100).toInt()}%'),
                ],
              ),

            // ステータスメッセージ
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _status == CalibrationStatus.error
                        ? Colors.red
                        : _status == CalibrationStatus.completed
                            ? Colors.green
                            : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 40),

            // 計測開始ボタン
            ElevatedButton(
              onPressed: _status == CalibrationStatus.inProgress
                  ? null // 計測中は無効化
                  : _startCalibration,
              child: const Text("計測開始"),
            ),

            const SizedBox(height: 40),

            // デバッグ用：保存されたキャリブレーションデータの表示
            if (_calibrationData.isNotEmpty) ...[
              const Divider(),
              const Text(
                'デバッグ情報：保存されたキャリブレーションデータ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // ジャイロデータ
              if (_calibrationData['gyro'] != null)
                Text(
                  'ジャイロ: X=${_calibrationData['gyro'].x.toStringAsFixed(4)}, '
                  'Y=${_calibrationData['gyro'].y.toStringAsFixed(4)}, '
                  'Z=${_calibrationData['gyro'].z.toStringAsFixed(4)}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),

              // 姿勢データ
              if (_calibrationData['attitude'] != null)
                Text(
                  '姿勢: Roll=${_calibrationData['attitude'].roll.toStringAsFixed(4)}, '
                  'Pitch=${_calibrationData['attitude'].pitch.toStringAsFixed(4)}, '
                  'Yaw=${_calibrationData['attitude'].yaw.toStringAsFixed(4)}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),

              // タイムスタンプ
              if (_calibrationData['timestamp'] != null)
                Text(
                  '計測日時: ${_calibrationData['timestamp']}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
