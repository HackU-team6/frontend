class AppConstants {
  // 姿勢検知の設定
  static const int postureThresholdDegrees = 8;
  static const Duration averageWindow = Duration(milliseconds: 500);
  static const Duration defaultConfirmDuration = Duration(seconds: 3);
  static const Duration defaultNotificationInterval = Duration(seconds: 60);

  // センサー設定
  static const int airPodsUpdateFrequency = 60; // Hz
  static const int sensorSamplingRate = 10; // Hz (実際の処理頻度)

  // UI設定
  static const Duration calibrationDuration = Duration(seconds: 3);
  static const Duration rotationAnimationDuration = Duration(seconds: 2);

  // 通知設定
  static const String notificationChannelId = 'posture_channel';
  static const String notificationChannelName = '姿勢通知';
  static const String notificationChannelDescription = '姿勢が崩れたときの通知チャネル';
  static const String notificationTitle = '姿勢が崩れています';
  static const String notificationBody = '背筋を伸ばしましょう！';
}
