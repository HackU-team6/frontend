// lib/utils/calibration_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class CalibrationStorage {
  static const _keyPitch = 'baseline_pitch_rad';

  Future<void> savePitch(double pitch) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setDouble(_keyPitch, pitch);
  }

  Future<double?> loadPitch() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getDouble(_keyPitch);
  }

  Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_keyPitch);
  }
}
