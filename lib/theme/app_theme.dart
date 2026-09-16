import 'package:fluent_ui/fluent_ui.dart';

/// Brand accent derived from the club logo (Taekwondo WT · Saliyev Team).
final AccentColor brandAccent = AccentColor.swatch(const <String, Color>{
  'darkest': Color(0xFF0A4B54),
  'darker': Color(0xFF0C616C),
  'dark': Color(0xFF0E7A87),
  'normal': Color(0xFF12A6B8),
  'light': Color(0xFF3FC4D4),
  'lighter': Color(0xFF6BD4E1),
  'lightest': Color(0xFF9AE3EC),
});

FluentThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return FluentThemeData(
    brightness: brightness,
    accentColor: brandAccent,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFF3F3F3),
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: isDark
          ? const Color(0xFF272727)
          : const Color(0xFFF9F9F9),
    ),
  );
}
