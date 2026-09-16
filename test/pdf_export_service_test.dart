import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:tk_random/models/athlete.dart';
import 'package:tk_random/models/bracket.dart';
import 'package:tk_random/models/gender.dart';
import 'package:tk_random/models/weight_class.dart';
import 'package:tk_random/services/bracket_generator.dart';
import 'package:tk_random/services/pdf_export_service.dart';

/// The `printing` package rebuilds the PDF via `onLayout(format)` every
/// time the user changes paper size/orientation in the print dialog — a
/// prior bug ignored that argument and always returned a pre-built
/// landscape document, so the dialog's own choice never actually reached
/// the output. These tests read the raw PDF bytes' `/MediaBox` (the only
/// reliable way to check page geometry without pulling in a full PDF
/// parser) to make sure the requested page format is the one that's
/// actually used.
void main() {
  // buildBracketDocument loads the bundled font/logo via rootBundle, which
  // needs the test binding initialized even outside of testWidgets.
  TestWidgetsFlutterBinding.ensureInitialized();

  final key = GroupKey(
    ageCategoryId: 'junior',
    ageCategoryLabel: 'Юниор',
    ageCategoryYearRangeLabel: '2010–2012',
    ageCategoryOrder: 1,
    gender: Gender.male,
    weightClass: const WeightClass(baseValue: 51, isOpenTop: false),
  );
  final athletes = List.generate(
    4,
    (i) => Athlete(
      id: 'id$i',
      fullName: 'Athlete $i',
      birthYear: 2011,
      gender: Gender.male,
      weightKg: 50,
    ),
  );
  final draw = generateDraw(key, athletes, random: Random(1));

  /// Extracts the first `/MediaBox [x0 y0 x1 y1]` found in the raw PDF
  /// bytes; that entry lives in the page dictionary and is written as
  /// plain text even though content streams are compressed.
  (double, double) firstMediaBoxSize(List<int> bytes) {
    final text = String.fromCharCodes(bytes);
    final match = RegExp(
      r'/MediaBox\s*\[\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*\]',
    ).firstMatch(text);
    expect(match, isNotNull, reason: 'no /MediaBox found in the PDF bytes');
    final x0 = double.parse(match!.group(1)!);
    final y0 = double.parse(match.group(2)!);
    final x1 = double.parse(match.group(3)!);
    final y1 = double.parse(match.group(4)!);
    return (x1 - x0, y1 - y0);
  }

  test('the default page format is landscape', () {
    expect(
      PdfExportService.defaultPageFormat.width,
      greaterThan(PdfExportService.defaultPageFormat.height),
    );
  });

  test('omitting pageFormat falls back to the landscape default', () async {
    final doc = await PdfExportService.buildBracketDocument(draw);
    final (width, height) = firstMediaBoxSize(await doc.save());
    expect(width, greaterThan(height));
  });

  test('an explicit landscape pageFormat is honored', () async {
    final doc = await PdfExportService.buildBracketDocument(
      draw,
      pageFormat: PdfPageFormat.a4.landscape,
    );
    final (width, height) = firstMediaBoxSize(await doc.save());
    expect(width, closeTo(PdfPageFormat.a4.landscape.width, 0.5));
    expect(height, closeTo(PdfPageFormat.a4.landscape.height, 0.5));
  });

  test('an explicit portrait pageFormat is honored, not silently forced '
      'to landscape', () async {
    final doc = await PdfExportService.buildBracketDocument(
      draw,
      pageFormat: PdfPageFormat.a4,
    );
    final (width, height) = firstMediaBoxSize(await doc.save());
    expect(height, greaterThan(width));
    expect(width, closeTo(PdfPageFormat.a4.width, 0.5));
    expect(height, closeTo(PdfPageFormat.a4.height, 0.5));
  });
}
