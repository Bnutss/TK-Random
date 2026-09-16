import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_random/models/age_category.dart';
import 'package:tk_random/models/gender.dart';
import 'package:tk_random/screens/home_shell.dart';
import 'package:tk_random/services/athlete_repository.dart';
import 'package:tk_random/services/category_repository.dart';
import 'package:tk_random/services/tournament_repository.dart';

/// Opening a bracket pushes BracketViewScreen as its own route on top of
/// HomeShell's NavigationView, so the side pane isn't reachable from there
/// at all — the only way out used to be an app restart. Guards that a back
/// button is present and actually returns to the previous screen.
void main() {
  testWidgets('the back button on an opened bracket returns to Жеребьёвка', (
    tester,
  ) async {
    // Wide enough that the nav pane stays expanded (labels directly
    // tappable) — narrow-width pane behavior is covered separately in
    // navigation_responsive_test.dart.
    await tester.binding.setSurfaceSize(const Size(1360, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final athleteRepository = AthleteRepository();
    await tester.pumpWidget(
      FluentApp(
        home: HomeShell(
          athleteRepository: athleteRepository,
          categoryRepository: CategoryRepository.seeded(defaultAgeCategories()),
          tournamentRepository: TournamentRepository(),
          checkForUpdate: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Two athletes in the same age/gender/weight group, so a draw can be
    // generated for them.
    await athleteRepository.add(
      fullName: 'Athlete One',
      birthYear: 2011,
      gender: Gender.male,
      weightKg: 50,
    );
    await athleteRepository.add(
      fullName: 'Athlete Two',
      birthYear: 2011,
      gender: Gender.male,
      weightKg: 50,
    );

    await tester.tap(find.text('Жеребьёвка'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Сформировать все сетки'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Открыть сетку'));
    await tester.pumpAndSettle();

    // No side pane on this route, but the back button must be there and
    // must work.
    expect(find.text('Участники'), findsNothing);
    final backButton = find.widgetWithIcon(IconButton, FluentIcons.back);
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Сформировать все сетки'), findsOneWidget);
  });
}
