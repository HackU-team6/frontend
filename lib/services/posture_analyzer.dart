import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/calibration_storage.dart';
import 'airpods_motion_service.dart';
import 'package:flutter_airpods/models/attitude.dart';

enum PostureState { good, poor }

class PostureAnalyzer {
  final CalibrationStorage _storage = CalibrationStorage();

  // Configurable parameters
  final int thresholdDeg;
  final double yawMaxThreshold;
  final double yawMinThreshold;
  final double rollMaxThreshold;
  final double rollMinThreshold;
  final Duration avgWindow;
  final Duration Function() getConfirmDuration;
  final Duration Function() getNotificationInterval;

  // Internal state
  double? _baselinePitch;
  final List<double> _pitchBuffer = [];
  late final int _maxBufferSize;

  // Streams
  final _stateController = BehaviorSubject<PostureState>.seeded(PostureState.good);
  final _errorController = StreamController<AppException>.broadcast();
  StreamSubscription<Attitude>? _attitudeSubscription;

  // Notification state
  DateTime? _poorPostureStartTime;
  DateTime? _lastNotificationTime;

  // Throttling
  final _throttleDuration = Duration(milliseconds: 1000 ~/ AppConstants.sensorSamplingRate);
  DateTime _lastProcessTime = DateTime.now();

  Stream<PostureState> get state$ => _stateController.stream;
  Stream<AppException> get error$ => _errorController.stream;
  PostureState get currentState => _stateController.value;
  double? get baselinePitch => _baselinePitch; 
  bool get isMonitoring => _attitudeSubscription != null;

  PostureAnalyzer({
    this.thresholdDeg = AppConstants.postureThresholdDegrees,
    this.avgWindow = AppConstants.averageWindow,
    this.yawMaxThreshold = AppConstants.yawMaxThreshold,
    this.yawMinThreshold = AppConstants.yawMinThreshold,
    this.rollMaxThreshold = AppConstants.rollMaxThreshold,
    this.rollMinThreshold = AppConstants.rollMinThreshold,
    required this.getConfirmDuration,
    required this.getNotificationInterval,
  }) {
    _maxBufferSize = (avgWindow.inMilliseconds * AppConstants.airPodsUpdateFrequency / 1000).ceil();
  }

  /// AirPodsの接続状態を確認
  Future<bool> checkAirPodsConnection() async {
    try {
      // タイムアウトを設定して接続チェック
      final attitude = await AirPodsMotionService.attitude$()
          .timeout(const Duration(seconds: 2))
          .first;
      return attitude != null;
    } catch (e) {
      return false;
    }
  }

  /// キャリブレーションを実行
  Future<void> calibrate() async {
    try {
      if (!await checkAirPodsConnection()) {
        throw AirPodsNotConnectedException();
      }

      if (kDebugMode) {
        print('PostureAnalyzer: Starting calibration...');
      }

      // ユーザーに準備時間を与える
      await Future.delayed(const Duration(seconds: 2));

      // 複数サンプルの平均を取る
      final samples = <double>[];
      await for (final attitude in AirPodsMotionService.attitude$().take(30)) {
        samples.add(attitude.pitch.toDouble());
      }

      if (samples.isEmpty) {
        throw CalibrationFailedException('センサーデータを取得できませんでした');
      }

      // 中央値を計算
      _baselinePitch = _calculateMedian(samples);

      // 保存
      await _storage.savePitch(_baselinePitch!);

      if (kDebugMode) {
        print('PostureAnalyzer: Calibration completed. Baseline: $_baselinePitch rad');
      }
    } catch (e) {
      _errorController.add(
          e is AppException ? e : CalibrationFailedException(e.toString())
      );
      rethrow;
    }
  }

  /// 保存済みキャリブレーションを読み込み
  Future<bool> loadCalibration() async {
    try {
      _baselinePitch = await _storage.loadPitch();
      return _baselinePitch != null;
    } catch (e) {
      _errorController.add(
          SensorDataException('キャリブレーションデータの読み込みに失敗しました: $e')
      );
      return false;
    }
  }

  /// モニタリングを開始
  Future<void> start() async {
    try {
      if (isMonitoring) return;

      if (!await checkAirPodsConnection()) {
        throw AirPodsNotConnectedException();
      }

      if (_baselinePitch == null && !await loadCalibration()) {
        throw CalibrationRequiredException();
      }

      _startMonitoring();
    } catch (e) {
      _errorController.add(
          e is AppException ? e : SensorDataException(e.toString())
      );
      rethrow;
    }
  }

