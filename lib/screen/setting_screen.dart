import 'package:flutter/material.dart';
import 'debug_screen.dart';

class SettingScreen extends StatefulWidget {
  final VoidCallback onStartPressed;
  final VoidCallback onNotifyPressed;
  const SettingScreen({
    super.key,
    required this.onStartPressed,
    required this.onNotifyPressed,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  bool _enableNotification = true;
  double _notificationDelay = 3;
  double _notificationInterval = 60;

  // --- measurement animation (★追加)
  late final AnimationController _measureController;
  bool _isMeasuring = false;
  bool _measureFinished = false;

  @override
  void initState() {
    super.initState();
    _measureController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _measureFinished = false;
    });
    _measureController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget calibrationArea;
    if (_isMeasuring) {
      calibrationArea = AnimatedBuilder(
        animation: _measureController,
        builder: (context, _) {
          return _MeasuringCard(progress: _measureController.value);
        },
      );
    } else if (_measureFinished) {
      calibrationArea = _MeasurementFinishedCard(
        onReMeasure: _startMeasurement,
      );
    } else {
      calibrationArea = _CalibrationCard(onMeasureStart: _startMeasurement);
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
                  enableNotification: _enableNotification,
                  notificationDelay: _notificationDelay,
                  notificationInterval: _notificationInterval,
                  onEnableChanged:
                      (v) => setState(() => _enableNotification = v),
                  onDelayChanged: (v) => setState(() => _notificationDelay = v),
                  onIntervalChanged:
                      (v) => setState(() => _notificationInterval = v),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  '開発者向け',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: const Text(
                    'デバッグ画面を開く',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.onStartPressed,
                  child: const Text('作業を開始する'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: widget.onNotifyPressed,
                  child: const Text('通知を出す'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  final VoidCallback onMeasureStart; // ★追加
  const _CalibrationCard({super.key, required this.onMeasureStart});

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
          _GradientButton(
            text: '測定開始',
            icon: Icons.radio_button_unchecked,
            onPressed: onMeasureStart, // ★変更
          ),
        ],
      ),
    );
  }
}

class _MeasuringCard extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  const _MeasuringCard({super.key, required this.progress});

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
            '測定中...背筋を伸ばしたまま動かないでください',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 共通部品
// ============================================================
class _GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  const _GradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF00B68F), Color(0xFF1DB0E9)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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

class _NotificationSettingsSection extends StatelessWidget {
  final bool enableNotification;
  final double notificationDelay;
  final double notificationInterval;
  final ValueChanged<bool> onEnableChanged;
  final ValueChanged<double> onDelayChanged;
  final ValueChanged<double> onIntervalChanged;

  const _NotificationSettingsSection({
    super.key,
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
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: const Color(0xFF00B68F),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '通知設定',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SwitchOptionCard(
          title: '通知設定',
          subtitle: '猫背を検知した際に通知',
          value: enableNotification,
          onChanged: onEnableChanged,
        ),
        if (enableNotification) ...[
          const SizedBox(height: 24),
          _SliderOptionCard(
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
          _SliderOptionCard(
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

class _SwitchOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
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
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00B68F),
          ),
        ],
      ),
    );
  }
}

class _SliderOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.round()}$unit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.round()}$unit',
            activeColor: const Color(0xFF00B68F),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MeasurementFinishedCard extends StatelessWidget {
  final VoidCallback onReMeasure;
  const _MeasurementFinishedCard({super.key, required this.onReMeasure});

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
            '測定が終了しました',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _GradientButton(
            text: '再測定',
            icon: Icons.replay,
            onPressed: onReMeasure,
          ),
        ],
      ),
    );
  }
}
