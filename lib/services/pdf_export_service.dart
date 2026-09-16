import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/bracket.dart';

/// Brand accent matching [brandAccent] in `lib/theme/app_theme.dart`.
const _brandColor = PdfColor.fromInt(0xFF12A6B8);
const _mutedColor = PdfColor.fromInt(0xFF6E6E6E);
const _lineColor = PdfColor.fromInt(0xFFB9B9B9);

class PdfExportService {
  PdfExportService._();

  static pw.Font? _font;
  static pw.Font? _fontBold;
  static pw.MemoryImage? _logo;

  static Future<pw.Font> _loadFont() async {
    final cached = _font;
    if (cached != null) return cached;
    final data = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final font = pw.Font.ttf(data);
    _font = font;
    return font;
  }

  /// The bundled Roboto is a variable font, so "bold" reuses the same
  /// outlines; headings lean on size/color/letter-spacing instead of weight.
  static Future<pw.Font> _loadFontBold() async {
    final cached = _fontBold;
    if (cached != null) return cached;
    final font = await _loadFont();
    _fontBold = font;
    return font;
  }

  static Future<pw.MemoryImage> _loadLogo() async {
    final cached = _logo;
    if (cached != null) return cached;
    final data = await rootBundle.load('assets/images/logo.png');
    final image = pw.MemoryImage(data.buffer.asUint8List());
    _logo = image;
    return image;
  }

  static Future<pw.Document> buildBracketDocument(
    WeightGroupDraw draw, {
    String? tournamentName,
    DateTime? tournamentDate,
  }) async {
    final font = await _loadFont();
    final fontBold = await _loadFontBold();
    final logo = await _loadLogo();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(logo, fontBold, tournamentName),
              pw.SizedBox(height: 14),
              _buildInfoGrid(draw, fontBold, tournamentDate),
              pw.SizedBox(height: 16),
              pw.Expanded(
                child: _BracketPainter(
                  draw: draw,
                  font: font,
                  fontBold: fontBold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildFooter(draw, font),
            ],
          );
        },
      ),
    );
    return doc;
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage logo,
    pw.Font fontBold,
    String? tournamentName,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.ClipRRect(
          horizontalRadius: 6,
          verticalRadius: 6,
          child: pw.Image(logo, width: 46, height: 46, fit: pw.BoxFit.cover),
        ),
        pw.SizedBox(width: 14),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TAEKWONDO WT  ·  SALIYEV TEAM',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9.5,
                  color: _brandColor,
                  letterSpacing: 1.4,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                tournamentName ?? 'Турнирная сетка',
                style: pw.TextStyle(font: fontBold, fontSize: 19),
              ),
            ],
          ),
        ),
        pw.Text(
          'Протокол жеребьёвки',
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: _mutedColor),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoGrid(
    WeightGroupDraw draw,
    pw.Font fontBold,
    DateTime? tournamentDate,
  ) {
    final key = draw.key;
    final dateLabel = tournamentDate != null
        ? DateFormat('dd.MM.yyyy').format(tournamentDate)
        : '—';
    final cells = [
      ('Категория', key.ageCategoryLabel),
      ('Годы рождения', key.ageCategoryYearRangeLabel),
      ('Пол', key.gender.label == 'М' ? 'Мужской' : 'Женский'),
      ('Весовая категория', 'до ${key.weightClass.label} кг'),
      ('Дата', dateLabel),
      ('Участников', '${draw.participants.length}'),
    ];
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _lineColor, width: 0.7),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: i == cells.length - 1
                    ? null
                    : pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(color: _lineColor, width: 0.7),
                        ),
                      ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      cells[i].$1,
                      style: pw.TextStyle(fontSize: 7.5, color: _mutedColor),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      cells[i].$2,
                      style: pw.TextStyle(font: fontBold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(WeightGroupDraw draw, pw.Font font) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'Всего участников: ${draw.participants.length}',
          style: pw.TextStyle(font: font, fontSize: 9, color: _mutedColor),
        ),
        pw.Spacer(),
        _signatureLine('Главный судья'),
        pw.SizedBox(width: 36),
        _signatureLine('Секретарь'),
      ],
    );
  }

  static pw.Widget _signatureLine(String label) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: const pw.TextStyle(fontSize: 9, color: _mutedColor),
        ),
        pw.Container(width: 140, height: 0.7, color: _lineColor),
      ],
    );
  }
}

/// Draws the bracket tree (match boxes + connector lines), auto-scaled to
/// always fit the space [pw.Expanded] gives it on a single A4 landscape page.
class _BracketPainter extends pw.StatelessWidget {
  final WeightGroupDraw draw;
  final pw.Font font;
  final pw.Font fontBold;

  static const _cardWidth = 150.0;
  static const _cardHeight = 30.0;
  static const _roundGap = 42.0;
  static const _rowHeight = 40.0;

  _BracketPainter({
    required this.draw,
    required this.font,
    required this.fontBold,
  });

