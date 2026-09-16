import 'dart:ffi';
import 'dart:io';

import 'package:win32/win32.dart';

/// Best-effort "send to Telegram" helper for Windows.
///
/// Telegram Desktop has no API that lets a third-party app hand it a local
/// file plus a chosen contact directly — `tg://` links can only open the
/// app or a specific chat by username, not attach a file. The next best
/// thing: put the file on the clipboard in the same `CF_HDROP` format
/// Explorer uses for copy/paste, so the user can open any chat in Telegram
/// and just press Ctrl+V to send it, instead of hunting for the file
/// themselves.
class TelegramShareService {
  TelegramShareService._();

  /// Whether something is registered to handle `tg://` links — Telegram's
  /// own installer does this, but a portable/no-installer copy might not.
  /// A `false` result isn't proof Telegram truly isn't installed, so
  /// callers should offer a way to proceed anyway rather than treat this
  /// as final.
  static Future<bool> isInstalled() async {
    try {
      final result = await Process.run('reg', ['query', r'HKCR\tg']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Copies [file] onto the clipboard as an actual file (`CF_HDROP`),
  /// ready to be pasted into Telegram or any other app. Returns false on
  /// any failure — every step of this talks to the raw Win32 clipboard
  /// API, so callers must treat a `false` result as "just open the folder
  /// instead" rather than a fatal error.
  static bool copyFileToClipboard(File file) {
    try {
      final path = file.absolute.path;
      final units = path.codeUnits;
      // DROPFILES header (20 bytes: DWORD pFiles + POINT pt + BOOL fNC +
      // BOOL fWide), then the UTF-16 path, its own null terminator, and one
      // more null terminator to end the (single-entry) file list.
      const headerSize = 20;
      final totalBytes = headerSize + (units.length + 2) * 2;

      final hMem = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, totalBytes).value;
      if (hMem == nullptr) return false;

      final ptr = GlobalLock(hMem).value;
      if (ptr == nullptr) {
        GlobalFree(hMem);
        return false;
      }

      final dropFiles = ptr.cast<DROPFILES>();
      dropFiles.ref
        ..pFiles = headerSize
        ..fNC = false
        ..fWide = true;
      dropFiles.ref.pt
        ..x = 0
        ..y = 0;

      final pathPtr = (ptr.cast<Uint8>() + headerSize).cast<Uint16>();
      for (var i = 0; i < units.length; i++) {
        pathPtr[i] = units[i];
      }
      pathPtr[units.length] = 0;
      pathPtr[units.length + 1] = 0;

      GlobalUnlock(hMem);

      if (!OpenClipboard(null).value) {
        GlobalFree(hMem);
        return false;
      }
      try {
        EmptyClipboard();
        final accepted = SetClipboardData(CF_HDROP, HANDLE(hMem)).value;
        if (accepted == nullptr) {
          GlobalFree(hMem);
          return false;
        }
        // The clipboard now owns hMem; it must not be freed here.
        return true;
      } finally {
        CloseClipboard();
      }
    } catch (_) {
      return false;
    }
  }
}
