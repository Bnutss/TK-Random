import 'package:fluent_ui/fluent_ui.dart';

import '../services/athlete_repository.dart';
import '../services/category_repository.dart';
import '../services/tournament_repository.dart';
import 'athletes_screen.dart';
import 'categories_screen.dart';
import 'draw_screen.dart';
import 'history_screen.dart';

class HomeShell extends StatefulWidget {
  final AthleteRepository athleteRepository;
  final CategoryRepository categoryRepository;
  final TournamentRepository tournamentRepository;

  const HomeShell({
    super.key,
    required this.athleteRepository,
    required this.categoryRepository,
    required this.tournamentRepository,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

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
