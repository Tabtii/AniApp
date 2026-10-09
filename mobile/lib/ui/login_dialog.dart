import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'brand.dart';
import 'visuals.dart';

enum LoginMode { signIn, register, recovery, newPassword }

class LoginDialog extends StatefulWidget {
  const LoginDialog({
    super.key,
    required this.backend,
    this.initialMode = LoginMode.signIn,
  });
  final SupabaseClient backend;
  final LoginMode initialMode;
  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late LoginMode _mode = widget.initialMode;
  bool _busy = false, _visible = false, _sent = false;
  String? _message;
  static const callback = 'com.tabtii.aniapp://login-callback/';
  bool get _active => mounted && ModalRoute.of(context)?.isCurrent == true;
  bool get _newPassword => _mode == LoginMode.newPassword;
  bool get _register => _mode == LoginMode.register;
  bool get _recovery => _mode == LoginMode.recovery;

  // Controllers survive the route's closing animation, including focused fields.
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _change(LoginMode mode) {
    FocusScope.of(context).unfocus();
    final email = _email.text;
    _form.currentState?.reset();
    _email.text = email;
    _password.clear();
    _confirmation.clear();
    setState(() {
      _mode = mode;
      _message = null;
      _sent = false;
      _visible = false;
    });
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_recovery) {
        await widget.backend.auth
            .resetPasswordForEmail(_email.text.trim(), redirectTo: callback)
            .timeout(const Duration(seconds: 20));
        if (_active) setState(() => _sent = true);
      } else if (_newPassword) {
        await widget.backend.auth
            .updateUser(UserAttributes(password: _password.text))
            .timeout(const Duration(seconds: 20));
        TextInput.finishAutofillContext();
        if (mounted && _active) Navigator.of(context).pop(true);
      } else if (_register) {
        final result = await widget.backend.auth
            .signUp(
              email: _email.text.trim(),
              password: _password.text,
              emailRedirectTo: callback,
            )
            .timeout(const Duration(seconds: 20));
        TextInput.finishAutofillContext();
        if (mounted && _active) {
          if (result.session != null) {
            Navigator.of(context).pop(true);
          } else {
            setState(() => _sent = true);
          }
        }
      } else {
        await widget.backend.auth
            .signInWithPassword(
              email: _email.text.trim(),
              password: _password.text,
            )
            .timeout(const Duration(seconds: 20));
        TextInput.finishAutofillContext();
        if (mounted && _active) Navigator.of(context).pop(true);
      }
    } on AuthException catch (e) {
      if (_active) {
        setState(
          () => _message = switch (e.code) {
            'invalid_credentials' =>
              'E-Mail oder Passwort stimmen nicht. Bitte versuche es noch einmal.',
            'email_not_confirmed' =>
              'Bitte bestätige zuerst den Link in deiner E-Mail.',
            'over_request_rate_limit' || 'over_email_send_rate_limit' =>
              'Zu viele Versuche. Bitte warte einen Moment und versuche es erneut.',
            'email_address_not_authorized' =>
              'Der E-Mail-Versand ist noch nicht freigeschaltet. Deine lokale Watchlist bleibt nutzbar.',
            'weak_password' =>
              'Bitte wähle ein stärkeres Passwort mit mindestens 8 Zeichen.',
            'same_password' => 'Bitte wähle ein anderes Passwort als bisher.',
            _ =>
              'Das hat gerade nicht geklappt. Prüfe deine Angaben und versuche es erneut.',
          },
        );
      }
    } on TimeoutException {
      if (_active) {
        setState(
          () => _message =
              'Die Verbindung dauert zu lange. Bitte versuche es erneut.',
        );
      }
    } catch (_) {
      if (_active) {
        setState(
          () => _message =
              'Keine Verbindung. Bitte prüfe dein Internet und versuche es erneut.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = _sent
        ? 'Schau in dein Postfach.'
        : _newPassword
        ? 'Ein neuer Anfang.'
        : _recovery
        ? 'Wieder startklar.'
        : _register
        ? 'Deine Anime.\nDein Zuhause.'
        : 'Deine nächste Folge\nwartet schon.';
    final subtitle = _newPassword
        ? 'Lege jetzt dein neues Passwort fest.'
        : _recovery
        ? 'Wir helfen dir zurück zu deiner Watchlist.'
        : 'Lieblingsserien sammeln. Fortschritt speichern. Auf jedem Gerät weitermachen.';
    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 12, 4),
              child: Row(
                children: [
                  const AniAppMark(size: 34),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'aniapp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Schließen',
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 18, 16, 26),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary.withValues(alpha: .16),
                                scheme.secondary.withValues(alpha: .08),
                                scheme.surfaceContainer,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                  letterSpacing: -.8,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                              if (!_recovery && !_newPassword && !_sent) ...[
                                const SizedBox(height: 16),
                                const Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Tag(
                                      'Deine Watchlist',
                                      icon: Icons.bookmark_outline_rounded,
                                    ),
                                    Tag(
                                      'Überall dabei',
                                      icon: Icons.devices_rounded,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_sent) ...[
                                const Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 46,
                                  color: coral,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _recovery
                                      ? 'Falls ein Konto für diese E-Mail existiert, erhältst du einen Link zum Zurücksetzen. Öffne ihn auf diesem Gerät.'
                                      : 'Falls eine Bestätigung erforderlich ist, erhältst du eine E-Mail. Öffne den Link auf diesem Gerät und melde dich danach an.',
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Prüfe auch deinen Spam-Ordner.',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: () => _change(LoginMode.signIn),
                                  child: const Text('Zur Anmeldung'),
                                ),
                              ] else ...[
                                if (!_recovery && !_newPassword) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _modeButton(
                                          'Anmelden',
                                          LoginMode.signIn,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _modeButton(
                                          'Konto erstellen',
                                          LoginMode.register,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                ],
                                if (!_newPassword) ...[
                                  TextFormField(
                                    controller: _email,
                                    enabled: !_busy,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: _recovery
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    autocorrect: false,
                                    decoration: const InputDecoration(
                                      labelText: 'E-Mail',
                                      hintText: 'du@beispiel.de',
                                      prefixIcon: Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                    validator: (v) =>
                                        RegExp(
                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                        ).hasMatch(v?.trim() ?? '')
                                        ? null
                                        : 'Bitte gib eine gültige E-Mail ein.',
                                    onFieldSubmitted: (_) {
                                      if (_recovery) _submit();
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (!_recovery) ...[
                                  TextFormField(
                                    controller: _password,
                                    enabled: !_busy,
                                    obscureText: !_visible,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    autofillHints: [
                                      _register || _newPassword
                                          ? AutofillHints.newPassword
                                          : AutofillHints.password,
                                    ],
                                    textInputAction: _register || _newPassword
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    decoration: InputDecoration(
                                      labelText: _newPassword
                                          ? 'Neues Passwort'
                                          : 'Passwort',
                                      helperText: _register || _newPassword
                                          ? 'Mindestens 8 Zeichen'
                                          : null,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _visible
                                            ? 'Passwort verbergen'
                                            : 'Passwort anzeigen',
                                        onPressed: () => setState(
                                          () => _visible = !_visible,
                                        ),
                                        icon: Icon(
                                          _visible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (v) => (v?.isEmpty ?? true)
                                        ? 'Bitte gib dein Passwort ein.'
                                        : ((_register || _newPassword) &&
                                              v!.length < 8)
                                        ? 'Nutze mindestens 8 Zeichen.'
                                        : null,
                                    onFieldSubmitted: (_) {
                                      if (!_register && !_newPassword) {
                                        _submit();
                                      }
                                    },
                                  ),
                                  if (_register || _newPassword) ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _confirmation,
                                      enabled: !_busy,
                                      obscureText: !_visible,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Passwort wiederholen',
                                        prefixIcon: Icon(
                                          Icons.lock_reset_rounded,
                                        ),
                                      ),
                                      validator: (v) => v == _password.text
                                          ? null
                                          : 'Die Passwörter stimmen nicht überein.',
                                      onFieldSubmitted: (_) => _submit(),
                                    ),
                                  ],
                                  if (_mode == LoginMode.signIn)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _change(LoginMode.recovery),
                                        child: const Text(
                                          'Passwort vergessen?',
                                        ),
                                      ),
                                    ),
                                ],
                                if (_message != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _message!,
                                        style: TextStyle(color: scheme.error),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  child: _busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _newPassword
                                              ? 'Passwort speichern'
                                              : _recovery
                                              ? 'Link senden'
                                              : _register
                                              ? 'Konto erstellen'
                                              : 'Anmelden',
                                        ),
                                ),
                                if (_recovery)
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _change(LoginMode.signIn),
                                    child: const Text('Zurück zur Anmeldung'),
                                  ),
                              ],
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Text(
                                  _newPassword
                                      ? 'Später'
                                      : 'Ohne Konto weitermachen',
                                ),
                              ),
                              if (!_newPassword)
                                Text(
                                  'Ohne Konto bleibt deine Liste auf diesem Gerät.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String title, LoginMode mode) => TextButton(
    onPressed: _busy ? null : () => _change(mode),
    style: TextButton.styleFrom(
      backgroundColor: _mode == mode
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .12)
          : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: _mode == mode ? FontWeight.w800 : FontWeight.w500,
      ),
    ),
  );
}
