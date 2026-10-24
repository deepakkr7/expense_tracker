import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';

class PasswordResetScreen extends StatefulWidget {
  final String email;
  final Future<void> Function(String)? onReset;
  const PasswordResetScreen({super.key, this.email = '', this.onReset});
  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _sending = false;
  bool _sent = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final reset =
          widget.onReset ?? context.read<AuthProvider>().resetPassword;
      await reset(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not send the link. Check your connection and try again.',
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset password')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            const SizedBox(height: 24),
            TextFormField(
              controller: _email,
              enabled: !_sending,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => Validators.validateEmail(value?.trim()),
            ),
            const SizedBox(height: 24),
            if (_sent)
              const Text(
                'If an account uses this email, a reset link has been sent. Check your inbox and spam folder.',
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sending ? null : _send,
              child: Text(
                _sending
                    ? 'Sending…'
                    : _sent
                    ? 'Resend link'
                    : 'Send reset link',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
