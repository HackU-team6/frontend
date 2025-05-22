import 'dart:async';
import 'package:flutter_airpods/models/attitude.dart';
import 'package:flutter_airpods/models/quaternion.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:nekoze_notify/models/posture_measurement.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// キャリブレーションの状態を表す列挙型
enum CalibrationStatus {
  /// キャリブレーションが開始されていない
  notStarted,

  /// 準備中（待機時間）
  preparing,

  /// キャリブレーション中
  inProgress,

  /// キャリブレーション完了
  completed,

  /// エラーが発生
  error,
}

/// ユーザーの正しい姿勢をキャリブレーションするためのサービス
class CalibrationService {
  /// キャリブレーションの状態を通知するためのストリームコントローラー
  final _statusController = StreamController<CalibrationStatus>.broadcast();

  /// キャリブレーションの進行状況（0.0〜1.0）を通知するためのストリームコントローラー
  final _progressController = StreamController<double>.broadcast();

  /// キャリブレーションの状態を取得するためのストリーム
  Stream<CalibrationStatus> get statusStream => _statusController.stream;

  /// キャリブレーションの進行状況を取得するためのストリーム
  Stream<double> get progressStream => _progressController.stream;

  /// 現在のキャリブレーションの状態
  CalibrationStatus _currentStatus = CalibrationStatus.notStarted;

  /// キャリブレーションの状態を取得
  CalibrationStatus get status => _currentStatus;

  /// キャリブレーションを開始する
  /// 
  /// [gyroStream] ジャイロデータのストリーム
  /// [attitudeStream] 姿勢データのストリーム
  /// [durationInSeconds] キャリブレーションの時間（秒）
  /// [delayInSeconds] 測定開始前の待機時間（秒）
  Future<void> startCalibration({
    required Stream<RotationRate> gyroStream,
    required Stream<Attitude> attitudeStream,
    int durationInSeconds = 5,
    int delayInSeconds = 2,
  }) async {
    if (_currentStatus == CalibrationStatus.inProgress) {
      return; // 既にキャリブレーション中なら何もしない
    }

    // 準備中の状態に更新
    _updateStatus(CalibrationStatus.preparing);

    try {
      // 計測用のデータ保存リスト
      final List<RotationRate> gyroData = [];
      final List<Attitude> attitudeData = [];

      // 待機時間と測定時間の合計を計算
      final delayTimeInMillis = delayInSeconds * 1000;
      final measureTimeInMillis = durationInSeconds * 1000;
      final totalTimeInMillis = delayTimeInMillis + measureTimeInMillis;
      final updateInterval = 100; // 100ミリ秒ごとに進行状況を更新

      // 進行状況の更新用の変数
      int elapsedTimeInMillis = 0;

      // 待機時間（この間はデータを収集しない）
      while (elapsedTimeInMillis < delayTimeInMillis) {
        await Future.delayed(Duration(milliseconds: updateInterval));
        elapsedTimeInMillis += updateInterval;

        // 進行状況を更新（0.0〜1.0）
        final progress = elapsedTimeInMillis / totalTimeInMillis;
        _progressController.add(progress);
      }

      // 測定中の状態に更新
      _updateStatus(CalibrationStatus.inProgress);

      // ジャイロデータのサブスクリプション（待機時間後に開始）
      final gyroSubscription = gyroStream.listen((data) {
        gyroData.add(data);
      });

      // 姿勢データのサブスクリプション（待機時間後に開始）
      final attitudeSubscription = attitudeStream.listen((data) {
        attitudeData.add(data);
      });

      // 指定された時間だけデータを収集
      final startMeasureTime = elapsedTimeInMillis;
      while (elapsedTimeInMillis < totalTimeInMillis) {
        await Future.delayed(Duration(milliseconds: updateInterval));
        elapsedTimeInMillis += updateInterval;

        // 進行状況を更新（0.0〜1.0）
        final progress = elapsedTimeInMillis / totalTimeInMillis;
        _progressController.add(progress);
      }

      // サブスクリプションをキャンセル
      await gyroSubscription.cancel();
      await attitudeSubscription.cancel();

      // データが収集できなかった場合はエラー
      if (gyroData.isEmpty || attitudeData.isEmpty) {
        _updateStatus(CalibrationStatus.error);
        return;
      }

      // 平均値を計算
      final avgGyro = _calculateAverageGyro(gyroData);
      final avgAttitude = _calculateAverageAttitude(attitudeData);

      // データを保存
      await _saveCalibrationData(avgGyro, avgAttitude);

      // 完了状態に更新
      _updateStatus(CalibrationStatus.completed);
    } catch (e) {
      _updateStatus(CalibrationStatus.error);
    }
  }

