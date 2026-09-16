import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/bracket.dart';
import '../services/pdf_export_service.dart';
import '../widgets/bracket_tree_view.dart';

class BracketViewScreen extends StatelessWidget {
  final WeightGroupDraw draw;
  final String? tournamentName;
  final DateTime? tournamentDate;

  const BracketViewScreen({
    super.key,
    required this.draw,
    this.tournamentName,
    this.tournamentDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(draw.key.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Печать / экспорт в PDF',
            onPressed: () async {
              final doc = await PdfExportService.buildBracketDocument(
                draw,
                tournamentName: tournamentName,
                tournamentDate: tournamentDate,
              );
              await Printing.layoutPdf(
                onLayout: (format) => doc.save(),
                name: draw.key.label,
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Участников: ${draw.participants.length} · '
              '${draw.key.ageCategory.label} · ${draw.key.gender.label} · '
              'до ${draw.key.weightClass.label} кг',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(child: BracketTreeView(draw: draw)),
        ],
      ),
    );
  }
}
