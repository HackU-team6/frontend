class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class AirPodsNotConnectedException extends AppException {
  AirPodsNotConnectedException() : super('AirPods Proが接続されていません');
}

class CalibrationRequiredException extends AppException {
  CalibrationRequiredException() : super('キャリブレーションが必要です');
}

class CalibrationFailedException extends AppException {
  CalibrationFailedException([String? details])
      : super('キャリブレーションに失敗しました${details != null ? ': $details' : ''}');
}

class NotificationPermissionDeniedException extends AppException {
  NotificationPermissionDeniedException() : super('通知権限が許可されていません');
}

class SensorDataException extends AppException {
  SensorDataException([String? details])
      : super('センサーデータの取得に失敗しました${details != null ? ': $details' : ''}');
}
