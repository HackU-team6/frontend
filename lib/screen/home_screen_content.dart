import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nekoze_notify/widgets/airpods_status_card.dart';
import '../provider/posture_monitoring_provider.dart';
import '../services/posture_analyzer.dart';
import '../widgets/posture_indicator.dart';
import '../exceptions/app_exceptions.dart';

class HomeScreenContent extends ConsumerWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringState = ref.watch(postureMonitoringProvider);
    final monitoringNotifier = ref.read(postureMonitoringProvider.notifier);

    // エラー表示
    ref.listen<PostureMonitoringState>(postureMonitoringProvider, (
      previous,
      next,
    ) {
      if (next.error != null && previous?.error != next.error) {
        _showErrorSnackBar(context, next.error!);
      }
    });

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FDFA), Color(0xFFE2F6FB)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _HeaderSection(),
            Expanded(
              flex: 4,
              child: PostureIndicator(
                isGoodPosture:
                    monitoringState.postureState == PostureState.good,
                isMonitoring: monitoringState.isMonitoring,
              ),
            ),
            const SizedBox(height: 30),
            const AirPodsStatusCard(),
            const SizedBox(height: 16),
            _MonitoringButton(
              isMonitoring: monitoringState.isMonitoring,
              isCalibrated: monitoringState.isCalibrated,
              onPressed:
                  () => _handleMonitoringButton(
                    context,
                    ref,
                    monitoringState,
                    monitoringNotifier,
                  ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Future<void> _handleMonitoringButton(
    BuildContext context,
    WidgetRef ref,
    PostureMonitoringState state,
    PostureMonitoringNotifier notifier,
  ) async {
    if (state.isMonitoring) {
      // 停止
      notifier.stopMonitoring();
    } else {
      // 開始
      if (!state.isCalibrated) {
        final shouldCalibrate = await _showCalibrationDialog(context);
        if (shouldCalibrate == true) {
          await notifier.calibrate();
        } else {
          return;
        }
      }

      await notifier.startMonitoring();
    }
  }

  static Future<bool?> _showCalibrationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('キャリブレーションが必要です'),
            content: const Text(
              'AirPods Proを装着し、背筋を伸ばした状態で「キャリブレーション」を押してください。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('キャリブレーション'),
              ),
            ],
          ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, AppException error) {
    final message = _getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static String _getErrorMessage(AppException error) {
    if (error is AirPodsNotConnectedException) {
      return 'AirPods Proを接続してください';
    } else if (error is CalibrationRequiredException) {
      return 'キャリブレーションを実行してください';
    } else if (error is NotificationPermissionDeniedException) {
      return '通知権限を許可してください';
    } else {
      return error.message;
    }
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(height: 20),
        Text(
          "PostureGuard",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0AB3A1),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'AirPods Proで姿勢を見守る',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF6D6D6D),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

class _MonitoringButton extends StatelessWidget {
  final bool isMonitoring;
  final bool isCalibrated;
  final VoidCallback onPressed;

  const _MonitoringButton({
    required this.isMonitoring,
    required this.isCalibrated,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 52),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isMonitoring ? Colors.red.shade400 : const Color(0xFF0AB3A1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
          ),
          child: Text(
            isMonitoring ? '作業停止' : '作業を開始する',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
