import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/auth/auth_controller.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_canvas.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';
import 'signup_screen.dart';

/// Email + password sign-in form. On success the authenticated `AuthState`
/// causes the root [AuthGate] to swap in the shell; no manual navigation.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );
      // Success is observed by the AuthGate via `authControllerProvider`.
    } on ApiException catch (e) {
      _showError(e.userMessage);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: AppScreen(
                  children: <Widget>[
                    const AppSectionLabel('Gym Manager'),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.045 * 32,
                        height: 1,
                        color: t.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your credentials to manage your gyms.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: t.muted.foreground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppSurface(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(t, 'Email'),
                              style: TextStyle(color: t.foreground),
                              validator: (String? v) => _required(v, 'Email'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: _inputDecoration(t, 'Password'),
                              style: TextStyle(color: t.foreground),
                              validator: (String? v) =>
                                  _required(v, 'Password'),
                            ),
                            const SizedBox(height: 24),
                            _SubmitButton(
                              submitting: _submitting,
                              onPressed: _submit,
                              label: 'Sign in',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'No account?',
                          style: TextStyle(
                            fontSize: 13,
                            color: t.muted.foreground,
                          ),
                        ),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  ),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared primary submit button with a busy spinner state.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.submitting,
    required this.onPressed,
    required this.label,
  });

  final bool submitting;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return FilledButton(
      onPressed: submitting ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: t.primary.value,
        foregroundColor: t.primary.foreground,
        disabledBackgroundColor: withOpacity(t.primary.value, 0.5),
        disabledForegroundColor: t.primary.foreground,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radius),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: submitting
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.primary.foreground,
              ),
            )
          : Text(label),
    );
  }
}

InputDecoration _inputDecoration(ThemeTokens t, String label) {
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(t.radius),
    borderSide: BorderSide(color: t.border),
  );
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: t.popover.value,
    labelStyle: TextStyle(color: t.muted.foreground),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radius),
      borderSide: BorderSide(color: t.ring, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radius),
      borderSide: BorderSide(color: t.destructive.value),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radius),
      borderSide: BorderSide(color: t.destructive.value, width: 2),
    ),
  );
}

String? _required(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return '$label is required';
  }
  return null;
}
