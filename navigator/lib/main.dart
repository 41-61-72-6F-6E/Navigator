import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:navigator/pages/main_navigation_page.dart';
import 'package:navigator/pages/page_models/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Fallbacks if dynamic color isn't available
  static final _defaultLight = ColorScheme.fromSwatch(primarySwatch: Colors.blue);
  static final _defaultDark = ColorScheme.fromSwatch(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
  );

  /// Generates a proper ColorScheme with distinct surface container variants
  /// using the material_color_utilities package
  ColorScheme _generateCustomColorScheme(Color seedColor, Brightness brightness) {
    final scheme = SchemeTonalSpot(
      sourceColorHct: Hct.fromInt(seedColor.value),
      isDark: brightness == Brightness.dark,
      contrastLevel: 0.0,
    );

    return ColorScheme(
      brightness: brightness,
      primary: Color(MaterialDynamicColors.primary.getArgb(scheme)),
      onPrimary: Color(MaterialDynamicColors.onPrimary.getArgb(scheme)),
      primaryContainer: Color(MaterialDynamicColors.primaryContainer.getArgb(scheme)),
      onPrimaryContainer: Color(MaterialDynamicColors.onPrimaryContainer.getArgb(scheme)),
      secondary: Color(MaterialDynamicColors.secondary.getArgb(scheme)),
      onSecondary: Color(MaterialDynamicColors.onSecondary.getArgb(scheme)),
      secondaryContainer: Color(MaterialDynamicColors.secondaryContainer.getArgb(scheme)),
      onSecondaryContainer: Color(MaterialDynamicColors.onSecondaryContainer.getArgb(scheme)),
      tertiary: Color(MaterialDynamicColors.tertiary.getArgb(scheme)),
      onTertiary: Color(MaterialDynamicColors.onTertiary.getArgb(scheme)),
      tertiaryContainer: Color(MaterialDynamicColors.tertiaryContainer.getArgb(scheme)),
      onTertiaryContainer: Color(MaterialDynamicColors.onTertiaryContainer.getArgb(scheme)),
      error: Color(MaterialDynamicColors.error.getArgb(scheme)),
      onError: Color(MaterialDynamicColors.onError.getArgb(scheme)),
      errorContainer: Color(MaterialDynamicColors.errorContainer.getArgb(scheme)),
      onErrorContainer: Color(MaterialDynamicColors.onErrorContainer.getArgb(scheme)),
      outline: Color(MaterialDynamicColors.outline.getArgb(scheme)),
      outlineVariant: Color(MaterialDynamicColors.outlineVariant.getArgb(scheme)),
      surface: Color(MaterialDynamicColors.surface.getArgb(scheme)),
      onSurface: Color(MaterialDynamicColors.onSurface.getArgb(scheme)),
      onSurfaceVariant: Color(MaterialDynamicColors.onSurfaceVariant.getArgb(scheme)),
      inverseSurface: Color(MaterialDynamicColors.inverseSurface.getArgb(scheme)),
      onInverseSurface: Color(MaterialDynamicColors.inverseOnSurface.getArgb(scheme)),
      inversePrimary: Color(MaterialDynamicColors.inversePrimary.getArgb(scheme)),
      shadow: Color(MaterialDynamicColors.shadow.getArgb(scheme)),
      scrim: Color(MaterialDynamicColors.scrim.getArgb(scheme)),
      surfaceTint: Color(MaterialDynamicColors.primary.getArgb(scheme)),
      // The key fix: properly generated surface container variants
      surfaceContainerLowest: Color(MaterialDynamicColors.surfaceContainerLowest.getArgb(scheme)),
      surfaceContainerLow: Color(MaterialDynamicColors.surfaceContainerLow.getArgb(scheme)),
      surfaceContainer: Color(MaterialDynamicColors.surfaceContainer.getArgb(scheme)),
      surfaceContainerHigh: Color(MaterialDynamicColors.surfaceContainerHigh.getArgb(scheme)),
      surfaceContainerHighest: Color(MaterialDynamicColors.surfaceContainerHighest.getArgb(scheme)),
    );
  }

  /// Enhances existing dynamic color scheme with proper surface variants
  ColorScheme _enhanceColorScheme(ColorScheme baseScheme) {
    // Use the primary color as seed for generating proper surface variants
    final seedColor = baseScheme.primary;
    final customScheme = _generateCustomColorScheme(seedColor, baseScheme.brightness);
    
    // Keep the original colors but replace surface containers with properly generated ones
    return baseScheme.copyWith(
      surfaceContainerLowest: customScheme.surfaceContainerLowest,
      surfaceContainerLow: customScheme.surfaceContainerLow,
      surfaceContainer: customScheme.surfaceContainer,
      surfaceContainerHigh: customScheme.surfaceContainerHigh,
      surfaceContainerHighest: customScheme.surfaceContainerHighest,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Apply the fix to dynamic schemes if available, otherwise use defaults
        final lightScheme = lightDynamic != null 
            ? _enhanceColorScheme(lightDynamic)
            : _generateCustomColorScheme(Colors.blue, Brightness.light);
            
        final darkScheme = darkDynamic != null 
            ? _enhanceColorScheme(darkDynamic)
            : _generateCustomColorScheme(Colors.blue, Brightness.dark);

        final NavigationService _navService = NavigationService();

        return MaterialApp(
          title: 'Navigator',
          navigatorKey: _navService.navigatorKey,
          themeMode: ThemeMode.system,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            brightness: Brightness.light,
            textTheme: GoogleFonts.robotoTextTheme(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            brightness: Brightness.dark,
            textTheme: GoogleFonts.robotoTextTheme(),
          ),
          home: MainNavigationPage(),
        );
      },
    );
  }
}