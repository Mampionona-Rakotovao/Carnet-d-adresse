import 'package:flutter/material.dart';

import '../../../core/onboarding.dart';
import '../../../core/theme/app_spacing.dart';

Future<void> showOnboardingTour(
  BuildContext context, {
  bool markSeen = true,
}) async {
  final completed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _OnboardingDialog(),
  );

  if (completed == true && markSeen) {
    await OnboardingStorage.markSeen();
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    icon: Icons.menu_book_outlined,
    title: 'Bienvenue dans votre carnet',
    description:
        'Enregistrez les lieux importants et retrouvez-les facilement, même sans connaître leur adresse exacte.',
  ),
  _OnboardingPage(
    icon: Icons.add_location_alt_outlined,
    title: 'Décrivez le lieu avec vos repères',
    description:
        'Ajoutez une photo, une position GPS et les points visibles autour du lieu : un arbre, une boutique, un portail…',
  ),
  _OnboardingPage(
    icon: Icons.route_outlined,
    title: 'Expliquez le chemin',
    description:
        'Ajoutez des étapes simples pour expliquer comment arriver, puis calculez un itinéraire ou lancez le guidage.',
  ),
  _OnboardingPage(
    icon: Icons.share_outlined,
    title: 'Partagez et retrouvez vos adresses',
    description:
        'Envoyez un lien temporaire à un proche, ajoutez vos lieux aux favoris et utilisez la recherche pour les retrouver.',
  ),
  _OnboardingPage(
    icon: Icons.help_outline,
    title: 'Besoin d’aide ?',
    description:
        'Le menu ⋮ de l’accueil donne accès au centre d’aide, à la recherche et au support. Vous pouvez revoir cette visite à tout moment.',
  ),
];

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final PageController _controller = PageController();
  var _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _pages.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _previous() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 600;
    final pageHeight = screenHeight < 480
        ? 160.0
        : compact
            ? 220.0
            : 330.0;
    final isLast = _index == _pages.length - 1;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Passer'),
                ),
              ),
              SizedBox(
                height: pageHeight,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              page.icon,
                              size: 42,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxs,
                      ),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (_index > 0)
                    TextButton(
                      onPressed: _previous,
                      child: const Text('Précédent'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(isLast ? 'Terminer' : 'Suivant'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
