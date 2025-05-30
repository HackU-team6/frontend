class AppConstants {
  // 姿勢検知の設定
  static const int postureThresholdDegrees = 8;
  static const Duration averageWindow = Duration(milliseconds: 500);
  static const Duration defaultConfirmDuration = Duration(seconds: 3);
  static const Duration defaultNotificationInterval = Duration(seconds: 60);

  // センサー設定
  static const int airPodsUpdateFrequency = 25; // Hz
  static const int sensorSamplingRate = 25; // Hz (実際の処理頻度)

  // UI設定
  static const Duration calibrationDuration = Duration(seconds: 3);
  static const Duration rotationAnimationDuration = Duration(seconds: 2);

  // 通知設定
  static const String notificationChannelId = 'posture_channel';
  static const String notificationChannelName = '姿勢通知';
  static const String notificationChannelDescription = '姿勢が崩れたときの通知チャネル';
  static const String notificationTitle = '姿勢が崩れています';
  static const String notificationBody = '背筋を伸ばしましょう！';

  // 接続確認設定
  static const Duration airPodsConnectionCheckInterval = Duration(seconds: 5); // 秒

  // rollとyawの閾値
  static const double yawMaxThreshold = 0.9;
  static const double rollMaxThreshold = 0.75; 
  static const double yawMinThreshold = -0.13;
  static const double rollMinThreshold = -0.1;
}
