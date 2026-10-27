import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../update/update_service.dart';

/// Neutral age bands: no exact date of birth, rewards, or suggested selection.
enum AgeGroup { under16, teen, adult }

class AgeGate extends StatefulWidget {
  const AgeGate({required this.child, required this.onSelected, super.key});
  final Widget child;
  final void Function(AgeGroup) onSelected;
  @override
  State<AgeGate> createState() => _AgeGateState();
}

class _AgeGateState extends State<AgeGate> {
  bool loading = true;
  bool selected = false;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('age_group');
      final matches = AgeGroup.values.where((group) => group.name == saved);
      if (mounted && matches.isNotEmpty) {
        selected = true;
        widget.onSelected(matches.first);
      }
    } catch (_) {
      /* Ask without requiring storage. */
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _select(AgeGroup group) async {
    if (saving) return;
    saving = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('age_group', group.name);
    } catch (_) {
      /* The current selection remains valid for this session. */
    }
    if (!mounted) return;
    widget.onSelected(group);
    setState(() {
      selected = true;
      saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (selected) return widget.child;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your age group',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose your age group to set up Ghost Runner. This choice is stored on this device.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                for (final entry in const {
                  AgeGroup.under16: 'Under 16',
                  AgeGroup.teen: '16–17',
                  AgeGroup.adult: '18 or older',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(220, 48),
                      ),
                      onPressed: saving ? null : () => _select(entry.key),
                      child: Text(entry.value),
                    ),
                  ),
                TextButton(
                  onPressed: () async {
                    try {
                      await launchUrl(
                        Uri.parse(privacyPolicyUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {
                      /* External browser unavailable. */
                    }
                  },
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
