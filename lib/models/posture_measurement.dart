import 'package:flutter_airpods/models/attitude.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';

/// 単一の姿勢測定データを表すモデルクラス
class PostureMeasurement {
  /// ジャイロデータ（回転速度）
  final RotationRate gyro;

  /// 姿勢データ（ピッチ、ロール、ヨー、クォータニオン）
  final Attitude attitude;

  /// 測定日時
  final DateTime timestamp;

  /// コンストラクタ
  PostureMeasurement({
    required this.gyro,
    required this.attitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 文字列表現を返す
  @override
  String toString() {
    return 'PostureMeasurement(gyro: $gyro, attitude: $attitude, timestamp: $timestamp)';
  }

  /// SharedPreferencesから読み込むためのファクトリメソッド
  factory PostureMeasurement.fromSharedPreferences(Map<String, dynamic> data) {
    return PostureMeasurement(
      gyro: data['gyro'] as RotationRate,
      attitude: data['attitude'] as Attitude,
      timestamp: data['timestamp'] != null 
          ? DateTime.parse(data['timestamp'] as String) 
          : null,
    );
  }

  /// SharedPreferencesに保存するためのマップに変換
  Map<String, dynamic> toMap() {
    return {
      'gyro': gyro,
      'attitude': attitude,
      'timestamp': timestamp.toString(),
    };
  }
}