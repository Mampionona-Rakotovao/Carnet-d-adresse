import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_spacing.dart';
import '../../ui/app_feedback.dart';
import 'data/platform_info.dart';

const String supportEmail = 'support@carnet-adresses.example';
const String appVersion = '0.1.0';

String buildSupportMessage() {
  return [
    'Bonjour,',
    '',
    "Je vous contacte au sujet de l'application Carnet d'adresses.",
    '',
    'Décrivez votre problème ici :',
    '',
    '',
    '---',
    'Version de l’application : $appVersion',
    'Système : ${platformDescription()}',
  ].join('\n');
}

Future<void> contactSupport(
  BuildContext context, {
  String subject = 'Aide Carnet d’adresses',
}) async {
  final message = buildSupportMessage();
  final uri = Uri(
    scheme: 'mailto',
    path: supportEmail,
    queryParameters: {
      'subject': subject,
      'body': message,
    },
  );

  var launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }

  if (launched || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Aucune messagerie disponible'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Écrivez à cette adresse depuis votre messagerie :',
            ),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              supportEmail,
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Message à envoyer :',
              style: Theme.of(dialogContext).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xxs),
            SelectableText(
              message,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: '$supportEmail\n\n$message'),
            );
            if (!dialogContext.mounted) return;
            AppSnack.success(
              dialogContext,
              'Adresse et message copiés.',
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copier'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
