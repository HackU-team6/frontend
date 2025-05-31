import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_airpods/models/attitude.dart';
import 'package:nekoze_notify/provider/notification_settings_provider.dart';
import '../provider/posture_monitoring_provider.dart';
import '../services/airpods_motion_service.dart';
import '../services/posture_analyzer.dart';
import '../constants/app_constants.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  StreamSubscription<Attitude>? _attitudeSubscription;

  double _currentPitch = 0.0;
  double _currentYaw = 0.0;
  double _currentRoll = 0.0;
  double? _baselinePitch;
  double _pitchDifference = 0.0;
  DateTime? _poorPostureSince;
  DateTime? _lastNotificationTime;
  Duration _confirmDuration = AppConstants.defaultConfirmDuration;
  Duration _interval = AppConstants.defaultNotificationInterval;

  final List<String> _eventLog = [];

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _attitudeSubscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    _attitudeSubscription = AirPodsMotionService.attitude$().listen((attitude) {
      setState(() {
        _currentPitch = attitude.pitch.toDouble();
        _currentRoll = attitude.roll.toDouble();
        _currentYaw = attitude.yaw.toDouble();

        // ベースラインピッチを取得
        final analyzer = ref.read(postureMonitoringProvider.notifier);
        _baselinePitch = analyzer.baselinePitch;

        if (_baselinePitch != null) {
          _pitchDifference = _baselinePitch! - _currentPitch;
        }

        final settings = ref.read(notificationSettingsProvider);
        _confirmDuration = Duration(
          seconds: settings.delay.round(),
        );
        _interval = Duration(
          seconds: settings.interval.round(),
        );
      });
    });
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _eventLog.insert(0, '$timestamp: $message');
      if (_eventLog.length > 50) {
        _eventLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(postureMonitoringProvider);

    // 状態変更を監視してログに追加
    ref.listen<PostureMonitoringState>(
      postureMonitoringProvider,
          (previous, next) {
        if (previous?.postureState != next.postureState) {
          _addLog('姿勢状態: ${next.postureState == PostureState.good ? "良好" : "悪い"}');
        }
        if (previous?.isMonitoring != next.isMonitoring) {
          _addLog('モニタリング: ${next.isMonitoring ? "開始" : "停止"}');
        }
        if (next.error != null && previous?.error != next.error) {
          _addLog('エラー: ${next.error!.message}');
        }
      },
    );

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

              // 状態カード
              _StatusCard(
                monitoringState: monitoringState,
                currentPitch: _currentPitch,
                currentRoll: _currentRoll,
                currentYaw: _currentYaw,
                baselinePitch: _baselinePitch,
                pitchDifference: _pitchDifference,
                poorPostureSince: _poorPostureSince,
                lastNotificationTime: _lastNotificationTime,
                confirmDuration: _confirmDuration,
                interval: _interval,
              ),

              const SizedBox(height: 20),

              // コントロールボタン
              _ControlButtons(
                isMonitoring: monitoringState.isMonitoring,
                onStartStop: () {
                  final notifier = ref.read(postureMonitoringProvider.notifier);
                  if (monitoringState.isMonitoring) {
                    notifier.stopMonitoring();
                  } else {
                    notifier.startMonitoring();
                  }
                },
                onCalibrate: () async {
                  final notifier = ref.read(postureMonitoringProvider.notifier);
                  await notifier.calibrate();
                  _addLog('キャリブレーション実行');
                },
                onClearLog: () {
                  setState(() {
                    _eventLog.clear();
                  });
                },
              ),

              const SizedBox(height: 20),

              // ビジュアライゼーションとログ
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ビジュアライゼーション
                    Expanded(
                      flex: 1,
                      child: _VisualizationCard(
                        baselinePitch: _baselinePitch,
                        currentPitch: _currentPitch,
                        currentRoll: _currentRoll,
                        currentYaw: _currentYaw,
                        thresholdRad: AppConstants.postureThresholdDegrees * math.pi / 180,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // イベントログ
                    Expanded(
                      flex: 1,
                      child: _EventLogCard(eventLog: _eventLog),
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

class _StatusCard extends StatelessWidget {
  final PostureMonitoringState monitoringState;
  final double currentPitch;
  final double currentRoll;
  final double currentYaw;
  final double? baselinePitch;
  final double pitchDifference;
  final DateTime? poorPostureSince;
  final DateTime? lastNotificationTime;
  final Duration confirmDuration;
  final Duration interval;

  const _StatusCard({
    required this.monitoringState,
    required this.currentPitch,
    required this.currentRoll,
    required this.currentYaw,
    required this.baselinePitch,
    required this.pitchDifference,
    required this.poorPostureSince,
    required this.lastNotificationTime,
    required this.confirmDuration,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(
              label: '解析状態',
              value: monitoringState.isMonitoring ? "実行中" : "停止中",
              valueColor: monitoringState.isMonitoring ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 8),
            _StatusRow(
              label: '姿勢状態',
              value: monitoringState.postureState == PostureState.good ? "良好" : "悪い",
              valueColor: monitoringState.postureState == PostureState.good
                  ? Colors.green
                  : Colors.red,
            ),
            const SizedBox(height: 8),
            _StatusRow(
              label: '現在のピッチ値',
              value: '${currentPitch.toStringAsFixed(4)} rad',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              label: '現在のヨー値',
              value: '${currentYaw.toStringAsFixed(4)} rad',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              label: '現在のロール値',
              value: '${currentRoll.toStringAsFixed(4)} rad',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              label: '基準ピッチ値',
              value: baselinePitch != null
                  ? '${baselinePitch!.toStringAsFixed(4)} rad'
                  : '未設定',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              label: 'ピッチ差分',
              value: '${pitchDifference.toStringAsFixed(4)} rad',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              label: '閾値',
              value: '${AppConstants.postureThresholdDegrees}度 '
                  '(${(AppConstants.postureThresholdDegrees * math.pi / 180).toStringAsFixed(4)} rad)',
            ),
            const Divider(height: 24),
            const Text('通知設定:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _StatusRow(
              label: '確定時間',
              value: '$confirmDuration秒',
            ),
            const SizedBox(height: 4),
            _StatusRow(
              label: '通知間隔',
              value: '$interval秒',
            ),
            if (poorPostureSince != null) ...[
              const SizedBox(height: 8),
              _StatusRow(
                label: '姿勢悪化継続時間',
                value: '${DateTime.now().difference(poorPostureSince!).inSeconds}秒',
                valueColor: Colors.red,
              ),
            ],
            if (lastNotificationTime != null) ...[
              const SizedBox(height: 8),
              _StatusRow(
                label: '前回通知からの経過',
                value: '${DateTime.now().difference(lastNotificationTime!).inSeconds}秒',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final bool isMonitoring;
  final VoidCallback onStartStop;
  final VoidCallback onCalibrate;
  final VoidCallback onClearLog;

  const _ControlButtons({
    required this.isMonitoring,
    required this.onStartStop,
    required this.onCalibrate,
    required this.onClearLog,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: onStartStop,
          icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
          label: Text(isMonitoring ? '停止' : '開始'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isMonitoring ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: onCalibrate,
          icon: const Icon(Icons.tune),
          label: const Text('キャリブレーション'),
        ),
        ElevatedButton.icon(
          onPressed: onClearLog,
          icon: const Icon(Icons.clear_all),
          label: const Text('ログクリア'),
        ),
      ],
    );
  }
}

class _VisualizationCard extends StatelessWidget {
  final double? baselinePitch;
  final double currentPitch;
  final double currentRoll;
  final double currentYaw;
  final double thresholdRad;

  const _VisualizationCard({
    required this.baselinePitch,
    required this.currentPitch,
    required this.currentRoll,
    required this.currentYaw,
    required this.thresholdRad,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                child: baselinePitch == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'キャリブレーションを\n実行してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
                    : CustomPaint(
                  size: const Size(200, 200),
                  painter: PostureVisualizationPainter(
                    currentPitch: currentPitch,
                    currentRoll: currentRoll,
                    currentYaw: currentYaw,
                    baselinePitch: baselinePitch,
                    thresholdRad: thresholdRad,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventLogCard extends StatelessWidget {
  final List<String> eventLog;

  const _EventLogCard({required this.eventLog});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'イベントログ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: eventLog.isEmpty
                  ? const Center(
                child: Text(
                  'ログはありません',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: eventLog.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      eventLog[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostureVisualizationPainter extends CustomPainter {
  final double currentPitch;
  final double currentRoll;
  final double currentYaw;
  final double? baselinePitch;
  final double thresholdRad;

  PostureVisualizationPainter({
    required this.currentPitch,
    required this.currentRoll,
    required this.currentYaw,
    this.baselinePitch,
    required this.thresholdRad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // 背景円
    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    if (baselinePitch != null) {
      // ベースラインを描画
      final baselinePaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final baselineAngle = baselinePitch! - math.pi / 2;
      final baselineEnd = Offset(
        center.dx + radius * 1.2 * math.cos(baselineAngle),
        center.dy + radius * 1.2 * math.sin(baselineAngle),
      );
      canvas.drawLine(center, baselineEnd, baselinePaint);

      // 閾値ラインを描画
      final thresholdPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final thresholdAngle = baselinePitch! - thresholdRad - math.pi / 2;
      final thresholdEnd = Offset(
        center.dx + radius * 1.2 * math.cos(thresholdAngle),
        center.dy + radius * 1.2 * math.sin(thresholdAngle),
      );
      canvas.drawLine(center, thresholdEnd, thresholdPaint);
    }

    // 現在のピッチを描画
    final currentPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final currentAngle = currentPitch - math.pi / 2;
    final currentEnd = Offset(
      center.dx + radius * math.cos(currentAngle),
      center.dy + radius * math.sin(currentAngle),
    );
    canvas.drawLine(center, currentEnd, currentPaint);

    // 頭部アイコンを描画
    final headPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(currentEnd, 5.0, headPaint);
  }

  @override
  bool shouldRepaint(covariant PostureVisualizationPainter oldDelegate) {
    return currentPitch != oldDelegate.currentPitch ||
        baselinePitch != oldDelegate.baselinePitch ||
        thresholdRad != oldDelegate.thresholdRad;
  }
}
