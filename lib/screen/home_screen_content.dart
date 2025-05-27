import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nekoze_notify/provider/posture_analyzer_provider.dart';
import 'package:nekoze_notify/services/posture_analyzer.dart';

class HomeScreenContent extends ConsumerStatefulWidget {
  const HomeScreenContent({super.key});

  @override
  ConsumerState<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends ConsumerState<HomeScreenContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  StreamSubscription<PostureState>? _postureSub;
  PostureState _currentState = PostureState.good;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _postureSub?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final notificationSettings = ref.watch(notificationSettingsProvider);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FDFA), Color(0xFFE2F6FB)],
        ),
      ),
      child: Center(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                "PostureGuard",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0AB3A1),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AirPods Proで姿勢を見守る',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF6D6D6D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                flex: 4,
                child: !_isMonitoring
                    ? const _IdleComponent()
                    : (_currentState == PostureState.poor
                        ? const _PosturePoorComponent()
                        : const _PostureGoodComponent()),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(
                      Icons.headset,
                      color: Color(0xFF12B981),
                    ),
                    title: const Text(
                      'AirPods Pro',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('接続済み'),
                    trailing: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF12B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 52, right: 52, bottom: 50),
                child: SizedBox(
                  height: 40,
                  width: 110,
                  child: ElevatedButton(
                    onPressed: () async {
                      final analyzer = ref.read(postureAnalyzerProvider);
                      if (!_isMonitoring) {
                        // start monitoring
                        final calibrated = await analyzer.loadCalibration();
                        if (!calibrated) {
                          debugPrint('PostureAnalyzer: キャリブレーション未実施');
                          return showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('キャリブレーションが必要です'),
                                content: const Text(
                                  'AirPods Proを装着し、背筋を伸ばしてから「キャリブレーション」を押してください。',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      await analyzer.calibrate();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('キャリブレーション'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        debugPrint('PostureAnalyzer: キャリブレーション済み');
                        await analyzer.start();
                        _postureSub?.cancel();
                        _postureSub = analyzer.state$.listen((s) {
                          if (!mounted) return;
                          setState(() => _currentState = s);
                        });
                      } else {
                        // stop monitoring
                        _postureSub?.cancel();
                        analyzer.reset();
                        setState(() {
                          _isMonitoring = false;
                          _currentState = PostureState.good;
                        });
                        return;
                      }
                      setState(() => _isMonitoring = true);
                    },
                    child: Text(
                      _isMonitoring ? '作業停止' : '作業を開始する',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0AB3A1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // const Text(
              //   '📡 通知設定デバッグ',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 8),
              // Text(
              //   '通知: ${notificationSettings.enableNotification ? "ON" : "OFF"}',
              // ),
              // Text('通知までの遅延: ${notificationSettings.delay.round()} 秒'),
              // Text('通知間隔: ${notificationSettings.interval.round()} 秒'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosturePoorComponent extends StatefulWidget {
  const _PosturePoorComponent({super.key});

  @override
  State<_PosturePoorComponent> createState() => _PosturePoorComponentState();
}

class _PosturePoorComponentState extends State<_PosturePoorComponent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  backgroundColor: Color(0xFFDDF0EF),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFECA631)),
                ),
              ),
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFDDF0EF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFECA631),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFF48B21), Color(0xFFF1603B)],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '姿勢に注意',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '背筋を伸ばしましょう',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6D6D6D)),
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

class _PostureGoodComponent extends StatefulWidget {
  const _PostureGoodComponent({super.key});

  @override
  State<_PostureGoodComponent> createState() => _PostureGoodComponentState();
}

class _PostureGoodComponentState extends State<_PostureGoodComponent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  backgroundColor: Color(0xFFDDF0EF),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF40CA95)),
                ),
              ),
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: 0.25,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFDDF0EF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF40CA95),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF13BD85), Color(0xFF2FCE95)],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '良い姿勢です！',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'キープしましょう！',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6D6D6D)),
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

class _IdleComponent extends StatelessWidget {
  const _IdleComponent({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.watch_later_outlined, size: 100, color: Color(0xFF6D6D6D)),
          SizedBox(height: 8),
          Text('待機中', style: TextStyle(fontSize: 20, color: Color(0xFF6D6D6D))),
        ],
      ),
    );
  }
}

