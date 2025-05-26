import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_airpods/models/attitude.dart';
import '../services/posture_analyzer.dart';
import '../services/airpods_motion_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final PostureAnalyzer _analyzer = PostureAnalyzer();
  StreamSubscription<PostureState>? _postureSubscription;
  StreamSubscription<Attitude>? _attitudeSubscription;

  PostureState _currentPostureState = PostureState.good;
  double _currentPitch = 0.0;
  double? _baselinePitch;
  double _pitchDifference = 0.0;
  bool _isAnalyzing = false;
  DateTime? _poorPostureSince;
  DateTime? _lastNotificationTime;

  // Log for tracking state changes and notifications
  final List<String> _eventLog = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _stopAnalyzing();
    super.dispose();
  }

  Future<void> _startAnalyzing() async {
    if (_isAnalyzing) return;

    final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS
    setState(() {
      _eventLog.add('$timestamp: 解析開始');
    });

    try {
      // Try to load calibration, if it fails, perform calibration
      bool hasCalibration = await _analyzer.loadCalibration();
      if (!hasCalibration) {
        setState(() {
          _eventLog.add('$timestamp: キャリブレーションが必要');
        });
        await _analyzer.calibrate();
      }

      // Get the baseline pitch from storage
      await _analyzer.loadCalibration();

      // Use the calibration value from the analyzer instead of overwriting it
      final calibrationPitch = _analyzer.baselinePitch;

      if (calibrationPitch != null) {
        // Use the loaded calibration value
        setState(() {
          _baselinePitch = calibrationPitch;
          _eventLog.add('$timestamp: 保存された基準ピッチを読み込み: ${calibrationPitch.toStringAsFixed(4)} rad');
        });
      }

      // Start the analyzer
      await _analyzer.start();

      // Listen to posture state changes
      _postureSubscription = _analyzer.state$.listen((state) {
        final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS
        setState(() {
          _currentPostureState = state;
          _eventLog.add('$timestamp: 姿勢状態変更 → ${state == PostureState.good ? "良好" : "悪い"}');

          // Keep log at a reasonable size
          if (_eventLog.length > 20) {
            _eventLog.removeAt(0);
          }
        });
      });

      // Listen to attitude updates to display raw data and simulate notification logic
      _attitudeSubscription = AirPodsMotionService.attitude$().listen((attitude) {
        final now = DateTime.now();
        final timestamp = now.toString().substring(11, 19); // HH:MM:SS

        setState(() {
          _currentPitch = attitude.pitch.toDouble();
          _pitchDifference = _baselinePitch != null ? (_baselinePitch! - _currentPitch) : 0.0;

          // Simulate the notification logic from PostureAnalyzer
          if (_baselinePitch != null) {
            final thresholdRad = _analyzer.thresholdDeg * math.pi / 180;
            final overThreshold = _pitchDifference > thresholdRad;

            if (overThreshold) {
              // Start tracking poor posture time
              _poorPostureSince ??= now;

              // Check if poor posture has continued long enough to trigger notification
              if (_poorPostureSince != null && 
                  now.difference(_poorPostureSince!) >= _analyzer.confirmDuration) {

                // Check if we should send a notification (based on interval)
                final needNotify = _analyzer.isNotificationEnabled && 
                    (_lastNotificationTime == null || 
                     now.difference(_lastNotificationTime!) >= _analyzer.notificationInterval);

                if (needNotify && _currentPostureState == PostureState.poor) {
                  _lastNotificationTime = now;
                  _eventLog.add('$timestamp: 通知トリガー - 姿勢悪化が続いています');
                }
              }
            } else {
              // Reset poor posture tracking
              if (_poorPostureSince != null) {
                _poorPostureSince = null;
              }
            }
          }
        });
      });

      setState(() {
        _isAnalyzing = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _stopAnalyzing() {
    final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS

    _postureSubscription?.cancel();
    _attitudeSubscription?.cancel();
    // _analyzer.dispose(); // これを使わない
    _analyzer.reset(); // 新しいメソッドを使用



    setState(() {
      _isAnalyzing = false;
      _poorPostureSince = null;
      _lastNotificationTime = null;
      _eventLog.add('$timestamp: 解析停止');
    });
  }

  Future<void> _calibrate() async {
    final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS

    setState(() {
      _eventLog.add('$timestamp: キャリブレーション開始');
    });

    try {
      await _analyzer.calibrate();
      await _analyzer.loadCalibration();

      // Get the calibration value from the analyzer
      final calibrationPitch = _analyzer.baselinePitch;

      if (calibrationPitch != null) {
        setState(() {
          _baselinePitch = calibrationPitch;
          _eventLog.add('$timestamp: キャリブレーション完了 - 基準ピッチ: ${calibrationPitch.toStringAsFixed(4)} rad');
        });
      } else {
        setState(() {
          _eventLog.add('$timestamp: キャリブレーションエラー - 基準ピッチが取得できませんでした');
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('キャリブレーション完了')),
      );
    } catch (e) {
      setState(() {
        _eventLog.add('$timestamp: キャリブレーションエラー - ${e.toString()}');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('デバッグ画面'),
        backgroundColor: const Color(0xFFB3E9D6),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FDFA), Color(0xFFE2F6FB)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PostureAnalyzer デバッグ情報',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('解析状態: ${_isAnalyzing ? "実行中" : "停止中"}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('姿勢状態: '),
                          Text(
                            '${_currentPostureState == PostureState.good ? "良好" : "悪い"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _currentPostureState == PostureState.good 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('現在のピッチ値: ${_currentPitch.toStringAsFixed(4)} rad'),
                      const SizedBox(height: 8),
                      Text('基準ピッチ値: ${_baselinePitch?.toStringAsFixed(4) ?? "未設定"} rad'),
                      const SizedBox(height: 8),
                      Text('ピッチ差分: ${_pitchDifference.toStringAsFixed(4)} rad'),
                      const SizedBox(height: 8),
                      Text('閾値: ${_analyzer.thresholdDeg} 度 (${(_analyzer.thresholdDeg * 3.14159 / 180).toStringAsFixed(4)} rad)'),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('通知設定:'),
                      const SizedBox(height: 8),
                      Text('  確定時間: ${_analyzer.confirmDuration.inSeconds} 秒'),
                      const SizedBox(height: 4),
                      Text('  通知間隔: ${_analyzer.notificationInterval.inSeconds} 秒'),
                      const SizedBox(height: 8),
                      if (_poorPostureSince != null)
                        Text(
                          '姿勢悪化継続時間: ${DateTime.now().difference(_poorPostureSince!).inSeconds} 秒',
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (_lastNotificationTime != null)
                        Text(
                          '前回通知からの経過時間: ${DateTime.now().difference(_lastNotificationTime!).inSeconds} 秒',
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isAnalyzing ? _stopAnalyzing : _startAnalyzing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnalyzing ? Colors.red : Colors.green,
                    ),
                    child: Text(_isAnalyzing ? '停止' : '開始'),
                  ),
                  ElevatedButton(
                    onPressed: _calibrate,
                    child: const Text('キャリブレーション'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Visualization and Log
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Visualization
                    Expanded(
                      flex: 1,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '姿勢視覚化',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Center(
                                  child: _baselinePitch == null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.info_outline, size: 48, color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'キャリブレーションを実行してください',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        )
                                      : CustomPaint(
                                          size: const Size(200, 200),
                                          painter: PostureVisualizationPainter(
                                            currentPitch: _currentPitch,
                                            baselinePitch: _baselinePitch,
                                            thresholdRad: _analyzer.thresholdDeg * 3.14159 / 180,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Event Log
                    Expanded(
                      flex: 1,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'イベントログ',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.clear_all, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _eventLog.clear();
                                      });
                                    },
                                    tooltip: 'ログをクリア',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _eventLog.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'ログはありません',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _eventLog.length,
                                        reverse: true,
                                        itemBuilder: (context, index) {
                                          final logEntry = _eventLog[_eventLog.length - 1 - index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: Text(
                                              logEntry,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostureVisualizationPainter extends CustomPainter {
  final double currentPitch;
  final double? baselinePitch;
  final double thresholdRad;

  PostureVisualizationPainter({
    required this.currentPitch,
    this.baselinePitch,
    required this.thresholdRad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw circle
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    // Draw baseline line if available
    if (baselinePitch != null) {
      final baselinePaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final baselineAngle = baselinePitch! - 3.14159 / 2; // Adjust to make 0 point up
      final baselineX = center.dx + radius * 1.2 * math.cos(baselineAngle);
      final baselineY = center.dy + radius * 1.2 * math.sin(baselineAngle);

      canvas.drawLine(center, Offset(baselineX, baselineY), baselinePaint);

      // Draw threshold lines
      final thresholdPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final thresholdAngle = baselinePitch! - thresholdRad - 3.14159 / 2;
      final thresholdX = center.dx + radius * 1.2 * math.cos(thresholdAngle);
      final thresholdY = center.dy + radius * 1.2 * math.sin(thresholdAngle);

      canvas.drawLine(center, Offset(thresholdX, thresholdY), thresholdPaint);
    }

    // Draw current pitch line
    final currentPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final currentAngle = currentPitch - 3.14159 / 2; // Adjust to make 0 point up
    final currentX = center.dx + radius * math.cos(currentAngle);
    final currentY = center.dy + radius * math.sin(currentAngle);

    canvas.drawLine(center, Offset(currentX, currentY), currentPaint);

    // Draw head icon at the end of the current line
    final headPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(currentX, currentY), 5.0, headPaint);
  }

  @override
  bool shouldRepaint(covariant PostureVisualizationPainter oldDelegate) {
    return currentPitch != oldDelegate.currentPitch ||
           baselinePitch != oldDelegate.baselinePitch ||
           thresholdRad != oldDelegate.thresholdRad;
  }
}
