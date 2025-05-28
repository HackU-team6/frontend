import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class PostureIndicator extends StatefulWidget {
  final bool isGoodPosture;
  final bool isMonitoring;

  const PostureIndicator({
    super.key,
    required this.isGoodPosture,
    required this.isMonitoring,
  });

  @override
  State<PostureIndicator> createState() => _PostureIndicatorState();
}

class _PostureIndicatorState extends State<PostureIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: AppConstants.rotationAnimationDuration,
    );
  }

  @override
  void didUpdateWidget(PostureIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMonitoring && !oldWidget.isMonitoring) {
      _rotationController.repeat();
    } else if (!widget.isMonitoring && oldWidget.isMonitoring) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMonitoring) {
      return const _IdleIndicator();
    }

    final config = widget.isGoodPosture
        ? _IndicatorConfig.good()
        : _IndicatorConfig.poor();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // 背景の円
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFDDF0EF),
                  valueColor: AlwaysStoppedAnimation<Color>(config.color),
                ),
              ),
              // 回転するインジケーター
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: config.progressValue,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFDDF0EF),
                        valueColor: AlwaysStoppedAnimation<Color>(config.color),
                      ),
                    ),
                  );
                },
              ),
              // 中央のアイコンとテキスト
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: config.gradientColors,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    config.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _IdleIndicator extends StatelessWidget {
  const _IdleIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.watch_later_outlined,
            size: 100,
            color: Color(0xFF6D6D6D),
          ),
          SizedBox(height: 8),
          Text(
            '待機中',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF6D6D6D),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorConfig {
  final Color color;
  final double progressValue;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;

  const _IndicatorConfig({
    required this.color,
    required this.progressValue,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
  });

  factory _IndicatorConfig.good() => const _IndicatorConfig(
    color: Color(0xFF40CA95),
    progressValue: 0.25,
    gradientColors: [Color(0xFF13BD85), Color(0xFF2FCE95)],
    title: '良い姿勢です！',
    subtitle: 'キープしましょう！',
  );

  factory _IndicatorConfig.poor() => const _IndicatorConfig(
    color: Color(0xFFECA631),
    progressValue: 0.75,
    gradientColors: [Color(0xFFF48B21), Color(0xFFF1603B)],
    title: '姿勢に注意',
    subtitle: '背筋を伸ばしましょう',
  );
}