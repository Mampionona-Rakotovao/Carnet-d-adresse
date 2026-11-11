import 'package:flutter/material.dart';
import '../core/app_haptics.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_spacing.dart';
import 'pressable_scale.dart';

enum AppButtonVariant { primary, tonal, outline, text, destructive }

/// Bouton unique de l'application.
///
/// Toutes les variantes partagent la même hauteur minimale (48 dp), le même
/// rayon, la même typographie et le même comportement de chargement. Le
/// chargement conserve exactement la taille du bouton : le libellé reste
/// présent mais invisible, un petit indicateur prend sa place.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.success = false,
    this.expanded = false,
    this.compact = false,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.success = false,
    this.expanded = false,
    this.compact = false,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : variant = AppButtonVariant.primary;

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.success = false,
    this.expanded = false,
    this.compact = false,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.success = false,
    this.expanded = false,
    this.compact = false,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.success = false,
    this.expanded = false,
    this.compact = false,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : variant = AppButtonVariant.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.success = false,
    this.expanded = false,
    this.compact = false,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : variant = AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool success;
  final bool expanded;
  final bool compact;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onLongPress;

  bool get _disabled => onPressed == null && !loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final brightness = theme.brightness;

    final foreground = _foreground(scheme, palette, brightness);
    final background = _background(scheme, palette, brightness);
    final border = _border(scheme, palette, brightness);

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.lg,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.fieldRadius),
      ),
      textStyle: WidgetStatePropertyAll(
        theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (_disabled) {
          return scheme.onSurface.withValues(alpha: 0.10);
        }
        if (states.contains(WidgetState.pressed)) {
          return _pressedBackground(background, brightness);
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (_disabled) return scheme.onSurface.withValues(alpha: 0.38);
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
          return BorderSide(
            color: brightness == Brightness.light
                ? scheme.primary
                : palette.infoText,
            width: 2,
          );
        }
        return border;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (variant == AppButtonVariant.primary ||
            variant == AppButtonVariant.destructive ||
            variant == AppButtonVariant.tonal) {
          if (states.contains(WidgetState.pressed)) return 0;
          return brightness == Brightness.light ? 1 : 0;
        }
        return 0;
      }),
      shadowColor: WidgetStatePropertyAll(palette.shadow),
      animationDuration: AppMotion.normal,
    );

    final content = _content(context, foreground);

    final button = switch (variant) {
      AppButtonVariant.outline => OutlinedButton(
          onPressed: _disabled ? null : (loading ? () {} : onPressed),
          onLongPress: loading ? null : onLongPress,
          style: style,
          focusNode: focusNode,
          autofocus: autofocus,
          child: content,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: _disabled ? null : (loading ? () {} : onPressed),
          onLongPress: loading ? null : onLongPress,
          style: style,
          focusNode: focusNode,
          autofocus: autofocus,
          child: content,
        ),
      _ => FilledButton(
          onPressed: _disabled ? null : (loading ? () {} : onPressed),
          onLongPress: loading ? null : onLongPress,
          style: style,
          focusNode: focusNode,
          autofocus: autofocus,
          child: content,
        ),
    };

    Widget result = PressableScale(
      enabled: !_disabled && !loading,
      child: button,
    );

    if (expanded) {
      result = SizedBox(width: double.infinity, child: result);
    }

    final semanticLabel = tooltip ?? label;
    result = Semantics(
      button: true,
      label: semanticLabel,
      enabled: !_disabled && !loading,
      child: result,
    );

    if (tooltip != null) {
      result = Tooltip(message: tooltip!, child: result);
    }

    return result;
  }

  Widget _content(BuildContext context, Color foreground) {
    final iconData = success ? Icons.check_circle_outline : icon;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconData != null) ...[
          Icon(iconData, size: compact ? 18 : 20),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: loading ? 0 : 1,
          duration: AppMotion.rapide,
          child: row,
        ),
        if (loading)
          SizedBox(
            height: compact ? 16 : 18,
            width: compact ? 16 : 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          ),
      ],
    );
  }

  Color _foreground(
    ColorScheme scheme,
    AppPalette palette,
    Brightness brightness,
  ) {
    if (success) {
      return switch (variant) {
        AppButtonVariant.primary ||
        AppButtonVariant.destructive =>
          palette.onSuccess,
        _ => palette.successText,
      };
    }
    return switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.destructive => scheme.onError,
      AppButtonVariant.tonal =>
        brightness == Brightness.light ? AppColors.darkNavy : scheme.onSurface,
      AppButtonVariant.outline || AppButtonVariant.text => scheme.primary,
    };
  }

  Color _background(
    ColorScheme scheme,
    AppPalette palette,
    Brightness brightness,
  ) {
    if (success) {
      return switch (variant) {
        AppButtonVariant.primary ||
        AppButtonVariant.destructive =>
          palette.success,
        AppButtonVariant.tonal =>
          palette.success.withValues(alpha: brightness == Brightness.light ? 0.14 : 0.20),
        _ => Colors.transparent,
      };
    }
    return switch (variant) {
      AppButtonVariant.primary => scheme.primary,
      AppButtonVariant.destructive => AppColors.error,
      AppButtonVariant.tonal => palette.accentSoft,
      AppButtonVariant.outline || AppButtonVariant.text => Colors.transparent,
    };
  }

  BorderSide _border(
    ColorScheme scheme,
    AppPalette palette,
    Brightness brightness,
  ) {
    return switch (variant) {
      AppButtonVariant.outline => BorderSide(
          color: success
              ? palette.success.withValues(alpha: 0.55)
              : scheme.outlineVariant,
        ),
      AppButtonVariant.tonal => BorderSide(
          color: success
              ? palette.success.withValues(alpha: 0.45)
              : palette.accent.withValues(alpha: 0.35),
        ),
      AppButtonVariant.primary ||
      AppButtonVariant.destructive ||
      AppButtonVariant.text =>
        BorderSide.none,
    };
  }

  Color _pressedBackground(Color background, Brightness brightness) {
    if (background == Colors.transparent) return Colors.transparent;
    return Color.alphaBlend(
      (brightness == Brightness.light ? Colors.black : Colors.white)
          .withValues(alpha: 0.08),
      background,
    );
  }
}

