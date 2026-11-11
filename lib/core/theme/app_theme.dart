import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Thèmes Material 3 de l'application.
///
/// Le `ColorScheme` est construit explicitement à partir de la palette : les
/// deux modes ne sont pas dérivés d'une graine, ce qui évite les teintes
/// imprévues et garantit les contrastes documentés dans [AppColors].
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = isLight ? _lightScheme : _darkScheme;
    final palette = isLight ? AppPalette.light : AppPalette.dark;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor:
          isLight ? AppColors.lightBackground : AppColors.darkBackground,
      // Ripple classique : discret, contenu dans la forme arrondie.
      splashFactory: InkRipple.splashFactory,
      extensions: [palette],
    );

    final textTheme = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: _appBar(scheme),
      cardTheme: _card(scheme, palette, isLight),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: _input(scheme),
      filledButtonTheme: _filled(scheme),
      outlinedButtonTheme: _outlined(scheme),
      textButtonTheme: _text(scheme),
      iconButtonTheme: _iconButton(scheme),
      floatingActionButtonTheme: _fab(scheme, palette, textTheme),
      navigationBarTheme: _navigationBar(scheme, textTheme),
      dialogTheme: _dialog(scheme, textTheme),
      snackBarTheme: _snackBar(scheme, textTheme),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetTopRadius,
        ),
      ),
      chipTheme: _chip(scheme),
      segmentedButtonTheme: _segmented(scheme),
      listTileTheme: _listTile(scheme, textTheme),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
  }

  /// Mode clair : fond bleu très pâle, surfaces blanches, texte navy.
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDCEBFF),
    onPrimaryContainer: Color(0xFF0B3A75),
    secondary: AppColors.secondary,
    onSecondary: Color(0xFF0B1220),
    secondaryContainer: Color(0xFFEAF4FF),
    onSecondaryContainer: Color(0xFF0B3A75),
    tertiary: AppColors.accent,
    onTertiary: AppColors.darkNavy,
    tertiaryContainer: Color(0xFFD6FBF5),
    onTertiaryContainer: Color(0xFF064E48),
    error: AppColors.error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightText,
    surfaceDim: AppColors.lightBackground,
    surfaceBright: AppColors.lightSurface,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: AppColors.lightSurface,
    surfaceContainer: AppColors.lightBackground,
    surfaceContainerHigh: Color(0xFFFFFFFF),
    surfaceContainerHighest: AppColors.lightSurfaceSecondary,
    onSurfaceVariant: AppColors.lightTextSecondary,
    outline: Color(0xFF94A3B8),
    outlineVariant: AppColors.lightBorder,
    shadow: AppColors.darkNavy,
    scrim: Color(0xFF000000),
    inverseSurface: AppColors.darkNavy,
    onInverseSurface: AppColors.darkText,
    inversePrimary: Color(0xFF90CAF9),
    surfaceTint: Colors.transparent,
  );

  /// Mode sombre : fond nuit, surfaces bleu ardoise, texte très clair.
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.secondary,
    onPrimary: AppColors.darkBackground,
    primaryContainer: Color(0xFF123A63),
    onPrimaryContainer: Color(0xFFD6E8FF),
    secondary: Color(0xFF38BDF8),
    onSecondary: AppColors.darkBackground,
    secondaryContainer: Color(0xFF16324F),
    onSecondaryContainer: Color(0xFFD6E8FF),
    tertiary: AppColors.darkAccent,
    onTertiary: AppColors.darkBackground,
    tertiaryContainer: Color(0xFF0F3D38),
    onTertiaryContainer: Color(0xFFA7F3EA),
    // Variante éclaircie : le rouge #DC2626 reste utilisé pour les
    // remplissages destructifs, mais pas comme texte sur fond sombre.
    error: Color(0xFFEF4444),
    onError: AppColors.darkBackground,
    errorContainer: Color(0xFF4C1D1D),
    onErrorContainer: Color(0xFFFECACA),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
    surfaceDim: AppColors.darkBackground,
    surfaceBright: AppColors.darkSurfaceSecondary,
    surfaceContainerLowest: AppColors.darkBackground,
    surfaceContainerLow: AppColors.darkSurface,
    surfaceContainer: AppColors.darkSurfaceSecondary,
    surfaceContainerHigh: AppColors.darkSurfaceSecondary,
    surfaceContainerHighest: AppColors.darkSurfaceSecondary,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: Color(0xFF64748B),
    outlineVariant: AppColors.darkBorder,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppColors.darkText,
    onInverseSurface: AppColors.darkNavy,
    inversePrimary: AppColors.primary,
    surfaceTint: Colors.transparent,
  );

  /// Hiérarchie typographique. Les corps de texte ne descendent jamais en
  /// dessous de 14 px pour rester lisibles sur un petit écran Android.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle s(
      double size,
      FontWeight weight, {
      double? height,
      double? spacing,
      Color? color,
    }) =>
        TextStyle(
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color ?? scheme.onSurface,
        );

    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
      bodySmall: s(14, FontWeight.w400,
          height: 1.4, color: scheme.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall:
          s(12, FontWeight.w600, spacing: 0.4, color: scheme.onSurfaceVariant),
    );
  }

  static AppBarTheme _appBar(ColorScheme scheme) => AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        elevation: 0,
        titleSpacing: AppSpacing.md,
        toolbarHeight: 64,
      );

  /// Cartes légèrement surélevées en mode clair, plates en mode sombre.
  static CardThemeData _card(
    ColorScheme scheme,
    AppPalette palette,
    bool isLight,
  ) =>
      CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: palette.shadow,
        elevation: isLight ? 1 : 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      );

  static InputDecorationTheme _input(ColorScheme scheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        helperStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        errorStyle: TextStyle(
          color: scheme.error,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  static ButtonStyle _baseButtonStyle(
    ColorScheme scheme,
    Color foreground,
    Color background, {
    BorderSide? side,
  }) =>
      ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.10);
          }
          return background;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          return foreground;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return foreground.withValues(alpha: 0.10);
          }
          return Colors.transparent;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: scheme.primary, width: 2);
          }
          return side;
        }),
      );

  static FilledButtonThemeData _filled(ColorScheme scheme) =>
      FilledButtonThemeData(
        style: _baseButtonStyle(scheme, scheme.onPrimary, scheme.primary),
      );

  static OutlinedButtonThemeData _outlined(ColorScheme scheme) =>
      OutlinedButtonThemeData(
        style: _baseButtonStyle(
          scheme,
          scheme.primary,
          Colors.transparent,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      );

  static TextButtonThemeData _text(ColorScheme scheme) => TextButtonThemeData(
        style: _baseButtonStyle(
          scheme,
          scheme.primary,
          Colors.transparent,
        ),
      );

  static IconButtonThemeData _iconButton(ColorScheme scheme) =>
      IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.square(48)),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: const WidgetStatePropertyAll(CircleBorder()),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurfaceVariant),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return scheme.primary.withValues(alpha: 0.10);
            }
            return Colors.transparent;
          }),
        ),
      );

  static FloatingActionButtonThemeData _fab(
    ColorScheme scheme,
    AppPalette palette,
    TextTheme textTheme,
  ) =>
      FloatingActionButtonThemeData(
        backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.94),
        foregroundColor: scheme.primary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 1,
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        shape: const CircleBorder(),
      );

  static NavigationBarThemeData _navigationBar(
    ColorScheme scheme,
    TextTheme text,
  ) =>
      NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      );

  static DialogThemeData _dialog(ColorScheme scheme, TextTheme text) =>
      DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        titleTextStyle: text.titleLarge,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
      );

  /// Les messages de retour sont flottants : ils ne décalent pas la mise en page
  /// et se lisent mieux au-dessus d'une feuille modale.
  static SnackBarThemeData _snackBar(ColorScheme scheme, TextTheme text) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        elevation: 3,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
      );

  static ChipThemeData _chip(ColorScheme scheme) => ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
        showCheckmark: false,
      );

  static SegmentedButtonThemeData _segmented(ColorScheme scheme) =>
      SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return scheme.onSurface;
          }),
        ),
      );

  static ListTileThemeData _listTile(ColorScheme scheme, TextTheme text) =>
      ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        minVerticalPadding: AppSpacing.sm,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle:
            text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
      );
}
