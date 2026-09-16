import 'package:fluent_ui/fluent_ui.dart';

/// Placeholder for the upcoming attendance-tracking feature.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ScaffoldPage(
      header: const PageHeader(title: Text('Посещения')),
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.construction_cone,
              size: 48,
              color: theme.resources.textFillColorSecondary,
            ),
            const SizedBox(height: 16),
            Text('В разработке', style: theme.typography.subtitle),
            const SizedBox(height: 8),
            Text(
              'Учёт посещений тренировок появится в одном из следующих обновлений.',
              textAlign: TextAlign.center,
              style: theme.typography.body?.copyWith(
                color: theme.resources.textFillColorSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
