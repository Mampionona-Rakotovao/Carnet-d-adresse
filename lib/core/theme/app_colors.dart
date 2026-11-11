import 'package:flutter/material.dart';

/// Palette de l'application.
///
/// Les valeurs de base sont figées ici : aucune couleur ne doit être écrite en
/// dur dans un widget. Les variantes « texte » servent aux couples qui ne
/// passent pas le contraste WCAG avec la teinte de base sur fond clair.
abstract final class AppColors {
  // --- Marque -----------------------------------------------------------
  static const Color primary = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF2196F3);
  static const Color accent = Color(0xFF00BFA6);
  static const Color darkNavy = Color(0xFF172B4D);

  // --- Sémantique -------------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
  static const Color favorite = Color(0xFFF97316);
  static const Color private = Color(0xFF8B5CF6);

  // --- Mode clair -------------------------------------------------------
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFEFF6FF);
  static const Color lightText = Color(0xFF172B4D);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // --- Mode sombre ------------------------------------------------------
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF151F32);
  static const Color darkSurfaceSecondary = Color(0xFF1E2A40);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF29364B);
  static const Color darkAccent = Color(0xFF2DD4BF);

  // --- Variantes de texte conformes (>= 4,5:1 sur fond clair) ----------
  static const Color successText = Color(0xFF15803D);
  static const Color warningText = Color(0xFFB45309);
  static const Color infoText = Color(0xFF0369A1);
  static const Color favoriteText = Color(0xFFC2410C);
  static const Color privateText = Color(0xFF6D28D9);
  static const Color errorTextLight = Color(0xFFB91C1C);
}

/// Couleurs sémantiques exposées via le thème.
///
/// `success`, `warning`, etc. sont les teintes de remplissage. Les champs
/// `*Text` sont les variantes lisibles sur une surface claire ou sombre.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.warning,
    required this.info,
    required this.favorite,
    required this.private,
    required this.successText,
    required this.warningText,
    required this.infoText,
    required this.favoriteText,
    required this.privateText,
    required this.errorText,
    required this.onSuccess,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.snackSuccess,
    required this.snackWarning,
    required this.snackError,
    required this.snackInfo,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.shadow,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color favorite;
  final Color private;

  final Color successText;
  final Color warningText;
  final Color infoText;
  final Color favoriteText;
  final Color privateText;
  final Color errorText;

  final Color onSuccess;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  final Color snackSuccess;
  final Color snackWarning;
  final Color snackError;
  final Color snackInfo;

  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color shadow;

  static const AppPalette light = AppPalette(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    favorite: AppColors.favorite,
    private: AppColors.private,
    successText: AppColors.successText,
    warningText: AppColors.warningText,
    infoText: AppColors.infoText,
    favoriteText: AppColors.favoriteText,
    privateText: AppColors.privateText,
    errorText: AppColors.errorTextLight,
    onSuccess: AppColors.darkBackground,
    accent: AppColors.accent,
    onAccent: AppColors.darkNavy,
    accentSoft: Color(0x2400BFA6),
    snackSuccess: Color(0xFF7BD88F),
    snackWarning: Color(0xFFFFCF8B),
    snackError: Color(0xFFFFB4AB),
    snackInfo: Color(0xFFF8FAFC),
    skeletonBase: Color(0xFFE9EEF6),
    skeletonHighlight: Color(0xFFF8FAFC),
    shadow: Color(0x1F172B4D),
  );

  static const AppPalette dark = AppPalette(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    favorite: AppColors.favorite,
    private: AppColors.private,
    successText: Color(0xFF22C55E),
    warningText: Color(0xFFFBBF24),
    infoText: Color(0xFF38BDF8),
    favoriteText: Color(0xFFFB923C),
    privateText: Color(0xFFA78BFA),
    errorText: Color(0xFFF87171),
    onSuccess: AppColors.darkBackground,
    accent: AppColors.darkAccent,
    onAccent: AppColors.darkBackground,
    accentSoft: Color(0x2E2DD4BF),
    snackSuccess: Color(0xFF15803D),
    snackWarning: Color(0xFFB45309),
    snackError: Color(0xFFB91C1C),
    snackInfo: Color(0xFF0369A1),
    skeletonBase: Color(0xFF1E2A40),
    skeletonHighlight: Color(0xFF29364B),
    shadow: Color(0x66000000),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? favorite,
    Color? private,
    Color? successText,
    Color? warningText,
    Color? infoText,
    Color? favoriteText,
    Color? privateText,
    Color? errorText,
    Color? onSuccess,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? snackSuccess,
    Color? snackWarning,
    Color? snackError,
    Color? snackInfo,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? shadow,
  }) =>
      AppPalette(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        favorite: favorite ?? this.favorite,
        private: private ?? this.private,
        successText: successText ?? this.successText,
        warningText: warningText ?? this.warningText,
        infoText: infoText ?? this.infoText,
        favoriteText: favoriteText ?? this.favoriteText,
        privateText: privateText ?? this.privateText,
        errorText: errorText ?? this.errorText,
        onSuccess: onSuccess ?? this.onSuccess,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        accentSoft: accentSoft ?? this.accentSoft,
        snackSuccess: snackSuccess ?? this.snackSuccess,
        snackWarning: snackWarning ?? this.snackWarning,
        snackError: snackError ?? this.snackError,
        snackInfo: snackInfo ?? this.snackInfo,
        skeletonBase: skeletonBase ?? this.skeletonBase,
        skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
        shadow: shadow ?? this.shadow,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      info: mix(info, other.info),
      favorite: mix(favorite, other.favorite),
      private: mix(private, other.private),
      successText: mix(successText, other.successText),
      warningText: mix(warningText, other.warningText),
      infoText: mix(infoText, other.infoText),
      favoriteText: mix(favoriteText, other.favoriteText),
      privateText: mix(privateText, other.privateText),
      errorText: mix(errorText, other.errorText),
      onSuccess: mix(onSuccess, other.onSuccess),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      snackSuccess: mix(snackSuccess, other.snackSuccess),
      snackWarning: mix(snackWarning, other.snackWarning),
      snackError: mix(snackError, other.snackError),
      snackInfo: mix(snackInfo, other.snackInfo),
      skeletonBase: mix(skeletonBase, other.skeletonBase),
      skeletonHighlight: mix(skeletonHighlight, other.skeletonHighlight),
      shadow: mix(shadow, other.shadow),
    );
  }
}
