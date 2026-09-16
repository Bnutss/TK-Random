import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/athlete_repository.dart';
import '../services/category_repository.dart';
import '../services/tournament_repository.dart';
import '../services/update_service.dart';
import 'athletes_screen.dart';
import 'categories_screen.dart';
import 'draw_screen.dart';
import 'history_screen.dart';

class HomeShell extends StatefulWidget {
  final AthleteRepository athleteRepository;
  final CategoryRepository categoryRepository;
  final TournamentRepository tournamentRepository;

  /// The running app's own version (e.g. "1.3.0"), shown in the title bar
  /// so it's visible without digging into the exe's file properties. Passed
  /// in already resolved (see main.dart) rather than fetched here and
  /// applied via setState — that was tried first and reliably tripped a
  /// fluent_ui semantics-tree assertion whenever the resulting rebuild
  /// landed during the nav pane's collapsed-mode open/close animation.
  /// Empty until known.
  final String appVersion;

  /// Checks whether a newer version is published. Defaults to a real
  /// GitHub Releases check; tests override it to avoid real network calls.
  final Future<UpdateInfo?> Function() checkForUpdate;

  /// Downloads an update's asset. Defaults to the real implementation;
  /// tests override it to avoid real network/file I/O.
  final Future<File> Function(
    UpdateInfo update, {
    void Function(int received, int total)? onProgress,
  })
  downloadUpdate;

  const HomeShell({
    super.key,
    required this.athleteRepository,
    required this.categoryRepository,
    required this.tournamentRepository,
    required this.appVersion,
    this.checkForUpdate = UpdateService.checkForUpdate,
    this.downloadUpdate = UpdateService.downloadUpdate,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final update = await widget.checkForUpdate();
    if (update == null || !mounted) return;

    final shouldDownload = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Доступно обновление'),
        content: Text('Вышла версия ${update.version}. Скачать её сейчас?'),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Скачать'),
          ),
        ],
      ),
    );
    if (shouldDownload != true || !mounted) return;

    if (update.downloadUrl == null) {
      // The release has no attached asset yet — the browser is the only way.
      await launchUrl(
        Uri.parse(update.releaseUrl),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    await _downloadUpdate(update);
  }

  Future<void> _downloadUpdate(UpdateInfo update) async {
    final progress = ValueNotifier<double?>(0);

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ContentDialog(
          title: const Text('Загрузка обновления'),
          content: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (context, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressBar(value: value == null ? null : value * 100),
                const SizedBox(height: 10),
                Text(
                  value == null
                      ? 'Подключение…'
                      : '${(value * 100).toStringAsFixed(0)}%',
                  style: FluentTheme.of(context).typography.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    File? file;
    Object? error;
    try {
      file = await widget.downloadUpdate(
        update,
        onProgress: (received, total) {
          progress.value = total > 0 ? received / total : null;
        },
      );
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // close the progress dialog

    if (file == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Не удалось скачать'),
          content: Text(
            'Попробуйте открыть страницу релиза в браузере и скачать '
            'вручную.\n\n$error',
          ),
          actions: [
            Button(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                launchUrl(
                  Uri.parse(update.releaseUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('Открыть страницу релиза'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Обновление скачано'),
        content: Text(
          'Файл сохранён:\n${file!.path}\n\n'
          'Распакуйте его поверх текущей папки установки — данные '
          '(участники, категории, история) сохранятся.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(
                Process.run('explorer.exe', [
                  '/select,',
                  file!.path,
                ]).catchError((_) => ProcessResult(0, 0, '', '')),
              );
            },
            child: const Text('Открыть папку'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A titleBar is required for the pane's hamburger toggle to have a
    // permanent, always-tappable home. Without one, fluent_ui renders the
    // toggle *inside* the collapsible pane itself, so once the window gets
    // narrow enough to collapse to PaneDisplayMode.minimal, the toggle button
    // that's supposed to reopen the pane is hidden off-screen along with it
    // — a dead end with no way back into the menu. Putting the brand here
    // also keeps it visible in compact/minimal modes, where the pane's own
    // header is hidden.
    return NavigationView(
      titleBar: TitleBar(
        isBackButtonVisible: false,
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'assets/images/logo.png',
            width: 18,
            height: 18,
            fit: BoxFit.cover,
          ),
        ),
        title: const Text('TK Random'),
      ),
      pane: NavigationPane(
        selected: _index,
        onChanged: (i) => setState(() => _index = i),
        size: const NavigationPaneSize(openWidth: 232),
        displayMode: PaneDisplayMode.auto,
        // Shown only in the open pane (hidden in compact/minimal, same as
        // this app's old branding header used to be) — deliberately not in
        // titleBar's title/subtitle: appending the version there made that
        // text long enough to need eliding at narrow widths, and fluent_ui's
        // title/subtitle overflow logic doesn't tolerate that combined with
        // the pane's collapsed-mode open/close animation (trips a
        // `parentDataDirty` semantics assertion — debug/test builds only).
        header: widget.appVersion.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 4,
                  top: 8,
                  bottom: 4,
                ),
                child: Text(
                  'v${widget.appVersion}',
                  style: FluentTheme.of(context).typography.caption,
                ),
              ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.people),
            title: const Text('Участники'),
            body: AthletesScreen(
              repository: widget.athleteRepository,
              categoryRepository: widget.categoryRepository,
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.branch_fork2),
            title: const Text('Жеребьёвка'),
            body: DrawScreen(
              athleteRepository: widget.athleteRepository,
              categoryRepository: widget.categoryRepository,
              tournamentRepository: widget.tournamentRepository,
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: const Text('История'),
            body: HistoryScreen(repository: widget.tournamentRepository),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.category_classification),
            title: const Text('Категории'),
            body: CategoriesScreen(repository: widget.categoryRepository),
          ),
        ],
      ),
    );
  }
}
