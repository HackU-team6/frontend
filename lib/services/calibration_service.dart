import 'dart:async';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:nekoze_notify/services/posture_service.dart';

/// キャリブレーションプロセスを管理するサービスクラス
/// 
/// 指定された秒数間ジャイロデータを収集し、平均値を計算して保存します。
class CalibrationService {
  /// PostureServiceのインスタンス
  final PostureService _postureService = PostureService();
  
  /// キャリブレーション中かどうかを示すフラグ
  bool _isCalibrating = false;
  
  /// キャリブレーション中に収集したジャイロデータ
  final List<RotationRate> _collectedGyroData = [];
  
  /// キャリブレーションの状態を通知するためのコントローラー
  final _calibrationStatusController = StreamController<CalibrationStatus>.broadcast();
  
  /// キャリブレーションの状態を通知するストリーム
  Stream<CalibrationStatus> get calibrationStatus => _calibrationStatusController.stream;
  
  /// キャリブレーションプロセスを開始する
  /// 
  /// [gyroStream] ジャイロデータのストリーム
  /// [durationInSeconds] キャリブレーションの秒数（デフォルト: 5秒）
  /// 
  /// 戻り値: キャリブレーションが完了したときに発火するFuture<bool>
  Future<bool> startCalibration(Stream<RotationRate> gyroStream, {int durationInSeconds = 5}) async {
    // 既にキャリブレーション中なら何もしない
    if (_isCalibrating) {
      return false;
    }
    
    _isCalibrating = true;
    _collectedGyroData.clear();
    
    // キャリブレーション開始を通知
    _calibrationStatusController.add(CalibrationStatus.started);
    
    // ジャイロデータの購読
    final subscription = gyroStream.listen((gyroData) {
      if (_isCalibrating) {
        _collectedGyroData.add(gyroData);
      }
    });
    
    // 指定された秒数後にキャリブレーションを終了
    try {
      await Future.delayed(Duration(seconds: durationInSeconds));
      
      // ストリームの購読を解除
      await subscription.cancel();
      
      // キャリブレーションを終了
      return await _finishCalibration();
    } catch (e) {
      // エラーが発生した場合
      _isCalibrating = false;
      await subscription.cancel();
      _calibrationStatusController.add(CalibrationStatus.error);
      return false;
    }
  }
  
  /// キャリブレーションを終了し、平均値を計算して保存する
  Future<bool> _finishCalibration() async {
    _isCalibrating = false;
    
    // 収集したデータがない場合
    if (_collectedGyroData.isEmpty) {
      _calibrationStatusController.add(CalibrationStatus.error);
      return false;
    }
    
    try {
      // 平均値を計算
      double sumX = 0, sumY = 0, sumZ = 0;
      for (var gyroData in _collectedGyroData) {
        sumX += gyroData.x;
        sumY += gyroData.y;
        sumZ += gyroData.z;
      }
      
      final avgX = sumX / _collectedGyroData.length;
      final avgY = sumY / _collectedGyroData.length;
      final avgZ = sumZ / _collectedGyroData.length;
      
      // 平均値を基準値として保存
      final referencePosture = RotationRate(avgX, avgY, avgZ);
      final success = await _postureService.saveNewCalibration(referencePosture);
      
      if (success) {
        _calibrationStatusController.add(CalibrationStatus.completed);
      } else {
        _calibrationStatusController.add(CalibrationStatus.error);
      }
      
      return success;
    } catch (e) {
      _calibrationStatusController.add(CalibrationStatus.error);
      return false;
    }
  }
  
  /// リソースを解放する
  void dispose() {
    _calibrationStatusController.close();
  }
}

/// キャリブレーションの状態を表す列挙型
enum CalibrationStatus {
  /// キャリブレーション開始
  started,
  
  /// キャリブレーション完了
  completed,
  
  /// エラー発生
  error
}