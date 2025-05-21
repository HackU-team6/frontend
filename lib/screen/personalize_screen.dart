import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nekoze_notify/actons/get-gryo.dart';
import 'package:nekoze_notify/services/calibration_service.dart';

class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({super.key});

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  // 計測状態を管理する変数
  bool _isCalibrating = false;
  int _calibrationTimeLeft = 5; // 5秒間の計測
  String _statusMessage = '';
  bool _showSuccess = false;

  // 計測用のタイマー
  Timer? _calibrationTimer;

  // キャリブレーションサービス
  final _calibrationService = CalibrationService();

  // キャリブレーションの状態を購読するためのStreamSubscription
  StreamSubscription? _calibrationStatusSubscription;

  @override
  void initState() {
    super.initState();

    // キャリブレーションの状態変化を監視
    _calibrationStatusSubscription = _calibrationService.calibrationStatus.listen((status) {
      switch (status) {
        case CalibrationStatus.started:
          setState(() {
            _isCalibrating = true;
            _statusMessage = '計測中...';
            _showSuccess = false;
          });
          break;
        case CalibrationStatus.completed:
          setState(() {
            _isCalibrating = false;
            _statusMessage = '計測完了！正しい姿勢の基準値を保存しました。';
            _showSuccess = true;
          });
          break;
        case CalibrationStatus.error:
          setState(() {
            _isCalibrating = false;
            _statusMessage = 'エラー: データの取得または保存に失敗しました。再試行してください。';
            _showSuccess = false;
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    // リソースを解放
    _calibrationTimer?.cancel();
    _calibrationStatusSubscription?.cancel();
    _calibrationService.dispose();
    super.dispose();
  }

  // 計測を開始する関数
  void _startCalibration() async {
    // 既に計測中なら何もしない
    if (_isCalibrating) return;

    setState(() {
      _calibrationTimeLeft = 5;
      _statusMessage = '計測中... $_calibrationTimeLeft 秒';
    });

    // カウントダウンタイマーを開始
    _calibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _calibrationTimeLeft--;
        if (_isCalibrating) {
          _statusMessage = '計測中... $_calibrationTimeLeft 秒';
        }
      });

      // タイマー終了
      if (_calibrationTimeLeft <= 0) {
        timer.cancel();
      }
    });

    // キャリブレーションを開始
    _calibrationService.startCalibration(
      AirPodsMotionService.gyroStream(),
      durationInSeconds: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('姿勢をパーソナライズ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'リラックスした“正しい姿勢”で座り、\n「計測開始」を押して 5 秒間キープしてください。',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // 計測状態の表示
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _showSuccess ? Colors.green : Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // 計測中のプログレスインジケーター
            if (_isCalibrating)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: (5 - _calibrationTimeLeft) / 5,
                  ),
                ],
              ),

            const SizedBox(height: 40),

            // 計測開始ボタン
            ElevatedButton(
              onPressed: _isCalibrating ? null : _startCalibration,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(_isCalibrating ? "計測中..." : "計測開始"),
            ),

            // 計測完了後の戻るボタン
            if (_showSuccess)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("ホーム画面に戻る"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
