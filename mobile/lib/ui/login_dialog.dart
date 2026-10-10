import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/strings.dart';
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
            'invalid_credentials' => context.l10n.invalidCredentials,
            'email_not_confirmed' => context.l10n.confirmEmail,
            'over_request_rate_limit' ||
            'over_email_send_rate_limit' => context.l10n.authRateLimit,
            'email_address_not_authorized' => context.l10n.emailNotEnabled,
            'weak_password' => context.l10n.weakPassword,
            'same_password' => context.l10n.samePassword,
            _ => context.l10n.authError,
          },
        );
      }
    } on TimeoutException {
      if (_active) {
        setState(() => _message = context.l10n.authTimeout);
      }
    } catch (_) {
      if (_active) {
        setState(() => _message = context.l10n.authOffline);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = _sent
        ? context.l10n.checkInbox
        : _newPassword
        ? context.l10n.freshStart
        : _recovery
        ? context.l10n.backReady
        : _register
        ? context.l10n.loginRegisterTitle
        : context.l10n.loginTitle;
    final subtitle = _newPassword
        ? context.l10n.setNewPassword
        : _recovery
        ? context.l10n.recoverySubtitle
        : context.l10n.loginSubtitle;
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
                    tooltip: context.l10n.close,
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Tag(
                                      context.l10n.yourWatchlist,
                                      icon: Icons.bookmark_outline_rounded,
                                    ),
                                    Tag(
                                      context.l10n.allDevices,
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
                                      ? context.l10n.recoverySent
                                      : context.l10n.confirmationSent,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  context.l10n.checkSpam,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: () => _change(LoginMode.signIn),
                                  child: Text(context.l10n.toSignIn),
                                ),
                              ] else ...[
                                if (!_recovery && !_newPassword) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _modeButton(
                                          context.l10n.signIn,
                                          LoginMode.signIn,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: _modeButton(
                                          context.l10n.createAccount,
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
                                    decoration: InputDecoration(
                                      labelText: context.l10n.email,
                                      hintText: context.l10n.emailHint,
                                      prefixIcon: const Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                    validator: (v) =>
                                        RegExp(
                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                        ).hasMatch(v?.trim() ?? '')
                                        ? null
                                        : context.l10n.invalidEmail,
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
                                          ? context.l10n.newPassword
                                          : context.l10n.password,
                                      helperText: _register || _newPassword
                                          ? context.l10n.minPassword
                                          : null,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _visible
                                            ? context.l10n.hidePassword
                                            : context.l10n.showPassword,
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
                                        ? context.l10n.enterPassword
                                        : ((_register || _newPassword) &&
                                              v!.length < 8)
                                        ? context.l10n.passwordLength
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
                                      decoration: InputDecoration(
                                        labelText: context.l10n.repeatPassword,
                                        prefixIcon: const Icon(
                                          Icons.lock_reset_rounded,
                                        ),
                                      ),
                                      validator: (v) => v == _password.text
                                          ? null
                                          : context.l10n.passwordMismatch,
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
                                        child: Text(
                                          context.l10n.forgotPassword,
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
                                              ? context.l10n.savePassword
                                              : _recovery
                                              ? context.l10n.sendLink
                                              : _register
                                              ? context.l10n.createAccount
                                              : context.l10n.signIn,
                                        ),
                                ),
                                if (_recovery)
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _change(LoginMode.signIn),
                                    child: Text(context.l10n.backSignIn),
                                  ),
                              ],
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Text(
                                  _newPassword
                                      ? context.l10n.later
                                      : context.l10n.continueGuest,
                                ),
                              ),
                              if (!_newPassword)
                                Text(
                                  context.l10n.guestHint,
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