  @override
  pw.Widget build(pw.Context context) {
    final rounds = draw.rounds;
    final firstRoundCount = rounds.first.length;
    final naturalWidth =
        rounds.length * _cardWidth + (rounds.length - 1) * _roundGap;
    final naturalHeight = firstRoundCount * _rowHeight;

    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints!.maxWidth;
        final availableHeight = constraints.maxHeight;
        final scale = math.min(
          1.0,
          math.min(
            availableWidth / naturalWidth,
            availableHeight / naturalHeight,
          ),
        );

        final cardWidth = _cardWidth * scale;
        final cardHeight = _cardHeight * scale;
        final roundGap = _roundGap * scale;
        final rowHeight = _rowHeight * scale;
        final fontSize = math.max(5.5, 8.5 * scale);
        final numberFontSize = math.max(5.0, 6.5 * scale);

        // y-center of every match, per round, computed bottom-up so each
        // parent match sits centered between its two feeder matches.
        final centers = <List<double>>[];
        centers.add(
          List.generate(firstRoundCount, (i) => rowHeight / 2 + i * rowHeight),
        );
        for (var r = 1; r < rounds.length; r++) {
          final previous = centers[r - 1];
          centers.add(
            List.generate(
              rounds[r].length,
              (i) => (previous[2 * i] + previous[2 * i + 1]) / 2,
            ),
          );
        }

        final children = <pw.Widget>[];

        // Connector lines between each round and the next.
        for (var r = 0; r < rounds.length - 1; r++) {
          final x = r * (cardWidth + roundGap);
          final xMid = x + cardWidth + roundGap / 2;
          for (var i = 0; i < rounds[r].length; i += 2) {
            final yTop = centers[r][i];
            final yBottom = centers[r][i + 1];
            final yNext = centers[r + 1][i ~/ 2];
            children.add(_line(x + cardWidth, yTop, xMid, yTop));
            children.add(_line(x + cardWidth, yBottom, xMid, yBottom));
            children.add(_line(xMid, yTop, xMid, yBottom));
            children.add(_line(xMid, yNext, x + cardWidth + roundGap, yNext));
          }
        }

        // Match cards, on top of the connector lines.
        for (var r = 0; r < rounds.length; r++) {
          final x = r * (cardWidth + roundGap);
          for (var i = 0; i < rounds[r].length; i++) {
            final match = rounds[r][i];
            final y = centers[r][i] - cardHeight / 2;
            children.add(
              pw.Positioned(
                left: x,
                top: y,
                child: _matchCard(
                  match,
                  width: cardWidth,
                  height: cardHeight,
                  fontSize: fontSize,
                  numberFontSize: numberFontSize,
                  numbered: r == 0,
                  baseIndex: i * 2 + 1,
                ),
              ),
            );
          }
        }

        return pw.Center(
          child: pw.SizedBox(
            width: naturalWidth * scale,
            height: naturalHeight * scale,
            child: pw.Stack(children: children),
          ),
        );
      },
    );
  }

  pw.Widget _line(double x1, double y1, double x2, double y2) {
    return pw.Positioned(
      left: math.min(x1, x2),
      top: math.min(y1, y2),
      child: pw.CustomPaint(
        size: PdfPoint(
          (x2 - x1).abs().clamp(0.01, double.infinity),
          (y2 - y1).abs().clamp(0.01, double.infinity),
        ),
        painter: (canvas, size) {
          canvas
            ..setStrokeColor(_lineColor)
            ..setLineWidth(0.9)
            ..drawLine(
              x1 < x2 ? 0 : size.x,
              y1 < y2 ? 0 : size.y,
              x1 < x2 ? size.x : 0,
              y1 < y2 ? size.y : 0,
            )
            ..strokePath();
        },
      ),
    );
  }

  pw.Widget _matchCard(
    BracketMatch match, {
    required double width,
    required double height,
    required double fontSize,
    required double numberFontSize,
    required bool numbered,
    required int baseIndex,
  }) {
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _lineColor, width: 0.7),
        borderRadius: pw.BorderRadius.circular(3),
        color: PdfColors.white,
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _slotLine(
            match.slotA,
            fontSize,
            numberFontSize,
            numbered ? baseIndex : null,
          ),
          pw.Container(
            height: 0.6,
            color: _lineColor,
            margin: const pw.EdgeInsets.symmetric(horizontal: 6),
          ),
          _slotLine(
            match.slotB,
            fontSize,
            numberFontSize,
            numbered ? baseIndex + 1 : null,
          ),
        ],
      ),
    );
  }

  pw.Widget _slotLine(
    BracketSlot slot,
    double fontSize,
    double numberFontSize,
    int? number,
  ) {
    String label;
    PdfColor color = PdfColors.black;
    if (slot.athlete != null) {
      label = slot.athlete!.fullName;
    } else if (slot.isBye) {
      label = 'БАЙ';
      color = _mutedColor;
    } else {
      label = '';
      color = _mutedColor;
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
      child: pw.Row(
        children: [
          if (number != null) ...[
            pw.SizedBox(
              width: 12,
              child: pw.Text(
                '$number',
                style: pw.TextStyle(
                  fontSize: numberFontSize,
                  color: _mutedColor,
                ),
              ),
            ),
          ],
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: fontSize, color: color),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }
}
