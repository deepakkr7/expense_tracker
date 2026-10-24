import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyNotice extends StatelessWidget {
  const PrivacyNotice({super.key});
  @override
  Widget build(BuildContext context) => TextButton(
    child: const Text('Privacy & data use'),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your data in SpendWise'),
        content: const SingleChildScrollView(
          child: Text(
            'SpendWise saves your profile and financial records to your account. '
            'Camera and contacts access are optional. Selected friend names and emails are saved to your account. '
            'Receipt recognition runs on your device. Location is not tracked. '
            'Optional AI assistance is off by default; enabling it sends relevant financial details and messages for processing to generate suggestions. '
            'You can manage AI consent, email discovery and account deletion in More > Privacy & Account. '
            'Support and deletion requests: bytesforges@gmail.com.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.tryParse(
                const String.fromEnvironment('PRIVACY_POLICY_URL'),
              );
              if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'The privacy policy is currently unavailable. Contact bytesforges@gmail.com for help.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Full privacy policy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}
