import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../provider/notification_settings_provider.dart';
import '../provider/posture_monitoring_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/option_cards.dart';
import '../constants/app_constants.dart';
import 'debug_screen.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _measureController;
  bool _isMeasuring = false;
  bool _measureFinished = false;

  @override
  void initState() {
    super.initState();
    _measureController = AnimationController(
      vsync: this,
      duration: AppConstants.calibrationDuration,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isMeasuring = false;
          _measureFinished = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _measureController.dispose();
    super.dispose();
  }

  Future<void> _startMeasurement() async {
    setState(() {
      _isMeasuring = true;
      _measureFinished = false;
    });

    _measureController.forward(from: 0);

    // キャリブレーションを実行
    final notifier = ref.read(postureMonitoringProvider.notifier);
    await notifier.calibrate();
  }

  @override
  Widget build(BuildContext context) {
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final monitoringState = ref.watch(postureMonitoringProvider);

    // エラー表示
    ref.listen<PostureMonitoringState>(
      postureMonitoringProvider,
          (previous, next) {
        if (next.error != null && previous?.error != next.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    Widget calibrationArea;
    if (_isMeasuring) {
      calibrationArea = AnimatedBuilder(
        animation: _measureController,
        builder: (context, _) {
          return _MeasuringCard(progress: _measureController.value);
        },
      );
    } else if (_measureFinished || monitoringState.isCalibrated) {
      calibrationArea = _MeasurementFinishedCard(
        onReMeasure: _startMeasurement,
      );
    } else {
      calibrationArea = _CalibrationCard(
        onMeasureStart: _startMeasurement,
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FDFA), Color(0xFFE2F6FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  '姿勢キャリブレーション',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text('あなたの正しい姿勢を記録して基準を設定します'),
                const SizedBox(height: 32),

                calibrationArea,

                const SizedBox(height: 32),

                _NotificationSettingsSection(
                  enableNotification: notificationSettings.enableNotification,
                  notificationDelay: notificationSettings.delay,
                  notificationInterval: notificationSettings.interval,
                  onEnableChanged: (v) => ref
                      .read(notificationSettingsProvider.notifier)
                      .setEnable(v),
                  onDelayChanged: (v) => ref
                      .read(notificationSettingsProvider.notifier)
                      .setDelay(v),
                  onIntervalChanged: (v) => ref
                      .read(notificationSettingsProvider.notifier)
                      .setInterval(v),
                ),

                const SizedBox(height: 32),

                if (kDebugMode) ...[
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    '開発者向け',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DebugScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('デバッグ画面を開く'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  final VoidCallback onMeasureStart;

  const _CalibrationCard({
    required this.onMeasureStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF00B68F), Color(0xFF1DB0E9)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.person_outline, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '姿勢を測定',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              '正しい姿勢で座り、測定ボタンを押してください',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          GradientButton(
            text: '測定開始',
            icon: Icons.radio_button_checked,
            onPressed: onMeasureStart,
          ),
        ],
      ),
    );
  }
}

class _MeasuringCard extends StatelessWidget {
  final double progress;

  const _MeasuringCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).round();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 100,
                  backgroundColor: const Color(0xFFE5E9EC),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00B68F)),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '測定中...\n背筋を伸ばしたまま動かないでください',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _MeasurementFinishedCard extends StatelessWidget {
  final VoidCallback onReMeasure;

  const _MeasurementFinishedCard({
    required this.onReMeasure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 80,
            color: Color(0xFF00B68F),
          ),
          const SizedBox(height: 24),
          const Text(
            '測定が完了しました',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: '再測定',
            icon: Icons.replay,
            onPressed: onReMeasure,
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsSection extends StatelessWidget {
  final bool enableNotification;
  final double notificationDelay;
  final double notificationInterval;
  final ValueChanged<bool> onEnableChanged;
  final ValueChanged<double> onDelayChanged;
  final ValueChanged<double> onIntervalChanged;

  const _NotificationSettingsSection({
    required this.enableNotification,
    required this.notificationDelay,
    required this.notificationInterval,
    required this.onEnableChanged,
    required this.onDelayChanged,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: const [
              Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF00B68F),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '通知設定',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        SwitchOptionCard(
          title: '通知設定',
          subtitle: '猫背を検知した際に通知',
          value: enableNotification,
          onChanged: onEnableChanged,
        ),

        if (enableNotification) ...[
          const SizedBox(height: 24),
          SliderOptionCard(
            title: '通知までの秒数',
            subtitle: '猫背を検知してから通知を送るまでの\n待機時間',
            value: notificationDelay,
            min: 1,
            max: 30,
            divisions: 29,
            unit: '秒',
            onChanged: onDelayChanged,
          ),
          const SizedBox(height: 24),
          SliderOptionCard(
            title: '通知間隔',
            subtitle: '通知と次の通知の間に空ける時間',
            value: notificationInterval,
            min: 10,
            max: 300,
            divisions: 29,
            unit: '秒',
            onChanged: onIntervalChanged,
          ),
        ],
      ],
    );
  }
}

final BoxDecoration _cardDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: const Color(0xFFB5E5D8), width: 1),
  color: Colors.white,
  boxShadow: [
    BoxShadow(
      color: Colors.black12.withOpacity(0.05),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ],
);