import 'package:flutter_test/flutter_test.dart';
import 'package:tk_random/services/update_service.dart';

void main() {
  group('isNewerVersion', () {
    test('a higher patch is newer', () {
      expect(isNewerVersion('1.2.10', '1.2.9'), isTrue);
    });

    test('a higher minor beats a higher patch on the other side', () {
      expect(isNewerVersion('1.3.0', '1.2.99'), isTrue);
    });

    test('an equal version is not newer', () {
      expect(isNewerVersion('1.2.0', '1.2.0'), isFalse);
    });

    test('an older version is not newer', () {
      expect(isNewerVersion('1.0.0', '1.2.0'), isFalse);
    });

    test('missing trailing segments count as zero', () {
      expect(isNewerVersion('1.2', '1.2.0'), isFalse);
      expect(isNewerVersion('1.2.1', '1.2'), isTrue);
    });
  });
}
