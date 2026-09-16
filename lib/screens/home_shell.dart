import 'package:fluent_ui/fluent_ui.dart';

import '../services/athlete_repository.dart';
import '../services/tournament_repository.dart';
import 'athletes_screen.dart';
import 'draw_screen.dart';
import 'history_screen.dart';

class HomeShell extends StatefulWidget {
  final AthleteRepository athleteRepository;
  final TournamentRepository tournamentRepository;

  const HomeShell({
    super.key,
    required this.athleteRepository,
    required this.tournamentRepository,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return NavigationView(
      pane: NavigationPane(
        selected: _index,
        onChanged: (i) => setState(() => _index = i),
        size: const NavigationPaneSize(openWidth: 232),
        header: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, top: 8, bottom: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TK Random',
                  style: theme.typography.bodyStrong,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        displayMode: PaneDisplayMode.expanded,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.people),
            title: const Text('Участники'),
            body: AthletesScreen(repository: widget.athleteRepository),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.branch_fork2),
            title: const Text('Жеребьёвка'),
            body: DrawScreen(
              athleteRepository: widget.athleteRepository,
              tournamentRepository: widget.tournamentRepository,
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: const Text('История'),
            body: HistoryScreen(repository: widget.tournamentRepository),
          ),
        ],
      ),
    );
  }
}
