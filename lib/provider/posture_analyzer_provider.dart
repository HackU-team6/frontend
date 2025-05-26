import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nekoze_notify/services/posture_analyzer.dart';
import 'notification_settings_provider.dart';

final postureAnalyzerProvider = Provider<PostureAnalyzer>((ref) {
  final settings = ref.watch(notificationSettingsProvider);

  return PostureAnalyzer(
    thresholdDeg: 8,
    confirmDuration: Duration(seconds: settings.delay.round()),
    notificationInterval: Duration(seconds: settings.interval.round()),
    isNotificationEnabled: settings.enableNotification,
  );
});
