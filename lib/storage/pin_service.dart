import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/storage/secure_key.dart';

enum AutoLockDuration {
  instant,
  oneMinute,
  fiveMinutes,
  oneHour,
  fiveHours,
}
extension AutoLockDurationX on AutoLockDuration {
  Duration get duration {
    switch (this) {
      case AutoLockDuration.instant:
        return Duration.zero;
      case AutoLockDuration.oneMinute:
        return const Duration(minutes: 1);
      case AutoLockDuration.fiveMinutes:
        return const Duration(minutes: 5);
      case AutoLockDuration.oneHour:
        return const Duration(hours: 1);
      case AutoLockDuration.fiveHours:
        return const Duration(hours: 5);
    }
  }
}

class PinService {
  static const _storage = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();


  static Future<void> savePin(String pin) async {
    await _storage.write(key: SecureKeys.pin, value: pin);
    await _storage.write(key: SecureKeys.pinEnabled, value: 'true');
  }

  static Future<void> removePin() async {
    await _storage.delete(key: SecureKeys.pin);
    await _storage.write(key: SecureKeys.pinEnabled, value: 'false');
    await _storage.write(key: SecureKeys.biometricsEnabled, value: 'false');
  }

  static Future<bool> checkPin(String pin) async {
    final saved = await _storage.read(key: SecureKeys.pin);
    return saved == pin;
  }

  static Future<bool> isPinEnabled() async {
    final val = await _storage.read(key: SecureKeys.pinEnabled);
    return val == 'true';
  }

  static Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }
  static Future<bool> isBiometricsEnabled() async {
    final val = await _storage.read(key: SecureKeys.biometricsEnabled);
    return val == 'true';
  }
  static Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(
      key: SecureKeys.biometricsEnabled,
      value: enabled ? 'true' : 'false',
    );
  }
  static Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      return await _localAuth.authenticate(
        localizedReason: S.current.pdtlic,
        authMessages: [
          AndroidAuthMessages(
            cancelButton: S.current.ot,
          ),
        ],
      );
    } catch (_) {
      return false;
    }
  }

  static Future<AutoLockDuration> getAutoLockDuration() async {
    final val = await _storage.read(key: SecureKeys.autoLockDuration);
    if (val == null) return AutoLockDuration.oneMinute;
    return AutoLockDuration.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AutoLockDuration.oneMinute,
    );
  }

  static Future<void> setAutoLockDuration(AutoLockDuration value) async {
    await _storage.write(key: SecureKeys.autoLockDuration, value: value.name);
  }
}

// this code was written by maksy