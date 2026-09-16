import 'package:flutter/material.dart';

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
    final destinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.groups_outlined),
        selectedIcon: const Icon(Icons.groups),
        label: const Text('Участники'),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.shuffle_outlined),
        selectedIcon: const Icon(Icons.shuffle),
        label: const Text('Жеребьёвка'),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history),
        label: const Text('История'),
      ),
    ];

    final pages = [
      AthletesScreen(repository: widget.athleteRepository),
      DrawScreen(
        athleteRepository: widget.athleteRepository,
        tournamentRepository: widget.tournamentRepository,
      ),
      HistoryScreen(repository: widget.tournamentRepository),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_index]),
        ],
      ),
    );
  }
}
