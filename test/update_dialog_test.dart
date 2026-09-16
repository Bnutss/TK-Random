import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tk_random/models/age_category.dart';
import 'package:tk_random/screens/home_shell.dart';
import 'package:tk_random/services/athlete_repository.dart';
import 'package:tk_random/services/category_repository.dart';
import 'package:tk_random/services/tournament_repository.dart';
import 'package:tk_random/services/update_service.dart';

void main() {
  Widget buildApp(
    Future<UpdateInfo?> Function() checkForUpdate, {
    Future<File> Function(
      UpdateInfo update, {
      void Function(int received, int total)? onProgress,
    })?
    downloadUpdate,
  }) => FluentApp(
    home: HomeShell(
      athleteRepository: AthleteRepository(),
      categoryRepository: CategoryRepository.seeded(defaultAgeCategories()),
      tournamentRepository: TournamentRepository(),
      checkForUpdate: checkForUpdate,
      appVersion: '1.0.0',
      // A test that reaches the "Скачать" button without stubbing this
      // should fail loudly, not silently hit the real network.
      downloadUpdate:
          downloadUpdate ??
          (_, {onProgress}) async =>
              throw UnimplementedError('downloadUpdate not stubbed'),
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

  testWidgets('downloads the update and reports where it was saved', (
    tester,
  ) async {
    final savedFile = File('${Directory.systemTemp.path}/tk_random_test.zip');

    await tester.pumpWidget(
      buildApp(
        () async => const UpdateInfo(
          version: '9.9.9',
          releaseUrl: 'https://github.com/Bnutss/TK-Random/releases/tag/v9.9.9',
          downloadUrl: 'https://example.com/tk_random-windows.zip',
          assetName: 'tk_random-windows.zip',
          assetSize: 100,
        ),
        downloadUpdate: (update, {onProgress}) async {
          onProgress?.call(50, 100);
          onProgress?.call(100, 100);
          return savedFile;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Скачать'));
    await tester.pumpAndSettle();

    expect(find.text('Обновление скачано'), findsOneWidget);
    expect(find.textContaining(savedFile.path), findsOneWidget);

    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    expect(find.text('Обновление скачано'), findsNothing);
  });

  testWidgets('shows a fallback when the download itself fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        () async => const UpdateInfo(
          version: '9.9.9',
          releaseUrl: 'https://github.com/Bnutss/TK-Random/releases/tag/v9.9.9',
          downloadUrl: 'https://example.com/tk_random-windows.zip',
        ),
        downloadUpdate: (update, {onProgress}) async {
          throw const HttpException('boom');
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Скачать'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось скачать'), findsOneWidget);
    expect(find.text('Открыть страницу релиза'), findsOneWidget);
  });
}
