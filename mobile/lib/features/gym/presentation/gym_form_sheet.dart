import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/spacing.dart';
import '../../auth/application/auth_controller.dart';
import '../application/active_gym_controller.dart';
import '../data/gym_repository.dart';
import '../domain/gym.dart';
import 'gym_delete_sheet.dart';
import 'gym_switcher_sheet.dart';

/// What [GymFormSheet] closed with.
enum GymFormResult { saved, created, deleted }

/// Add/edit gym bottom sheet. Pass [existing] to edit that gym: fields
/// pre-fill, Save stays disabled until something changes, and a Danger zone
/// at the bottom starts the delete flow. Without it the sheet creates a gym
/// and switches to it.
class GymFormSheet extends ConsumerStatefulWidget {
  const GymFormSheet({super.key, this.existing});

  final Gym? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<GymFormSheet> createState() => _GymFormSheetState();
}

class _GymFormSheetState extends ConsumerState<GymFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _reminderCtrl = TextEditingController(text: '7');

  String _currency = 'INR';
  String _timezone = 'Asia/Kolkata';
  bool _submitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    if (g != null) {
      _nameCtrl.text = g.name;
      _addressCtrl.text = g.address ?? '';
      _phoneCtrl.text = g.phone ?? '';
      _emailCtrl.text = g.email ?? '';
      _reminderCtrl.text = g.expiryReminderDays.toString();
      _currency = g.currency;
      _timezone = g.timezone;
    }
    for (final c in [
      _nameCtrl,
      _addressCtrl,
      _phoneCtrl,
      _emailCtrl,
      _reminderCtrl,
    ]) {
      c.addListener(_onEdited);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _reminderCtrl.dispose();
    super.dispose();
  }

  void _onEdited() => setState(() {});

  /// Create mode is always submittable; edit mode only once a value differs
  /// from what was loaded.
  bool get _changed {
    final g = widget.existing;
    if (g == null) return true;
    return _nameCtrl.text.trim() != g.name ||
        _addressCtrl.text.trim() != (g.address ?? '') ||
        _phoneCtrl.text.trim() != (g.phone ?? '') ||
        _emailCtrl.text.trim() != (g.email ?? '') ||
        _currency != g.currency ||
        _timezone != g.timezone ||
        _reminderCtrl.text.trim() != g.expiryReminderDays.toString();
  }

  Future<void> _pickCurrency() async {
    final picked = await _pickFromList(
      title: 'Select Currency',
      options: _currencyOptions(_currency),
      selected: _currency,
    );
    if (picked != null) setState(() => _currency = picked);
  }

  Future<void> _pickTimezone() async {
    final picked = await _pickFromList(
      title: 'Select Timezone',
      options: _timezoneOptions(_timezone),
      selected: _timezone,
      searchable: true,
    );
    if (picked != null) setState(() => _timezone = picked);
  }

  Future<String?> _pickFromList({
    required String title,
    required List<_Option> options,
    required String selected,
    bool searchable = false,
  }) {
    return showLatoSheet<String>(
      context: context,
      builder: (_) => _OptionSheet(
        title: title,
        options: options,
        selected: selected,
        searchable: searchable,
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
      _formError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(gymRepositoryProvider);
      final name = _nameCtrl.text.trim();
      final reminder = int.parse(_reminderCtrl.text.trim());
      if (widget.isEdit) {
        await repo.updateGym(widget.existing!.id, {
          'name': name,
          'address': _addressCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'currency': _currency,
          'timezone': _timezone,
          'expiryReminderDays': reminder,
        });
        ref.invalidate(userGymsProvider);
        ref.invalidate(activeGymProvider);
        navigator.pop(GymFormResult.saved);
        messenger.showSnackBar(const SnackBar(content: Text('Gym updated')));
      } else {
        // Capture the notifiers before popping: once the sheet is popped this
        // State is disposed and `ref` can no longer be used.
        final authNotifier = ref.read(authControllerProvider.notifier);
        final selectedNotifier = ref.read(selectedGymIdProvider.notifier);
        final gym = await repo.createGym(
          name: name,
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          currency: _currency,
          timezone: _timezone,
          expiryReminderDays: reminder,
        );
        ref.invalidate(userGymsProvider);
        // Close the sheet BEFORE flipping the auth stage. Creating the first
        // gym flips the stage needsGymCreation -> authenticated, which makes
        // the router redirect /gym/new -> /home. Doing that while this modal
        // is still open wedges the navigator on a black screen, so the sheet
        // must be gone first. (From My Gyms the stage is already authenticated,
        // so the order is harmless there.)
        navigator.pop(GymFormResult.created);
        // Adds the id to the staff's gyms and makes the new gym current.
        await authNotifier.onGymCreated(gym.id);
        await selectedNotifier.select(gym.id);
        messenger.showSnackBar(
          SnackBar(content: Text('Gym created. Switched to ${gym.name}')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _formError = 'Could not save the gym. Try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _startDelete() async {
    final deleted = await showGymDeleteSheet(context, widget.existing!);
    if (deleted == true && mounted) {
      Navigator.of(context).pop(GymFormResult.deleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = _changed && !_submitting;
    return LatoFormSheetScaffold(
      title: widget.isEdit ? 'Edit Gym' : 'New Gym',
      footer: LatoPrimaryButton(
        label: widget.isEdit ? 'SAVE CHANGES' : 'CREATE GYM',
        loading: _submitting,
        onPressed: canSubmit ? _submit : null,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('GYM DETAILS'),
            const SizedBox(height: LatoSpacing.md),
            const _RequiredLabel('Name'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'e.g., Muscle Gym'),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Name is required';
                if (value.length > 200) return 'Keep it under 200 characters';
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.lg),
            const _FieldLabel('Address'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _addressCtrl,
              minLines: 2,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Street, area, city',
                counterText: '',
              ),
            ),
            const SizedBox(height: LatoSpacing.lg),
            const _FieldLabel('Phone'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 20,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: '+91 98765 43210',
                counterText: '',
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                final digits = value.replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) return 'Enter at least 10 digits';
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.lg),
            const _FieldLabel('Email'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'name@example.com'),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.xxl),
            const _SectionLabel('REGIONAL'),
            const SizedBox(height: LatoSpacing.md),
            const _RequiredLabel('Currency'),
            const SizedBox(height: LatoSpacing.sm),
            _PickerField(
              key: const Key('gym-currency-field'),
              value: _currencyLabel(_currency),
              onTap: _pickCurrency,
            ),
            const SizedBox(height: LatoSpacing.xs),
            Text(
              'Amounts in the app are shown in ₹ for now.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: LatoSpacing.lg),
            const _RequiredLabel('Timezone'),
            const SizedBox(height: LatoSpacing.sm),
            _PickerField(
              key: const Key('gym-timezone-field'),
              value: _timezone,
              onTap: _pickTimezone,
            ),
            const SizedBox(height: LatoSpacing.xs),
            Text(
              'Sets the day membership dates and activity roll over.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: LatoSpacing.xxl),
            const _SectionLabel('REMINDERS'),
            const SizedBox(height: LatoSpacing.md),
            const _RequiredLabel('Expiry reminder (days)'),
            const SizedBox(height: LatoSpacing.sm),
            TextFormField(
              controller: _reminderCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '7'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null) return 'Enter a number';
                if (n < 1 || n > 90) return 'Between 1 and 90';
                return null;
              },
            ),
            const SizedBox(height: LatoSpacing.xs),
            Text(
              'Members are flagged this many days before their plan ends.',
              style: theme.textTheme.bodySmall,
            ),
            if (_formError != null) ...[
              const SizedBox(height: LatoSpacing.lg),
              Text(
                _formError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: LatoColors.error,
                ),
              ),
            ],
            if (widget.isEdit) ...[
              const SizedBox(height: LatoSpacing.xxl),
              const _SectionLabel('DANGER ZONE'),
              const SizedBox(height: LatoSpacing.md),
              _DangerCard(onDelete: _startDelete),
            ],
          ],
        ),
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LatoCard(
      borderColor: LatoColors.error.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delete this gym', style: theme.textTheme.titleMedium),
          const SizedBox(height: LatoSpacing.xs),
          Text(
            'Permanently erases its members, payments, plans and activity. '
            'This cannot be undone.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: LatoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete gym...'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(LatoSizes.button),
                foregroundColor: LatoColors.error,
                side: const BorderSide(color: LatoColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Currency / timezone options
// ---------------------------------------------------------------------------

class _Option {
  const _Option(this.value, this.label);
  final String value;
  final String label;
}

const _currencies = <(String, String)>[
  ('INR', 'Indian Rupee'),
  ('USD', 'US Dollar'),
  ('EUR', 'Euro'),
  ('GBP', 'British Pound'),
  ('AED', 'UAE Dirham'),
  ('SAR', 'Saudi Riyal'),
  ('SGD', 'Singapore Dollar'),
  ('AUD', 'Australian Dollar'),
  ('CAD', 'Canadian Dollar'),
  ('NZD', 'New Zealand Dollar'),
  ('JPY', 'Japanese Yen'),
  ('CNY', 'Chinese Yuan'),
  ('PKR', 'Pakistani Rupee'),
  ('BDT', 'Bangladeshi Taka'),
  ('LKR', 'Sri Lankan Rupee'),
  ('NPR', 'Nepalese Rupee'),
  ('ZAR', 'South African Rand'),
];

const _timezones = <String>[
  'Asia/Kolkata',
  'Asia/Dubai',
  'Asia/Riyadh',
  'Asia/Karachi',
  'Asia/Dhaka',
  'Asia/Colombo',
  'Asia/Kathmandu',
  'Asia/Bangkok',
  'Asia/Jakarta',
  'Asia/Singapore',
  'Asia/Kuala_Lumpur',
  'Asia/Manila',
  'Asia/Hong_Kong',
  'Asia/Shanghai',
  'Asia/Seoul',
  'Asia/Tokyo',
  'Australia/Perth',
  'Australia/Sydney',
  'Pacific/Auckland',
  'Europe/London',
  'Europe/Dublin',
  'Europe/Paris',
  'Europe/Berlin',
  'Europe/Madrid',
  'Europe/Rome',
  'Europe/Moscow',
  'Africa/Cairo',
  'Africa/Lagos',
  'Africa/Nairobi',
  'Africa/Johannesburg',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Toronto',
  'America/Mexico_City',
  'America/Sao_Paulo',
  'America/Argentina/Buenos_Aires',
  'UTC',
];

String _currencyLabel(String code) {
  for (final (c, name) in _currencies) {
    if (c == code) return '$c - $name';
  }
  return code;
}

List<_Option> _currencyOptions(String current) => [
  for (final (c, name) in _currencies) _Option(c, '$c - $name'),
  if (!_currencies.any((e) => e.$1 == current)) _Option(current, current),
];

List<_Option> _timezoneOptions(String current) => [
  for (final z in _timezones) _Option(z, z),
  if (!_timezones.contains(current)) _Option(current, current),
];

/// Pick-list sheet with an optional search box. Pops with the chosen value.
class _OptionSheet extends StatefulWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
  });

  final String title;
  final List<_Option> options;
  final String selected;
  final bool searchable;

  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? widget.options
        : [
            for (final o in widget.options)
              if (o.label.toLowerCase().contains(q)) o,
          ];
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LatoSheetTitle(widget.title),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  0,
                  LatoSpacing.xl,
                  LatoSpacing.sm,
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
              ),
            Flexible(
              child: shown.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(LatoSpacing.xl),
                      child: Text('No matches'),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final o in shown)
                          ListTile(
                            title: Text(o.label),
                            trailing: o.value == widget.selected
                                ? const Icon(
                                    Icons.check,
                                    color: LatoColors.primary,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(o.value),
                          ),
                      ],
                    ),
            ),
            SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local form pieces (same shape as plan_form_sheet / member_form_sheet)
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            color: LatoColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({super.key, required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: LatoRadius.button,
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          suffixIcon: Icon(
            Icons.expand_more,
            size: 18,
            color: LatoColors.textSecondaryDark,
          ),
        ),
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
