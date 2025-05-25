// lib/services/posture_analyzer.dart
//
// AirPods ピッチ値を用いた姿勢解析クラス。
// ──────────────────────────────────────────
import 'dart:async';
import 'dart:math' as math;
import '../utils/calibration_storage.dart';
import 'airpods_motion_service.dart';
import 'package:flutter_airpods/models/attitude.dart';

/// 姿勢状態
enum PostureState { good, poor }

class PostureAnalyzer {
  PostureAnalyzer({
    this.thresholdDeg = 15, // しきい値（deg）
    this.avgWindow = const Duration(milliseconds: 500),
    this.confirmDuration = const Duration(seconds: 1),
  });

  final double thresholdDeg;
  final Duration avgWindow;
  final Duration confirmDuration;

  // 内部ストリーム
  final _stateCtl = StreamController<PostureState>.broadcast();
  Stream<PostureState> get state$ => _stateCtl.stream;

  final _storage = CalibrationStorage();
  double? _baselinePitch; // キャリブレーション値
  StreamSubscription<Attitude>? _sub;
  final _buffer = <double>[]; // 移動平均バッファ
  DateTime? _poorSince;

  /// キャリブレーションを実行（現在値を基準に）
  Future<void> calibrate() async {
    _baselinePitch = null; // 初期化
    final current = await AirPodsMotionService.attitude$().first;
    _baselinePitch = current.pitch as double?; // rad
    await _storage.savePitch(_baselinePitch!);
  }

  /// 保存済みキャリブレーションを読み込み。なければ false。
  Future<bool> loadCalibration() async {
    _baselinePitch = await _storage.loadPitch();
    return _baselinePitch != null;
  }

  /// 解析開始
  Future<void> start() async {
    if (_baselinePitch == null) {
      final ok = await loadCalibration();
      if (!ok) throw StateError('キャリブレーション未実施');
    }
    _sub ??= AirPodsMotionService.attitude$().listen(_onData);
  }

  /// 解析停止
  Future<void> dispose() async {
    await _sub?.cancel();
    await _stateCtl.close();
  }

  // ──────────────────────────────────────────
  // センサ値ハンドラ
  void _onData(Attitude att) {
    // 移動平均用バッファ更新
    final now = DateTime.now();
    _buffer.add(att.pitch.toDouble());
    _buffer.removeWhere((_) => _buffer.length > 25); // 約0.4–0.5 s分だけ保持

    if (_buffer.isEmpty) {
      return; // バッファが空の場合は何もしない
    }
    final avgPitch = _buffer.reduce((a, b) => a + b) / _buffer.length;

    final diff = (_baselinePitch! - avgPitch); // 正姿勢より負方向に倒れれば diff > 0
    final overThreshold = diff > math.pi * thresholdDeg / 180; // rad へ変換

    // 状態遷移判定
    if (overThreshold) {
      _poorSince ??= now;
      if (now.difference(_poorSince!) >= confirmDuration) {
        _emit(PostureState.poor);
      }
    } else {
      _poorSince = null;
      _emit(PostureState.good);
    }
  }

  void _emit(PostureState s) {
    if (!_stateCtl.isClosed && (_stateCtl.hasListener)) {
      _stateCtl.add(s);
    }
  }
}
