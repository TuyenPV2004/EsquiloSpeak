import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/core/config/preference_keys.dart';
import 'package:mobile/src/core/device/device_id_service.dart';

void main() {
  group('DeviceIdService Tests', () {
    late DeviceIdService service;

    setUp(() {
      service = DeviceIdService();
    });

    test('should generate new device ID if SharedPreferences is empty', () async {
      SharedPreferences.setMockInitialValues({});

      final deviceId = await service.getOrCreateDeviceId();

      expect(deviceId, isNotNull);
      expect(deviceId, matches(RegExp(r'^dev_\d{13}_[0-9a-f]{16}$')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PreferenceKeys.deviceId), deviceId);
    });

    test('should reuse existing valid device ID from SharedPreferences', () async {
      const existingId = 'dev_1719416560000_abcdef0123456789';
      SharedPreferences.setMockInitialValues({
        PreferenceKeys.deviceId: existingId,
      });

      final deviceId = await service.getOrCreateDeviceId();

      expect(deviceId, existingId);
    });

    test('should regenerate device ID if saved ID is device_mock_id', () async {
      SharedPreferences.setMockInitialValues({
        PreferenceKeys.deviceId: 'device_mock_id',
      });

      final deviceId = await service.getOrCreateDeviceId();

      expect(deviceId, isNot('device_mock_id'));
      expect(deviceId, matches(RegExp(r'^dev_\d{13}_[0-9a-f]{16}$')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PreferenceKeys.deviceId), deviceId);
    });

    test('should regenerate device ID if saved ID is empty or blank', () async {
      SharedPreferences.setMockInitialValues({
        PreferenceKeys.deviceId: '   ',
      });

      final deviceId = await service.getOrCreateDeviceId();

      expect(deviceId.trim(), isNotEmpty);
      expect(deviceId, matches(RegExp(r'^dev_\d{13}_[0-9a-f]{16}$')));
    });

    test('should regenerate device ID if saved ID does not start with dev_', () async {
      SharedPreferences.setMockInitialValues({
        PreferenceKeys.deviceId: 'some_other_id',
      });

      final deviceId = await service.getOrCreateDeviceId();

      expect(deviceId, matches(RegExp(r'^dev_\d{13}_[0-9a-f]{16}$')));
    });

    test('should prevent race conditions and return same ID on concurrent calls', () async {
      SharedPreferences.setMockInitialValues({});

      final futures = await Future.wait([
        service.getOrCreateDeviceId(),
        service.getOrCreateDeviceId(),
        service.getOrCreateDeviceId(),
      ]);

      expect(futures[0], futures[1]);
      expect(futures[1], futures[2]);
      expect(futures[0], matches(RegExp(r'^dev_\d{13}_[0-9a-f]{16}$')));
    });
  });
}
