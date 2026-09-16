import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

import 'screens/home_shell.dart';
import 'services/athlete_repository.dart';
import 'services/category_repository.dart';
import 'services/tournament_repository.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1360, 840),
    minimumSize: Size(1100, 700),
    center: true,
    title: 'TK Random',
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const TkRandomApp());
}

class TkRandomApp extends StatefulWidget {
  const TkRandomApp({super.key});

  @override
  State<TkRandomApp> createState() => _TkRandomAppState();
}

class _TkRandomAppState extends State<TkRandomApp> {
  final athleteRepository = AthleteRepository();
  final categoryRepository = CategoryRepository();
  final tournamentRepository = TournamentRepository();
  late final Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = Future.wait([
      athleteRepository.load(),
      categoryRepository.load(),
      tournamentRepository.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'TK Random',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ScaffoldPage(content: Center(child: ProgressRing()));
          }
          return HomeShell(
            athleteRepository: athleteRepository,
            categoryRepository: categoryRepository,
            tournamentRepository: tournamentRepository,
          );
        },
      ),
    );
  }
}
