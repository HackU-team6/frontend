import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettings {
  final bool enableNotification;
  final double delay;
  final double interval;

  const NotificationSettings({
    required this.enableNotification,
    required this.delay,
    required this.interval,
  });

  NotificationSettings copyWith({
    bool? enableNotification,
    double? delay,
    double? interval,
  }) => NotificationSettings(
    enableNotification: enableNotification ?? this.enableNotification,
    delay: delay ?? this.delay,
    interval: interval ?? this.interval,
  );
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier()
    : super(
        const NotificationSettings(
          enableNotification: true,
          delay: 3,
          interval: 60,
        ),
      );

  void setEnable(bool v) => state = state.copyWith(enableNotification: v);

  void setDelay(double v) => state = state.copyWith(delay: v);

  void setInterval(double v) => state = state.copyWith(interval: v);
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      (ref) => NotificationSettingsNotifier(),
    );
