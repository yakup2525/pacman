import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'update_service.dart';

class UpdateGate extends StatelessWidget {
  const UpdateGate({required this.service, required this.child, super.key});
  final UpdateService service;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: service,
    builder: (context, _) {
      if (service.checking) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (!service.mandatory) return child;
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.system_update, size: 48),
                    const SizedBox(height: 24),
                    Text(
                      'Update Ghost Runner',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This version is no longer supported. Update from Google Play to continue.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () async {
                        var opened = false;
                        try {
                          opened = await launchUrl(
                            Uri.parse(playStoreUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (_) {
                          /* Show retry below. */
                        }
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Google Play could not open. Check your connection and try again.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Update on Google Play'),
                    ),
                    TextButton(
                      onPressed: service.check,
                      child: const Text('Check again'),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(privacyPolicyUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
