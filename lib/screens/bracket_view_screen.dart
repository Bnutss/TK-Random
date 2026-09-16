import 'package:fluent_ui/fluent_ui.dart';
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
    final theme = FluentTheme.of(context);
    return ScaffoldPage(
      header: PageHeader(
        title: Text(draw.key.label),
        commandBar: FilledButton(
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
          child: const Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.print, size: 15),
                SizedBox(width: 8),
                Text('Печать / PDF'),
              ],
            ),
          ),
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Участников: ${draw.participants.length} · '
              '${draw.key.ageCategory.label} · ${draw.key.gender.label} · '
              'до ${draw.key.weightClass.label} кг',
              style: theme.typography.body,
            ),
          ),
          Expanded(child: BracketTreeView(draw: draw)),
        ],
      ),
    );
  }
}
