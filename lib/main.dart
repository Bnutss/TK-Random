import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'services/athlete_repository.dart';
import 'services/tournament_repository.dart';

void main() {
  runApp(const TkRandomApp());
}

class TkRandomApp extends StatefulWidget {
  const TkRandomApp({super.key});

  @override
  State<TkRandomApp> createState() => _TkRandomAppState();
}

class _TkRandomAppState extends State<TkRandomApp> {
  final athleteRepository = AthleteRepository();
  final tournamentRepository = TournamentRepository();
  late final Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = Future.wait([
      athleteRepository.load(),
      tournamentRepository.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Жеребьёвка турнира',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return HomeShell(
            athleteRepository: athleteRepository,
            tournamentRepository: tournamentRepository,
          );
        },
      ),
    );
  }
}
