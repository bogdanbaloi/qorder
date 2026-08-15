import 'package:flutter/services.dart';

import '../../domain/alerts/alert_signal.dart';

/// Fires the device's built-in alert: a haptic buzz plus the system alert sound
/// where the platform allows it. No third-party dependency. A richer web-audio
/// signal (which needs a user-gesture unlock in the browser) can slot in behind
/// [AlertSignal] later without touching the waiter surface.
class DeviceAlertSignal implements AlertSignal {
  const DeviceAlertSignal();

  @override
  Future<void> fire() async {
    await HapticFeedback.vibrate();
    await SystemSound.play(SystemSoundType.alert);
  }
}