  void _startMonitoring() {
    _attitudeSubscription?.cancel();
    _pitchBuffer.clear();
    _poorPostureStartTime = null;
    _lastNotificationTime = null;

    _attitudeSubscription = AirPodsMotionService.attitude$()
        .handleError((error) {
      _errorController.add(SensorDataException('センサーエラー: $error'));
    })
        .listen(_processAttitudeData);
  }

  void _processAttitudeData(Attitude attitude) {
    final now = DateTime.now();

    // スロットリング：指定されたサンプリングレートで処理
    if (now.difference(_lastProcessTime) < _throttleDuration) {
      return;
    }
    _lastProcessTime = now;

    // バッファを更新
    if (attitude.yaw.toDouble() < yawMinThreshold || attitude.yaw.toDouble() > yawMaxThreshold || attitude.roll.toDouble() < rollMinThreshold || attitude.roll.toDouble() > rollMaxThreshold) {
      _pitchBuffer.add(0);
    }
    else {
      _pitchBuffer.add(attitude.pitch.toDouble());
    }
    if (_pitchBuffer.length > _maxBufferSize) {
      _pitchBuffer.removeRange(0, _pitchBuffer.length - _maxBufferSize);
    }

    if (_pitchBuffer.isEmpty) return;

    // 移動平均を計算
    //final avgPitch = _pitchBuffer.reduce((a, b) => a + b) / _pitchBuffer.length;

    // Hampelフィルター処理
    final window = List<double>.from(_pitchBuffer);
    final median = _calculateMedian(window);
    final deviations = window.map((v) => (v - median).abs()).toList();
    // MedAD (Median Absolute Deviation)
    final medad = _calculateMedian(deviations);
    // 1.8はwindow内の中央値から何倍離れているか（直感）、1.4826は標準偏差とのスケール調整
    final threshold = 1.8 * 1.4826 * medad;
    final filtered = window.map((v) => 
      (v - median).abs() > threshold ? median : v).toList();
    final medianPitch = _calculateMedian(filtered);

    // 姿勢判定
    double pitchDiff = 0;
    if (_baselinePitch != null) {
      pitchDiff = _baselinePitch! - medianPitch;
    }
    final thresholdRad = thresholdDeg * (math.pi / 180);
    final isPoorPosture = pitchDiff > thresholdRad;

    // 状態更新とイベント発火
    _updatePostureState(isPoorPosture, now);
  }

  /// Helper: calculate median of a list
  double _calculateMedian(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final n = sorted.length;
    if (n % 2 == 1) {
      return sorted[n ~/ 2];
    } else {
      return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
    }
  }

  void _updatePostureState(bool isPoorPosture, DateTime now) {
    if (isPoorPosture) {
      // 姿勢悪化の開始時刻を記録
      _poorPostureStartTime ??= now;

      // 確定時間経過後に状態を更新
      if (now.difference(_poorPostureStartTime!) >= getConfirmDuration()) {
        if (currentState != PostureState.poor) {
          _stateController.add(PostureState.poor);
          _onPoorPostureDetected(now);
        } else {
          // 既に姿勢が悪い状態で、通知間隔が経過していれば再通知
          _checkForRenotification(now);
        }
      }
    } else {
      // 姿勢が改善された
      _poorPostureStartTime = null;
      if (currentState != PostureState.good) {
        _stateController.add(PostureState.good);
      }
    }
  }

  void _onPoorPostureDetected(DateTime now) {
    _lastNotificationTime = now;
    // 通知イベントを発火（NotificationServiceで処理）
  }

  void _checkForRenotification(DateTime now) {
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) >= getNotificationInterval()) {
      _onPoorPostureDetected(now);
    }
  }

  /// モニタリングを停止
  void stop() {
    _attitudeSubscription?.cancel();
    _attitudeSubscription = null;
    _pitchBuffer.clear();
    _poorPostureStartTime = null;
    _lastNotificationTime = null;
    _stateController.add(PostureState.good);
  }

  /// リソースを解放
  void dispose() {
    stop();
    _stateController.close();
    _errorController.close();
  }

  /// キャリブレーションをクリア
  Future<void> clearCalibration() async {
    _baselinePitch = null;
    await _storage.clear();
  }
}
