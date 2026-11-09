import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_feedback.dart';
import 'data/platform_info.dart';

const String supportEmail = 'mampyyonona@gmail.com';

Future<String> _appVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    if (version.isEmpty) return 'inconnue';
    final build = info.buildNumber.trim();
    return build.isEmpty ? version : '$version ($build)';
  } catch (_) {
    return 'inconnue';
  }
}

Future<String> buildSupportMessage() async {
  return [
    'Bonjour,',
    '',
    "Je vous contacte au sujet de l'application Carnet d'adresses.",
    '',
    'Décrivez votre problème ici :',
    '',
    '',
    '---',
    'Version de l’application : ${await _appVersion()}',
    'Système : ${platformDescription()}',
  ].join('\n');
}

Future<void> contactSupport(
  BuildContext context, {
  String subject = 'Aide Carnet d’adresses',
}) async {
  final message = await buildSupportMessage();
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

  await Clipboard.setData(const ClipboardData(text: supportEmail));
  if (!context.mounted) return;
  AppSnack.warning(
    context,
    'Aucune messagerie trouvée. Adresse copiée : $supportEmail',
  );
}
