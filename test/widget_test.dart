import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_random/models/age_category.dart';
import 'package:tk_random/screens/home_shell.dart';
import 'package:tk_random/services/athlete_repository.dart';
import 'package:tk_random/services/category_repository.dart';
import 'package:tk_random/services/tournament_repository.dart';

void main() {
  // Repositories are used unloaded (no .load() call) so the test never
  // touches real file I/O via path_provider/dart:io. CategoryRepository is
  // seeded in-memory instead, since it has no persistence-free defaults.
  Widget buildApp() => FluentApp(
    home: HomeShell(
      athleteRepository: AthleteRepository(),
      categoryRepository: CategoryRepository.seeded(defaultAgeCategories()),
      tournamentRepository: TournamentRepository(),
    ),
  );

  testWidgets('Starts empty and adds an athlete through the form', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('Список участников пуст'), findsOneWidget);

    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('athlete_name_field')),
      'Test Athlete',
    );
    await tester.enterText(find.byKey(const Key('athlete_year_field')), '2011');
    await tester.enterText(find.byKey(const Key('athlete_weight_field')), '50');

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Test Athlete'), findsOneWidget);
    expect(find.text('Юниор'), findsOneWidget);
  });
}
