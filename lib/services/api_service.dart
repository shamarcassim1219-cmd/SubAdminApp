import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';

class ApiService {
  static const String baseUrl = 'https://api.finbassshamar.online';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('subadmin_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subadmin_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('subadmin_token');
  }

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (withAuth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> _handle(http.Response res) async {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      final errorMsg = body is Map ? (body['error'] ?? 'Request failed (${res.statusCode})') : 'Request failed (${res.statusCode})';
      throw Exception(errorMsg);
    }
  }

  // ---------- REGISTRATION ----------
  static Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String address,
    required String nicNumber,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/subadmin/register'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'email': email, 'password': password, 'fullName': fullName,
        'address': address, 'nicNumber': nicNumber,
        'gpsLat': gpsLat, 'gpsLng': gpsLng,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
    );
    await _handle(res);
  }

  // ---------- AUTH ----------
  static Future<void> login(String email, String password) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/subadmin/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'email': email, 'password': password,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> verifyLogin(String email, String code) async {
    final deviceFingerprint = await DeviceService.getFingerprint();
    final deviceModel = await DeviceService.getModel();
    final res = await http.post(
      Uri.parse('$baseUrl/subadmin/verify-login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({
        'email': email, 'code': code,
        'deviceFingerprint': deviceFingerprint, 'deviceModel': deviceModel,
      }),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  static Future<void> saveFcmToken(String fcmToken) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/notifications/fcm-token'),
        headers: await _headers(),
        body: jsonEncode({'token': fcmToken}),
      );
      await _handle(res);
    } catch (_) {}
  }

  // ---------- VERIFICATIONS ----------
  static Future<List<dynamic>> getVerifications() async {
    final res = await http.get(Uri.parse('$baseUrl/subadmin/verifications'), headers: await _headers());
    final data = await _handle(res);
    return data['verifications'];
  }

  static Future<void> decideVerification(int userId, bool approve) async {
    final res = await http.post(
      Uri.parse('$baseUrl/subadmin/verifications/$userId/decide'),
      headers: await _headers(),
      body: jsonEncode({'approve': approve}),
    );
    await _handle(res);
  }

  static Future<void> reportVerification(int userId, String reason) async {
    final res = await http.post(
      Uri.parse('$baseUrl/subadmin/verifications/$userId/report'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );
    await _handle(res);
  }

  // ---------- CONTENT REPORTS ----------
  static Future<List<dynamic>> getContentReports() async {
    final res = await http.get(Uri.parse('$baseUrl/subadmin/content-reports'), headers: await _headers());
    final data = await _handle(res);
    return data['reports'];
  }

  static Future<void> resolveContentReport(int id) async {
    final res = await http.post(Uri.parse('$baseUrl/subadmin/content-reports/$id/resolve'), headers: await _headers());
    await _handle(res);
  }

  // ---------- SETTINGS ----------
  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(Uri.parse('$baseUrl/subadmin/me'), headers: await _headers());
    return await _handle(res);
  }

  static Future<List<dynamic>> getActivityLog() async {
    final res = await http.get(Uri.parse('$baseUrl/subadmin/activity-log'), headers: await _headers());
    final data = await _handle(res);
    return data['logins'];
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/subadmin/password/change'),
      headers: await _headers(),
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    await _handle(res);
  }

  static Future<void> requestEmailChange(String newEmail) async {
    final res = await http.post(
      Uri.parse('$baseUrl/subadmin/email/request-change'),
      headers: await _headers(),
      body: jsonEncode({'newEmail': newEmail}),
    );
    await _handle(res);
  }

  // ---------- SUPPORT CHAT ----------
  static Future<List<dynamic>> getSupportRequests() async {
    final res = await http.get(Uri.parse('$baseUrl/subadmin/support-requests'), headers: await _headers());
    final data = await _handle(res);
    return data['requests'];
  }

  static Future<Map<String, dynamic>> getSupportMessages(int requestId) async {
    final res = await http.get(Uri.parse('$baseUrl/subadmin/support-requests/$requestId/messages'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> sendSupportReply(int requestId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/subadmin/support-requests/$requestId/reply'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
    await _handle(res);
  }

  static Future<void> escalateSupportRequest(int requestId) async {
    final res = await http.post(Uri.parse('$baseUrl/subadmin/support-requests/$requestId/escalate'), headers: await _headers());
    await _handle(res);
  }

  static Future<void> closeSupportRequest(int requestId) async {
    final res = await http.post(Uri.parse('$baseUrl/subadmin/support-requests/$requestId/close'), headers: await _headers());
    await _handle(res);
  }

  // ---------- APP UPDATE CHECK ----------
  static Future<Map<String, dynamic>> checkForUpdate(String currentVersion) async {
    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/shamarcassim1219-cmd/SubAdminApp/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (res.statusCode == 404) {
        return {'updateAvailable': false, 'noReleases': true};
      }
      if (res.statusCode != 200) {
        throw Exception('Could not check for updates right now');
      }

      final data = jsonDecode(res.body);
      final latestTag = (data['tag_name'] ?? '').toString().replaceFirst('v', '');
      final downloadUrl = (data['assets'] as List?)?.cast<Map<String, dynamic>>().firstWhere(
            (a) => (a['name'] ?? '').toString().endsWith('.apk'),
            orElse: () => {},
          )['browser_download_url'];

      final isNewer = _isVersionNewer(latestTag, currentVersion);

      return {
        'updateAvailable': isNewer,
        'latestVersion': latestTag,
        'downloadUrl': downloadUrl,
        'releaseNotes': data['body'],
      };
    } catch (e) {
      throw Exception('Could not check for updates: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  static bool _isVersionNewer(String latest, String current) {
    if (latest.isEmpty) return false;
    final l = latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final c = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }
}
