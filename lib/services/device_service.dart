import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static final DeviceService instance = DeviceService._init();
  DeviceService._init();

  static const _deviceIdKey = 'device_id';
  String? _cachedDeviceId;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      print('🆕 Generated new device ID: $deviceId');
    } else {
      print('✅ Loaded existing device ID: $deviceId');
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }
}