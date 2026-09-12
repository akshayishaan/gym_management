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

/// Account registration form. Signup does NOT establish a session — on success
/// the user is returned to [LoginScreen] to sign in.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signup(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please log in.')),
      );
      Navigator.of(context).pop();
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
        appBar: AppBar(
          title: Text(
            'Create account',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: t.foreground,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: AppScreen(
                  children: <Widget>[
                    const AppSectionLabel('New gym manager'),
                    const SizedBox(height: 12),
                    Text(
                      'Set up your account to get started.',
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
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(t, 'Name'),
                              style: TextStyle(color: t.foreground),
                              validator: (String? v) => _required(v, 'Name'),
                            ),
                            const SizedBox(height: 16),
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
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(t, 'Password'),
                              style: TextStyle(color: t.foreground),
                              validator: (String? v) =>
                                  _required(v, 'Password'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirm,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: _inputDecoration(
                                t,
                                'Confirm password',
                              ),
                              style: TextStyle(color: t.foreground),
                              validator: (String? v) {
                                if (v != null &&
                                    v.isNotEmpty &&
                                    v != _password.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _SubmitButton(
                              submitting: _submitting,
                              onPressed: _submit,
                              label: 'Create account',
                            ),
                          ],
                        ),
                      ),
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
