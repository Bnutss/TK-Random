import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/bracket.dart';

class PdfExportService {
  PdfExportService._();

  static pw.Font? _font;

  static Future<pw.Font> _loadFont() async {
    final cached = _font;
    if (cached != null) return cached;
    final data = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final font = pw.Font.ttf(data);
    _font = font;
    return font;
  }

  static Future<pw.Document> buildBracketDocument(
    WeightGroupDraw draw, {
    String? tournamentName,
    DateTime? tournamentDate,
  }) async {
    final font = await _loadFont();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    final dateFormat = DateFormat('dd.MM.yyyy');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          if (tournamentName != null)
            pw.Text(tournamentName, style: const pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Протокол жеребьёвки',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _infoTable(draw, dateFormat, tournamentDate),
          pw.SizedBox(height: 16),
          for (var i = 0; i < draw.rounds.length; i++) ...[
            pw.Text(
              _roundLabel(i, draw.rounds.length),
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            ...draw.rounds[i].map(_matchRow),
            pw.SizedBox(height: 10),
          ],
          pw.SizedBox(height: 12),
          pw.Text('Всего участников: ${draw.participants.length}'),
        ],
      ),
    );
    return doc;
  }

  static pw.Widget _infoTable(
    WeightGroupDraw draw,
    DateFormat dateFormat,
    DateTime? tournamentDate,
  ) {
    final key = draw.key;
    final rows = <List<String>>[
      ['Категория', key.ageCategory.label],
      ['Годы рождения', key.ageCategory.yearRangeLabel],
      ['Пол', key.gender.label],
      ['Весовая категория', 'до ${key.weightClass.label} кг'],
      if (tournamentDate != null) ['Дата', dateFormat.format(tournamentDate)],
    ];
    return pw.Table(
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(2)},
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(
                  row[0],
                  style: const pw.TextStyle(color: PdfColors.grey700),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Text(row[1]),
              ),
            ],
          ),
      ],
    );
  }

  static String _roundLabel(int roundIndex, int totalRounds) {
    final fromEnd = totalRounds - roundIndex;
    return switch (fromEnd) {
      1 => 'Финал',
      2 => '1/2 финала',
      3 => '1/4 финала',
      4 => '1/8 финала',
      _ => 'Раунд ${roundIndex + 1}',
    };
  }

  static pw.Widget _matchRow(BracketMatch match) {
    String label(BracketSlot slot) {
      if (slot.athlete != null) return slot.athlete!.fullName;
      if (slot.isBye) return 'БАЙ';
      return '—';
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 20, child: pw.Text('${match.indexInRound + 1}.')),
          pw.Expanded(child: pw.Text(label(match.slotA))),
          pw.SizedBox(
            width: 24,
            child: pw.Text('vs', textAlign: pw.TextAlign.center),
          ),
          pw.Expanded(child: pw.Text(label(match.slotB))),
        ],
      ),
    );
  }
}
