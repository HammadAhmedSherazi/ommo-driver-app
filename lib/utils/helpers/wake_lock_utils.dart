import 'package:wakelock_plus/wakelock_plus.dart';

class WakeLockUtils {
  WakeLockUtils._();

  static void enable() async {
    if (await WakelockPlus.enabled) return;
    WakelockPlus.enable();
  }

  static void disable() async {
    if (!(await WakelockPlus.enabled)) return;
    WakelockPlus.disable();
  }
}
