import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_random/models/age_category.dart';
import 'package:tk_random/screens/home_shell.dart';
import 'package:tk_random/services/athlete_repository.dart';
import 'package:tk_random/services/category_repository.dart';
import 'package:tk_random/services/tournament_repository.dart';

void main() {
  testWidgets('Посещения shows the in-development placeholder', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1360, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      FluentApp(
        home: HomeShell(
          athleteRepository: AthleteRepository(),
          categoryRepository: CategoryRepository.seeded(defaultAgeCategories()),
          tournamentRepository: TournamentRepository(),
          checkForUpdate: () async => null,
          appVersion: '1.0.0',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Посещения'));
    await tester.pumpAndSettle();

    expect(find.text('В разработке'), findsOneWidget);
  });
}
