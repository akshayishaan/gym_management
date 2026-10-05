import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_error_state.dart';
import '../../../design/components/lato_loading.dart';
import '../../../design/spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../../gym/application/active_gym_controller.dart';
import '../../gym/data/gym_repository.dart';
import '../../gym/domain/gym.dart';

/// Gym settings — read/write the active Gym via `GET`/`PUT /gyms/:id`
/// (CLAUDE.md: "Gym settings use GET/PUT /gyms/:id, not /settings").
/// Reuses the same field set as `gym_create_screen.dart`'s "Add your gym"
/// form, pre-filled from the currently active gym instead of blank.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGymAsync = ref.watch(activeGymProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LatoColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Settings'),
      ),
      body: activeGymAsync.when(
        loading: () => const LatoLoading(),
        error: (err, _) => LatoErrorState(
          message:
              err is ApiException ? err.message : 'Could not load gym settings.',
          onRetry: () => ref.invalidate(activeGymProvider),
        ),
        data: (gym) {
          if (gym == null) {
            return const LatoErrorState(
              message: 'No active gym selected.',
            );
          }
          return _SettingsForm(gym: gym);
        },
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.gym});
  final Gym gym;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _timezoneCtrl;
  late final TextEditingController _reminderCtrl;

  bool _submitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final gym = widget.gym;
    _nameCtrl = TextEditingController(text: gym.name);
    _addressCtrl = TextEditingController(text: gym.address ?? '');
    _phoneCtrl = TextEditingController(text: gym.phone ?? '');
    _emailCtrl = TextEditingController(text: gym.email ?? '');
    _currencyCtrl = TextEditingController(text: gym.currency);
    _timezoneCtrl = TextEditingController(text: gym.timezone);
    _reminderCtrl =
        TextEditingController(text: gym.expiryReminderDays.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currencyCtrl.dispose();
    _timezoneCtrl.dispose();
    _reminderCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      final repo = ref.read(gymRepositoryProvider);
      await repo.updateGym(widget.gym.id, {
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'currency': _currencyCtrl.text.trim().toUpperCase(),
        'timezone': _timezoneCtrl.text.trim(),
        'expiryReminderDays': int.tryParse(_reminderCtrl.text.trim()) ?? 7,
      });
      // Refreshes the Dashboard's gym-picker chip, the More menu's
      // profile card subtitle, and this form's own `gym` prop everywhere
      // `activeGymProvider` is watched.
      ref.invalidate(activeGymProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym settings saved')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Could not save settings. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = ref.watch(authControllerProvider).staff;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Facility details for this location.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LatoSpacing.xxl),

              Text('Gym name', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'RepiX HQ'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Gym name is required';
                  if (value.length > 200) return 'Keep it under 200 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text('Address', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressCtrl,
                decoration:
                    const InputDecoration(hintText: '12 Demo Lane, City'),
              ),
              const SizedBox(height: 20),

              Text('Phone', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(hintText: '+1 555 123 4567'),
              ),
              const SizedBox(height: 20),

              Text('Email', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: 'hello@studio.com'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return null;
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text('Currency', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currencyCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
                decoration: const InputDecoration(
                  hintText: 'USD',
                  counterText: '',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.length != 3) return 'Use a 3-letter code';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              Text('Timezone', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _timezoneCtrl,
                decoration: const InputDecoration(
                  hintText: 'America/Los_Angeles',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Timezone is required';
                  return null;
                },
              ),
              const SizedBox(height: 8),

              Text('Expiry reminder (days)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reminderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '7'),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Enter a number';
                  if (n < 1 || n > 90) return 'Between 1 and 90';
                  return null;
                },
              ),

              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],

              const SizedBox(height: 28),
              FilledButton(
                onPressed: _submitting ? null : _onSave,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),

              if (staff != null) ...[
                const SizedBox(height: 36),
                Divider(color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('SIGNED IN AS', style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(staff.name, style: theme.textTheme.titleMedium),
                Text(staff.email, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
