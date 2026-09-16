import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_random/models/age_category.dart';
import 'package:tk_random/screens/home_shell.dart';
import 'package:tk_random/services/athlete_repository.dart';
import 'package:tk_random/services/category_repository.dart';
import 'package:tk_random/services/tournament_repository.dart';

/// Guards the navigation pane's adaptive behaviour. `.hitTestable()` is used
/// throughout because the pane stays mounted (for its animation) even while
/// visually collapsed, so a plain `find.text` would find labels that are on
/// screen but not actually tappable — hiding exactly the regression this
/// guards against: a hamburger toggle that renders but does nothing, because
/// [NavigationPane.displayMode] was pinned to [PaneDisplayMode.expanded]
/// instead of adapting ([PaneDisplayMode.auto]) to the window width.
void main() {
  Widget buildApp() => FluentApp(
    home: HomeShell(
      athleteRepository: AthleteRepository(),
      categoryRepository: CategoryRepository.seeded(defaultAgeCategories()),
      tournamentRepository: TournamentRepository(),
      checkForUpdate: () async => null,
    ),
  );

  testWidgets('wide window shows every pane item directly, reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1360, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // "Участники" is both the pane label and the current page's own header.
    expect(find.text('Участники').hitTestable(), findsNWidgets(2));
    expect(find.text('Жеребьёвка').hitTestable(), findsOneWidget);
    expect(find.text('История').hitTestable(), findsOneWidget);
    expect(find.text('Категории').hitTestable(), findsOneWidget);
  });

  testWidgets(
    'narrow window collapses to a hamburger that actually opens the menu',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Pane labels aren't reachable yet: only the current page's own
      // header ("Участники") is. The other pane items are not tappable.
      expect(find.text('Участники').hitTestable(), findsOneWidget);
      expect(find.text('Жеребьёвка').hitTestable(), findsNothing);
      expect(find.text('История').hitTestable(), findsNothing);
      expect(find.text('Категории').hitTestable(), findsNothing);

      final toggle = find.byType(PaneToggleButton).hitTestable();
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Opening the hamburger makes every item reachable, including the
      // one added for category management.
      expect(find.text('Жеребьёвка').hitTestable(), findsOneWidget);
      expect(find.text('История').hitTestable(), findsOneWidget);
      expect(find.text('Категории').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Категории').hitTestable());
      await tester.pumpAndSettle();

      expect(find.text('Добавить категорию'), findsOneWidget);
    },
  );
}
