import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_spacing.dart';

/// Squelette animé : un balayage lumineux doux, sans dépendance externe.
///
/// Le `RepaintBoundary` isole le repeint et l'animation est coupée quand le
/// système demande de réduire les animations.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeleton,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final reduced = AppMotion.reduit(context);

    if (reduced) {
      return RepaintBoundary(child: widget.child);
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(-1.5 + value * 3, 0),
              end: Alignment(-0.5 + value * 3, 0),
              colors: [
                palette.skeletonBase,
                palette.skeletonHighlight,
                palette.skeletonBase,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppPalette.of(context).skeletonBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
  });

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: width, height: height, radius: 999);
}

/// Liste de cartes squelettes pour les adresses, favoris et résultats.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({
    super.key,
    this.count = 5,
    this.showHeader = true,
  });

  final int count;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListView(
        padding: AppSpacing.list,
        children: [
          if (showHeader) ...[
            const SkeletonShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 170, height: 24),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonLine(width: 260),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          for (var i = 0; i < count; i++) ...[
            const SkeletonShimmer(child: _AddressSkeletonCard()),
            if (i < count - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AddressSkeletonCard extends StatelessWidget {
  const _AddressSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 52, height: 52, radius: 26),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLine(width: 170, height: 16),
                  const SizedBox(height: AppSpacing.xs),
                  const SkeletonLine(width: 120),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: const [
                      SkeletonBox(width: 58, height: 20, radius: 999),
                      SizedBox(width: AppSpacing.xs),
                      SkeletonBox(width: 72, height: 20, radius: 999),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Squelette du détail d'une adresse : photo, titre, informations, carte.
class AppDetailSkeleton extends StatelessWidget {
  const AppDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListView(
        padding: AppSpacing.list,
        children: const [
          SkeletonShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 180, radius: AppRadius.md),
                SizedBox(height: AppSpacing.md),
                SkeletonLine(width: 220, height: 24),
                SizedBox(height: AppSpacing.sm),
                SkeletonLine(width: 150),
                SizedBox(height: AppSpacing.lg),
                SkeletonLine(width: 90, height: 14),
                SizedBox(height: AppSpacing.xs),
                SkeletonLine(width: 190),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(height: 220, radius: AppRadius.md),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(height: 48, radius: AppRadius.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Petites lignes squelettes pour les feuilles (liens, historique).
class AppInlineSkeleton extends StatelessWidget {
  const AppInlineSkeleton({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines; i++) ...[
            SkeletonLine(width: i.isEven ? 220 : 160),
            if (i < lines - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