  /// ジャイロデータの平均値を計算
  RotationRate _calculateAverageGyro(List<RotationRate> data) {
    if (data.isEmpty) {
      return RotationRate(0, 0, 0);
    }

    double sumX = 0, sumY = 0, sumZ = 0;

    for (var item in data) {
      sumX += item.x;
      sumY += item.y;
      sumZ += item.z;
    }

    return RotationRate(
      sumX / data.length,
      sumY / data.length,
      sumZ / data.length,
    );
  }

  /// 姿勢データの平均値を計算
  Attitude _calculateAverageAttitude(List<Attitude> data) {
    if (data.isEmpty) {
      return Attitude(Quaternion(0, 0, 0, 0), 0, 0, 0);
    }

    double sumRoll = 0, sumPitch = 0, sumYaw = 0;
    double sumQuatX = 0, sumQuatY = 0, sumQuatZ = 0, sumQuatW = 0;

    for (var item in data) {
      sumRoll += item.roll;
      sumPitch += item.pitch;
      sumYaw += item.yaw;

      sumQuatX += item.quaternion.x;
      sumQuatY += item.quaternion.y;
      sumQuatZ += item.quaternion.z;
      sumQuatW += item.quaternion.w;
    }

    return Attitude(
      Quaternion(
        sumQuatX / data.length,
        sumQuatY / data.length,
        sumQuatZ / data.length,
        sumQuatW / data.length,
      ),
      sumPitch / data.length,
      sumRoll / data.length,
      sumYaw / data.length,
    );
  }

  /// キャリブレーションデータを保存
  Future<void> _saveCalibrationData(RotationRate gyro, Attitude attitude) async {
    final prefs = await SharedPreferences.getInstance();

    // PostureMeasurementオブジェクトを作成
    final measurement = PostureMeasurement(
      gyro: gyro,
      attitude: attitude,
    );

    // ジャイロデータを保存
    await prefs.setDouble('calibration_gyro_x', gyro.x.toDouble());
    await prefs.setDouble('calibration_gyro_y', gyro.y.toDouble());
    await prefs.setDouble('calibration_gyro_z', gyro.z.toDouble());

    // 姿勢データを保存
    await prefs.setDouble('calibration_roll', attitude.roll.toDouble());
    await prefs.setDouble('calibration_pitch', attitude.pitch.toDouble());
    await prefs.setDouble('calibration_yaw', attitude.yaw.toDouble());

    // クォータニオンを保存
    await prefs.setDouble('calibration_quat_x', attitude.quaternion.x.toDouble());
    await prefs.setDouble('calibration_quat_y', attitude.quaternion.y.toDouble());
    await prefs.setDouble('calibration_quat_z', attitude.quaternion.z.toDouble());
    await prefs.setDouble('calibration_quat_w', attitude.quaternion.w.toDouble());

    // 保存日時を記録
    await prefs.setString('calibration_timestamp', measurement.timestamp.toString());
  }

  /// 保存されたキャリブレーションデータを取得
  Future<PostureMeasurement?> getCalibrationData() async {
    final prefs = await SharedPreferences.getInstance();

    // データが存在しない場合はnullを返す
    if (!prefs.containsKey('calibration_timestamp')) {
      return null;
    }

    // ジャイロデータを取得
    final gyroX = prefs.getDouble('calibration_gyro_x') ?? 0;
    final gyroY = prefs.getDouble('calibration_gyro_y') ?? 0;
    final gyroZ = prefs.getDouble('calibration_gyro_z') ?? 0;

    // 姿勢データを取得
    final roll = prefs.getDouble('calibration_roll') ?? 0;
    final pitch = prefs.getDouble('calibration_pitch') ?? 0;
    final yaw = prefs.getDouble('calibration_yaw') ?? 0;

    // クォータニオンを取得
    final quatX = prefs.getDouble('calibration_quat_x') ?? 0;
    final quatY = prefs.getDouble('calibration_quat_y') ?? 0;
    final quatZ = prefs.getDouble('calibration_quat_z') ?? 0;
    final quatW = prefs.getDouble('calibration_quat_w') ?? 0;

    // タイムスタンプを取得
    final timestampStr = prefs.getString('calibration_timestamp') ?? '';
    final timestamp = DateTime.tryParse(timestampStr);

    // PostureMeasurementオブジェクトを作成して返す
    return PostureMeasurement(
      gyro: RotationRate(gyroX, gyroY, gyroZ),
      attitude: Attitude(
        Quaternion(quatX, quatY, quatZ, quatW),
        pitch,
        roll,
        yaw,
      ),
      timestamp: timestamp,
    );
  }

  /// キャリブレーションデータが存在するかチェック
  Future<bool> hasCalibrationData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('calibration_timestamp');
  }

  /// キャリブレーションの状態を更新
  void _updateStatus(CalibrationStatus newStatus) {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  /// リソースを解放
  void dispose() {
    _statusController.close();
    _progressController.close();
  }
}
