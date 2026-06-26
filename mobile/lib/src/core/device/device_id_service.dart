import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/preference_keys.dart';

class DeviceIdService {
  SharedPreferences? _prefs;
  Future<String>? _inFlightDeviceId;
  String? _cachedDeviceId;
  final _random = Random.secure();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String> getOrCreateDeviceId() {
    if (_cachedDeviceId != null) {
      return Future.value(_cachedDeviceId!);
    }

    return _inFlightDeviceId ??= _loadOrCreateDeviceId().whenComplete(() {
      _inFlightDeviceId = null;
    });
  }

  Future<String> _loadOrCreateDeviceId() async {
    final prefs = await _getPrefs();
    final storedId = prefs.getString(PreferenceKeys.deviceId);
    final String deviceId;

    if (_isInvalidDeviceId(storedId)) {
      deviceId = _generateDeviceId();
      await prefs.setString(PreferenceKeys.deviceId, deviceId);
    } else {
      deviceId = storedId!;
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  bool _isInvalidDeviceId(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    if (value == 'device_mock_id') return true;
    if (!value.startsWith('dev_')) return true;
    return false;
  }

  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = List.generate(
      16,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    return 'dev_${timestamp}_$randomPart';
  }
}

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService();
});
