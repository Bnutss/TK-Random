import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_random/models/athlete.dart';
import 'package:tk_random/models/bracket.dart';
import 'package:tk_random/models/gender.dart';
import 'package:tk_random/models/weight_class.dart';
import 'package:tk_random/screens/bracket_view_screen.dart';
import 'package:tk_random/services/bracket_generator.dart';

/// Only the "Telegram isn't installed" branch is safe to exercise here:
/// the "proceed anyway" / actually-installed path goes on to call the real
/// Win32 clipboard API (via package:win32's FFI bindings to user32.dll),
/// which doesn't exist on this test runner and would crash rather than
/// no-op. That path is Windows-only by nature and untested by design.
void main() {
  final key = GroupKey(
    ageCategoryId: 'junior',
    ageCategoryLabel: 'Юниор',
    ageCategoryYearRangeLabel: '2010–2012',
    ageCategoryOrder: 1,
    gender: Gender.male,
    weightClass: const WeightClass(baseValue: 51, isOpenTop: false),
  );
  final athletes = List.generate(
    2,
    (i) => Athlete(
      id: 'id$i',
      fullName: 'Athlete $i',
      birthYear: 2011,
      gender: Gender.male,
      weightKg: 50,
    ),
  );
  final draw = generateDraw(key, athletes);

  testWidgets('offers to open the download page when Telegram is not found', (
    tester,
  ) async {
    await tester.pumpWidget(
      FluentApp(
        home: BracketViewScreen(
          draw: draw,
          isTelegramInstalled: () async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Отправить в Telegram'));
    await tester.pumpAndSettle();

    expect(find.text('Telegram не найден'), findsOneWidget);
    expect(find.text('Скачать Telegram'), findsOneWidget);
    expect(find.text('Всё равно открыть'), findsOneWidget);

    // Cancelling must not fall through to the real clipboard/launch code.
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Telegram не найден'), findsNothing);
  });
}
