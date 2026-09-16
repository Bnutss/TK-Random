import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/bracket.dart';
import '../services/pdf_export_service.dart';
import '../services/telegram_share_service.dart';
import '../widgets/bracket_tree_view.dart';

class BracketViewScreen extends StatelessWidget {
  final WeightGroupDraw draw;
  final String? tournamentName;
  final DateTime? tournamentDate;

  /// Whether Telegram is registered for `tg://` links on this machine.
  /// Defaults to the real registry check; tests override it to avoid
  /// touching the real Windows registry.
  final Future<bool> Function() isTelegramInstalled;

  const BracketViewScreen({
    super.key,
    required this.draw,
    this.tournamentName,
    this.tournamentDate,
    this.isTelegramInstalled = TelegramShareService.isInstalled,
  });

  String _sanitizedFileName() =>
      '${draw.key.label}.pdf'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  Future<void> _shareToTelegram(BuildContext context) async {
    final installed = await isTelegramInstalled();
    if (!installed) {
      if (!context.mounted) return;
      final proceedAnyway = await showDialog<bool>(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Telegram не найден'),
          content: const Text(
            'Не удалось найти установленный Telegram Desktop на этом '
            'компьютере. Если он всё же установлен (например, портативная '
            'версия без установщика), можно попробовать продолжить всё '
            'равно.',
          ),
          actions: [
            Button(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            Button(
              onPressed: () {
                Navigator.of(context).pop(false);
                launchUrl(
                  Uri.parse('https://desktop.telegram.org'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('Скачать Telegram'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Всё равно открыть'),
            ),
          ],
        ),
      );
      if (proceedAnyway != true) return;
    }

    if (!context.mounted) return;

    final dir =
        await getDownloadsDirectory() ?? await getApplicationSupportDirectory();
    final file = File('${dir.path}/${_sanitizedFileName()}');
    final doc = await PdfExportService.buildBracketDocument(
      draw,
      tournamentName: tournamentName,
      tournamentDate: tournamentDate,
    );
    await file.writeAsBytes(await doc.save());

    // Telegram Desktop has no API for a third-party app to hand it a file
    // plus a chosen contact directly, so the next best thing: put the file
    // on the clipboard in the same format Explorer uses for copy/paste, and
    // bring Telegram to the front so the user only needs to open a chat and
    // press Ctrl+V.
    final copiedToClipboard = TelegramShareService.copyFileToClipboard(file);
    await launchUrl(Uri.parse('tg://'), mode: LaunchMode.externalApplication);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Telegram открыт'),
        content: Text(
          copiedToClipboard
              ? 'Файл сетки скопирован в буфер обмена — откройте нужный чат '
                    'в Telegram и нажмите Ctrl+V, чтобы отправить его.'
              : 'Не удалось автоматически положить файл в буфер обмена. '
                    'Он сохранён здесь:\n${file.path}',
        ),
        actions: [
          if (!copiedToClipboard)
            Button(
              onPressed: () {
                Navigator.of(context).pop();
                Process.run('explorer.exe', ['/select,', file.path]);
              },
              child: const Text('Открыть папку'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ок'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ScaffoldPage(
      header: PageHeader(
        // This screen is pushed as its own route on top of HomeShell's
        // NavigationView, so the side pane and its hamburger toggle aren't
        // part of this page at all — without an explicit way back, the
        // only way out is to restart the app. PaneBackButton doesn't work
        // here (it requires a NavigationView ancestor, which this route
        // doesn't have), so this is a plain back button tied to the pop
        // that got us here.
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: Navigator.of(context).canPop()
              ? () => Navigator.of(context).pop()
              : null,
        ),
        title: Text(draw.key.label),
        commandBar: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Button(
              onPressed: () => _shareToTelegram(context),
              child: const Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.send, size: 15),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Отправить в Telegram',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                // `format` reflects whatever paper size/orientation the
                // print dialog is currently set to — rebuilding on every
                // call (rather than reusing one fixed document) is what
                // lets the built-in picker actually change the output,
                // including switching back to portrait if that's ever
                // preferred for a given printer.
                await Printing.layoutPdf(
                  format: PdfExportService.defaultPageFormat,
                  onLayout: (format) async {
                    final doc = await PdfExportService.buildBracketDocument(
                      draw,
                      tournamentName: tournamentName,
                      tournamentDate: tournamentDate,
                      pageFormat: format,
                    );
                    return doc.save();
                  },
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
                    Flexible(
                      child: Text(
                        'Печать / PDF',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Участников: ${draw.participants.length} · '
              '${draw.key.ageCategoryLabel} · ${draw.key.gender.label} · '
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
