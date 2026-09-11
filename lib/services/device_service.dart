import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

class DeviceService {
  static String? _cachedFingerprint;
  static String? _cachedModel;

  static Future<void> _load() async {
    if (_cachedFingerprint != null) return;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _cachedFingerprint = androidInfo.id;
      _cachedModel = '${androidInfo.manufacturer} ${androidInfo.model}'.trim();
    } catch (e) {
      _cachedFingerprint = 'unknown-device';
      _cachedModel = 'Unknown Device';
    }
  }

  static Future<String> getFingerprint() async {
    await _load();
    return _cachedFingerprint ?? 'unknown-device';
  }

  static Future<String> getModel() async {
    await _load();
    return _cachedModel ?? 'Unknown Device';
  }

  static Future<Position?> getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      return null;
    }
  }
}
