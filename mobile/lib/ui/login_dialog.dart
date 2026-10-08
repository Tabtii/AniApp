import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key, required this.backend});
  final SupabaseClient backend;

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  // showDialog's future completes before its closing animation. The fields
  // must own their controllers until the dialog is actually unmounted.
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _active => mounted && ModalRoute.of(context)?.isCurrent == true;

  Future<void> _submit({required bool register}) async {
    if (_busy) return;
    if (!_email.text.contains('@') ||
        _password.text.isEmpty ||
        (register && _password.text.length < 8)) {
      setState(
        () => _message = register
            ? 'Bitte nutze eine gültige E-Mail und mindestens 8 Zeichen im Passwort.'
            : 'Bitte gib deine E-Mail und dein Passwort ein.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (register) {
        await widget.backend.auth
            .signUp(
              email: _email.text.trim(),
              password: _password.text,
              emailRedirectTo: 'com.tabtii.aniapp://login-callback/',
            )
            .timeout(const Duration(seconds: 20));
        if (_active) {
          setState(
            () => _message =
                'Bitte bestätige deine E-Mail. Danach kannst du dich anmelden.',
          );
        }
      } else {
        await widget.backend.auth
            .signInWithPassword(
              email: _email.text.trim(),
              password: _password.text,
            )
            .timeout(const Duration(seconds: 20));
        // A late response must not pop the underlying screen after dismissal.
        if (mounted && _active) Navigator.of(context).pop();
      }
    } catch (_) {
      if (_active) {
        setState(
          () => _message = register
              ? 'Registrierung nicht möglich. Bitte prüfe deine Angaben oder versuche es später.'
              : 'Anmeldung nicht möglich. Prüfe E-Mail, Passwort und E-Mail-Bestätigung.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Deine Watchlist überall'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'E-Mail'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Passwort'),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
        child: const Text('Abbrechen'),
      ),
      TextButton(
        onPressed: _busy ? null : () => _submit(register: true),
        child: const Text('Registrieren'),
      ),
      FilledButton(
        onPressed: _busy ? null : () => _submit(register: false),
        child: const Text('Anmelden'),
      ),
    ],
  );
}
