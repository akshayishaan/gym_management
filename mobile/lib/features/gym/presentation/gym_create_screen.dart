import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/components/lato_card.dart';
import '../../auth/application/auth_controller.dart';
import '../data/gym_repository.dart';

/// Full-screen form to create the user's first (or next) Gym.
///
/// Hits `POST /gyms`, then notifies the auth controller so the new gym is
/// added to staff.gymIds and auto-selected, then routes to /home.
class GymCreateScreen extends ConsumerStatefulWidget {
  const GymCreateScreen({super.key});

  @override
  ConsumerState<GymCreateScreen> createState() => _GymCreateScreenState();
}

class _GymCreateScreenState extends ConsumerState<GymCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'USD');
  final _timezoneCtrl = TextEditingController(text: 'America/Los_Angeles');
  final _reminderCtrl = TextEditingController(text: '7');

  bool _submitting = false;
  String? _formError;

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

  Future<void> _onSubmit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      final repo = ref.read(gymRepositoryProvider);
      final newGym = await repo.createGym(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        currency: _currencyCtrl.text.trim().toUpperCase(),
        timezone: _timezoneCtrl.text.trim(),
        primaryColor: '#C5F23F',
        expiryReminderDays: int.tryParse(_reminderCtrl.text.trim()) ?? 7,
      );
      // Tell the auth controller a new gym exists; it will add the id to
      // staff.gymIds, persist it, and flip stage to authenticated.
      await ref.read(authControllerProvider.notifier).onGymCreated(newGym.id);
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Could not create gym. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add your gym'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/operations'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set up the location this device manages.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Name (required)
                Text('Gym name', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(hintText: 'RepiX HQ'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Gym name is required';
                    if (value.length > 200) return 'Keep it under 200 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Address
                Text('Address', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    hintText: '12 Demo Lane, City',
                  ),
                ),
                const SizedBox(height: 20),

                // Phone
                Text('Phone', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+1 555 123 4567',
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                Text('Email', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(hintText: 'hello@studio.com'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null; // optional
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Currency (3-letter code)
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

                // Timezone
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

                // Reminder days
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
                LatoPrimaryButton(
                  label: 'Create gym',
                  loading: _submitting,
                  onPressed: _submitting ? null : _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}