/// Bouton d'icône, zone tactile de 48 dp, forme circulaire et ripple contenu.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.loading = false,
    this.success = false,
    this.selected = false,
    this.color,
    this.backgroundColor,
    this.elevated = false,
    this.size = 22,
    this.haptic = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool loading;
  final bool success;
  final bool selected;
  final Color? color;
  final Color? backgroundColor;
  final bool elevated;
  final double size;
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    final disabled = onPressed == null && !loading;
    final effectiveColor = disabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : success
            ? palette.successText
            : color ??
                (selected ? scheme.primary : scheme.onSurfaceVariant);
    final effectiveBackground = backgroundColor ??
        (selected ? scheme.primaryContainer.withValues(alpha: 0.55) : Colors.transparent);

    final iconData = success ? Icons.check_circle_outline : icon;

    Widget content = SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: effectiveColor,
                ),
              )
            : Icon(iconData, size: size, color: effectiveColor),
      ),
    );

    final button = Material(
      color: effectiveBackground,
      elevation: elevated && theme.brightness == Brightness.light ? 2 : 0,
      shadowColor: palette.shadow,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: disabled || loading
            ? null
            : () {
                if (haptic) AppHaptics.selectionClick();
                onPressed!();
              },
        child: content,
      ),
    );

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        enabled: !disabled && !loading,
        child: PressableScale(
          enabled: !disabled && !loading,
          child: button,
        ),
      ),
    );
  }
}

/// Étoile de favori : montée en échelle 1 → 1,2 → 1 et couleur Favorite.
class AppFavoriteButton extends StatefulWidget {
  const AppFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.tooltip,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<AppFavoriteButton> createState() => _AppFavoriteButtonState();
}

class _AppFavoriteButtonState extends State<AppFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

    late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.0, end: 1.2)
          .chain(CurveTween(curve: AppMotion.entree)),
      weight: 40,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.2, end: 1.0)
          .chain(CurveTween(curve: AppMotion.etat)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant AppFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFavorite && widget.isFavorite) {
      if (!AppMotion.reduit(context)) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final color =
        widget.isFavorite ? palette.favorite : scheme.onSurfaceVariant;

    return Tooltip(
      message: widget.tooltip ??
          (widget.isFavorite
              ? 'Retirer des favoris'
              : 'Ajouter aux favoris'),
      child: Semantics(
        button: true,
        label: widget.tooltip ??
            (widget.isFavorite
                ? 'Retirer des favoris'
                : 'Ajouter aux favoris'),
        child: PressableScale(
          child: IconButton(
            onPressed: () {
              AppHaptics.lightImpact();
              widget.onPressed();
            },
            icon: AnimatedBuilder(
              animation: _scale,
              builder: (context, child) =>
                  Transform.scale(scale: _scale.value, child: child),
              child: AnimatedSwitcher(
                duration: AppMotion.rapide,
                switchInCurve: AppMotion.entree,
                switchOutCurve: AppMotion.sortie,
                child: Icon(
                  widget.isFavorite ? Icons.star : Icons.star_outline,
                  key: ValueKey(widget.isFavorite),
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
