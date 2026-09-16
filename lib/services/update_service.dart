import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// A published version newer than the one currently running.
class UpdateInfo {
  final String version;
  final String releaseUrl;

  const UpdateInfo({required this.version, required this.releaseUrl});
}

class UpdateService {
  UpdateService._();

  static const _latestReleaseUrl =
      'https://api.github.com/repos/Bnutss/TK-Random/releases/latest';

  /// Checks the GitHub repo's latest release against the running app's
  /// version. Returns null if already up to date, and also if the check
  /// itself fails for any reason (offline, no releases published yet, API
  /// rate limit, unexpected response shape) — this is a best-effort
  /// background check on startup, never worth failing loudly over.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(_latestReleaseUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String?;
      final releaseUrl = json['html_url'] as String?;
      if (tag == null || releaseUrl == null) return null;

      final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;
      final currentVersion = (await PackageInfo.fromPlatform()).version;

      if (!isNewerVersion(latestVersion, currentVersion)) return null;
      return UpdateInfo(version: latestVersion, releaseUrl: releaseUrl);
    } catch (_) {
      return null;
    }
  }
}

/// Compares dotted numeric versions ("1.2.10" vs "1.2.9"); missing or
/// non-numeric segments count as 0, so "1.2" and "1.2.0" are equal.
bool isNewerVersion(String latest, String current) {
  final a = latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final b = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final length = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    final va = i < a.length ? a[i] : 0;
    final vb = i < b.length ? b[i] : 0;
    if (va != vb) return va > vb;
  }
  return false;
}
