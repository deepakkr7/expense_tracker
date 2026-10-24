import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/privacy_preferences.dart';
import '../../../data/repositories/auth_repository.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _ai = false;
  bool _discoverable = false;
  bool _dailyReminder = false;
  bool _busy = true;
  static const policyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

  DocumentReference<Map<String, dynamic>> get _profile =>
      FirebaseFirestore.instance.doc(
        'expense_tracker/users/users/${FirebaseAuth.instance.currentUser!.uid}',
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ai = await PrivacyPreferences.aiEnabled();
      final dailyReminder = await NotificationService().dailyEnabled();
      if (mounted) {
        setState(() {
          _ai = ai;
          _dailyReminder = dailyReminder;
        });
      }
      final profile = await _profile.get();
      if (mounted) {
        setState(() {
          _discoverable = profile.data()?['discoverable'] == true;
        });
      }
    } catch (_) {
      _error('Could not load privacy settings. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _error(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setAi(bool enabled) async {
    if (enabled) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable AI assistance?'),
          content: const Text(
            'To offer suggestions, relevant financial details and your messages are sent for processing. '
            'Only enable this if you agree. Never enter bank passwords or card numbers. '
            'Suggestions can be inaccurate. You can keep tracking expenses without AI and turn it off at any time. '
            'Turning it off stops new requests but does not erase information already shared. See our privacy policy for details.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Agree & enable'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await PrivacyPreferences.setAiEnabled(enabled);
      if (mounted) setState(() => _ai = enabled);
    } catch (_) {
      _error('Could not save your choice.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDiscoverable(bool enabled) async {
    setState(() => _busy = true);
    try {
      await _profile.update({'discoverable': enabled});
      if (mounted) setState(() => _discoverable = enabled);
    } catch (_) {
      _error('Could not save your choice.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDailyReminder(bool enabled) async {
    setState(() => _busy = true);
    try {
      final saved = await NotificationService().setDailyEnabled(enabled);
      if (saved && mounted) setState(() => _dailyReminder = enabled);
      if (!saved)
        _error('Allow notifications in device settings to enable reminders.');
    } catch (_) {
      _error('Could not update reminders. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently delete your account?'),
        content: const Text(
          'This permanently deletes your SpendWise account and saved records. It cannot be undone. '
          'Copies kept by other people or information already shared are not automatically removed. '
          'For security, sign out and sign in again before deleting your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await BackendService().call('deleteAccount', {});
      // The backend has completed deletion; cleanup failures must not claim otherwise.
      try {
        await NotificationService().cancelAll();
      } catch (_) {}
      try {
        await NotificationService().setDailyEnabled(false);
      } catch (_) {
        // Account deletion already succeeded; device cleanup is best effort.
      }
      try {
        await PrivacyPreferences.clear();
      } catch (_) {}
      await AuthRepository().logout();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _error(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPolicy() async {
    final uri = Uri.tryParse(policyUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _error(
        'The privacy policy is currently unavailable. Contact bytesforges@gmail.com for help.',
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _error('Could not open the privacy policy.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy & Account')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Choose how you use AI, receive reminders and connect with friends. '
          'You can also manage your account and request help with your data.',
        ),
        SwitchListTile(
          title: const Text('Optional AI assistance'),
          subtitle: const Text(
            'Get budgeting and savings suggestions using the details you choose to share.',
          ),
          value: _ai,
          onChanged: _busy ? null : _setAi,
        ),
        SwitchListTile(
          title: const Text('Daily expense reminder'),
          subtitle: const Text(
            'An optional reminder around 10 PM on this device.',
          ),
          value: _dailyReminder,
          onChanged: _busy ? null : _setDailyReminder,
        ),
        SwitchListTile(
          title: const Text('Let friends find me by email'),
          subtitle: const Text(
            'Let people who know your email find your name and profile photo. Your financial details stay private. Turning this off does not remove existing connections.',
          ),
          value: _discoverable,
          onChanged: _busy ? null : _setDiscoverable,
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          onTap: _openPolicy,
        ),
        const ListTile(
          title: Text('Support & data requests'),
          subtitle: SelectableText('bytesforges@gmail.com'),
        ),
        if (FirebaseAuth.instance.currentUser?.emailVerified == false)
          ListTile(
            title: const Text('Verify your email'),
            subtitle: const Text(
              'After verifying, sign out and sign in again.',
            ),
            onTap: _busy
                ? null
                : () async {
                    try {
                      await FirebaseAuth.instance.currentUser!
                          .sendEmailVerification();
                      _error(
                        'Verification email sent. Please check your inbox.',
                      );
                    } catch (_) {
                      _error(
                        'Could not send verification email. Please try again later.',
                      );
                    }
                  },
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Delete account and data'),
          onTap: _busy ? null : _delete,
        ),
        if (_busy) const Center(child: CircularProgressIndicator()),
      ],
    ),
  );
}
