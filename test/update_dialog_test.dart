import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_random/models/age_category.dart';
import 'package:tk_random/screens/home_shell.dart';
import 'package:tk_random/services/athlete_repository.dart';
import 'package:tk_random/services/category_repository.dart';
import 'package:tk_random/services/tournament_repository.dart';
import 'package:tk_random/services/update_service.dart';

void main() {
  Widget buildApp(Future<UpdateInfo?> Function() checkForUpdate) => FluentApp(
    home: HomeShell(
      athleteRepository: AthleteRepository(),
      categoryRepository: CategoryRepository.seeded(defaultAgeCategories()),
      tournamentRepository: TournamentRepository(),
      checkForUpdate: checkForUpdate,
    ),
  );

  testWidgets('shows an update dialog when a newer version is found', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        () async => const UpdateInfo(
          version: '9.9.9',
          releaseUrl: 'https://github.com/Bnutss/TK-Random/releases/tag/v9.9.9',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Доступно обновление'), findsOneWidget);
    expect(find.textContaining('9.9.9'), findsOneWidget);

    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();

    expect(find.text('Доступно обновление'), findsNothing);
  });

  testWidgets('shows nothing when already up to date', (tester) async {
    await tester.pumpWidget(buildApp(() async => null));
    await tester.pumpAndSettle();

    expect(find.text('Доступно обновление'), findsNothing);
  });
}
