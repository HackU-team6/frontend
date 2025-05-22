// イヤホンが返す roll・pitch・yaw（°）を使って
// 「キャリブレーション姿勢」から どれだけ首が前傾したかを計算
// 0-15 (軽度) / 15-30 (中度) / 30-45 (重度) / 45- (危険) に分類する。
//
// 回転順序は Z-Y-X（yaw → pitch → roll）を想定。
// 3 軸の回転行列を組み立てて，耳の “正面ベクトル” (1,0,0) を回転。
// こうすることでroll, yawがpitchに与える影響を除去できる。
// 正面ベクトルの鉛直成分から前傾角 θ を求め，
// キャリブレーション時の θ₀ との差 Δθ を前傾角として扱うことを想定。

import 'dart:math' as math;

/// 前傾の重症度ラベル
enum TiltLevel { mild, moderate, severe, danger }

class NeckTiltResult {
  final double tiltDeg;    // キャリブ後の前傾角 Δθ
  final TiltLevel level;   // 重症度

  const NeckTiltResult(this.tiltDeg, this.level)
}

class NeckTiltCalculator {
  // --- キャリブレーション時の姿勢 (°) ---
  // ここに初期値を入れて欲しいです to ブンさん
  final double _roll0;
  final double _pitch0;
  final double _yaw0;

  NeckTiltCalculator({
    required double roll0,
    required double pitch0,
    required double yaw0,
  })  : _roll0 = roll0,
        _pitch0 = pitch0,
        _yaw0 = yaw0 {
    // キャリブレーション姿勢での前傾角 θ₀ を先に計算しておく
    _theta0 = _forwardTilt(_roll0, _pitch0, _yaw0);
  }

  late final double _theta0;

  /// ° → rad 変換
  double _deg2rad(double deg) => deg * math.pi / 180.0;

  /// 3×3回転行列 R = Rz·Ry·Rx を作る
  List<List<double>> _rotationMatrix(
      double rollDeg, double pitchDeg, double yawDeg) {
    final r = _deg2rad(rollDeg);
    final p = _deg2rad(pitchDeg);
    final y = _deg2rad(yawDeg);

    final cr = math.cos(r), sr = math.sin(r);
    final cp = math.cos(p), sp = math.sin(p);
    final cy = math.cos(y), sy = math.sin(y);

    // 行列を手計算で展開（Z-Y-X の積）
    return [
      [
        cy * cp,
        cy * sp * sr - sy * cr,
        cy * sp * cr + sy * sr,
      ],
      [
        sy * cp,
        sy * sp * sr + cy * cr,
        sy * sp * cr - cy * sr,
      ],
      [
        -sp,
        cp * sr,
        cp * cr,
      ],
    ];
  }

  /// 行列 × ベクトル (3×3 · 3) を計算
  List<double> _mulMatVec(List<List<double>> m, List<double> v) {
    return [
      m[0][0] * v[0] + m[0][1] * v[1] + m[0][2] * v[2],
      m[1][0] * v[0] + m[1][1] * v[1] + m[1][2] * v[2],
      m[2][0] * v[0] + m[2][1] * v[1] + m[2][2] * v[2],
    ];
  }

  /// roll-pitch-yaw → 前傾角 θ（°）
  double _forwardTilt(double rollDeg, double pitchDeg, double yawDeg) {
    // (1) 回転行列を作成
    final R = _rotationMatrix(rollDeg, pitchDeg, yawDeg);

    // (2) イヤホン「鼻方向」= (1,0,0) を回転
    final f = _mulMatVec(R, [1.0, 0.0, 0.0]); // f = (f_x, f_y, f_z)

    // (3) 水平分 H と下向き成分 D を計算
    final H = math.sqrt(f[0] * f[0] + f[1] * f[1]); // √(f_x² + f_y²)
    final D = -f[2];                                // −f_z   ※前に倒れると＋に変換している（直感的にするため）

    // (4) atan2 で θ を求め, rad → °
    return math.atan2(D, H) * 180.0 / math.pi;
  }

  /// 現在姿勢を与えて Δθ と重症度を返す
  NeckTiltResult evaluate({
    required double roll,
    required double pitch,
    required double yaw,
  }) {
    // 現在の θ
    final theta = _forwardTilt(roll, pitch, yaw);

    // キャリブとの差 Δθ
    double delta = theta - _theta0;
    if (delta < 0) delta = 0; // 後ろへ反った分は 0° とみなす

    // --- 重症度分類 ---
    late TiltLevel level;
    if (delta < 15) {
      level = TiltLevel.mild;
    } else if (delta < 30) {
      level = TiltLevel.moderate;
    } else if (delta < 45) {
      level = TiltLevel.severe;
    } else {
      level = TiltLevel.danger;
    }

    return NeckTiltResult(delta, level);
  }
}

void main() {
  final calc = NeckTiltCalculator(
    // キャリブレーションされた値
    roll0: 0.0,
    pitch0: 0.0,
    yaw0: 0.0,
  );

  final result = calc.evaluate(
    // 姿勢情報（姿勢を評価するためにセンサーから取った値）
    roll: 0.0,
    pitch: 0.0,
    yaw: 0.0,
  );
}

