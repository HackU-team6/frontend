import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nekoze_notify/services/airpods_motion_service.dart';

/// AirPods の接続状態（true = 接続中）を流し続けるストリーム
final airPodsConnectionProvider = StreamProvider<bool>((ref) {
  AirPodsMotionService.initialize();

  return AirPodsMotionService.motion$()
      .map((event) => event != null)
      .distinct();
});
