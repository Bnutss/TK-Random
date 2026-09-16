import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_random/screens/home_shell.dart';
import 'package:tk_random/services/athlete_repository.dart';
import 'package:tk_random/services/tournament_repository.dart';

void main() {
  // Repositories are used unloaded (no .load() call) so the test never
  // touches real file I/O via path_provider/dart:io.
  Widget buildApp() => MaterialApp(
    home: HomeShell(
      athleteRepository: AthleteRepository(),
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
      find.widgetWithText(TextFormField, 'Ф.И. спортсмена'),
      'Test Athlete',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Год рождения'),
      '2011',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Вес, кг'), '50');

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Test Athlete'), findsOneWidget);
    expect(find.text('Юниор'), findsOneWidget);
  });
}
