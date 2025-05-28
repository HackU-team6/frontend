// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:nekoze_notify/services/posture_analyzer.dart';
// import 'notification_settings_provider.dart';
//
// final postureAnalyzerProvider = Provider<PostureAnalyzer>((ref) {
//
//   final analyzer = PostureAnalyzer(
//     thresholdDeg: 8,
//     avgWindow: const Duration(milliseconds: 500),
//     shouldNotify: () => ref.read(notificationSettingsProvider).enableNotification,
//     getConfirmDuration: () => Duration(seconds: ref.read(notificationSettingsProvider).delay.round()),
//     getNotificationInterval: () => Duration(seconds: ref.read(notificationSettingsProvider).interval.round()),
//   );
//
//   // Defer the start of the analyzer to a user-driven action.
//   ref.onDispose(() => analyzer.dispose());
//
//   ref.listen<NotificationSettings>(
//     notificationSettingsProvider,
//       (_, next) => analyzer.updateSettings(
//           shouldNotify: () =>  next.enableNotification,
//           getConfirmDuration: () => Duration(seconds: next.delay.round()),
//           getNotificationInterval: () => Duration(seconds: next.interval.round()),
//       ),
//   );
//
//   return analyzer;
// });
