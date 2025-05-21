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
  String _statusMessage = '';
  bool _showSuccess = false;
  double _progress = 0.0; // 進捗状況（0.0〜1.0）

  // キャリブレーションサービス
  final _calibrationService = CalibrationService();

  // キャリブレーションの状態を購読するためのStreamSubscription
  StreamSubscription? _calibrationStatusSubscription;
  // 進捗状況を更新するためのタイマー
  Timer? _progressTimer;

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
            _progress = 0.0;
          });

          // 進捗状況を更新するタイマーを開始（0.1秒ごとに更新）
          _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
            if (_isCalibrating) {
              setState(() {
                // 5秒間で進捗を0から1まで増加（0.1秒ごとに0.02ずつ増加）
                _progress += 0.02;
                if (_progress >= 1.0) {
                  _progress = 1.0;
                }
              });
            } else {
              timer.cancel();
            }
          });
          break;
        case CalibrationStatus.completed:
          setState(() {
            _isCalibrating = false;
            _statusMessage = '計測完了！正しい姿勢の基準値を保存しました。';
            _showSuccess = true;
            _progress = 1.0;
          });
          _progressTimer?.cancel();
          break;
        case CalibrationStatus.error:
          setState(() {
            _isCalibrating = false;
            _statusMessage = 'エラー: データの取得または保存に失敗しました。再試行してください。';
            _showSuccess = false;
          });
          _progressTimer?.cancel();
          break;
      }
    });
  }

  @override
  void dispose() {
    // リソースを解放
    _progressTimer?.cancel();
    _calibrationStatusSubscription?.cancel();
    _calibrationService.dispose();
    super.dispose();
  }

  // 計測を開始する関数
  void _startCalibration() async {
    // 既に計測中なら何もしない
    if (_isCalibrating) return;

    setState(() {
      _statusMessage = '計測中...';
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
                    value: _progress,
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
