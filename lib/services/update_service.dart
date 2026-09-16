import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// A published version newer than the one currently running.
class UpdateInfo {
  final String version;
  final String releaseUrl;

  /// Direct link to the built zip attached to the release, or null if the
  /// release has no asset yet (e.g. it's still being uploaded, or was
  /// created by hand without one) — callers should fall back to
  /// [releaseUrl] in that case.
  final String? downloadUrl;
  final String? assetName;
  final int? assetSize;

  const UpdateInfo({
    required this.version,
    required this.releaseUrl,
    this.downloadUrl,
    this.assetName,
    this.assetSize,
  });
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

      final assets = json['assets'] as List?;
      final asset = (assets != null && assets.isNotEmpty)
          ? assets.first as Map<String, dynamic>
          : null;

      return UpdateInfo(
        version: latestVersion,
        releaseUrl: releaseUrl,
        downloadUrl: asset?['browser_download_url'] as String?,
        assetName: asset?['name'] as String?,
        assetSize: asset?['size'] as int?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Downloads [update]'s asset to the user's Downloads folder (falling
  /// back to the app's own data folder if that isn't available), streaming
  /// so [onProgress] can report `(bytesReceived, totalBytes)` — `totalBytes`
  /// is 0 if the server doesn't report a length. Throws on any failure
  /// (network error, non-200 response, no [UpdateInfo.downloadUrl]); the
  /// caller decides how to surface that.
  static Future<File> downloadUpdate(
    UpdateInfo update, {
    void Function(int received, int total)? onProgress,
  }) async {
    final url = update.downloadUrl;
    if (url == null) {
      throw StateError('This release has no downloadable asset');
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamed = await client.send(request);
      if (streamed.statusCode != 200) {
        throw HttpException(
          'Download failed with status ${streamed.statusCode}',
        );
      }
      final total = streamed.contentLength ?? update.assetSize ?? 0;

      final dir =
          await getDownloadsDirectory() ??
          await getApplicationSupportDirectory();
      final fileName = update.assetName ?? 'tk_random-windows.zip';
      final file = File('${dir.path}/$fileName');

      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.close();

      return file;
    } finally {
      client.close();
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
