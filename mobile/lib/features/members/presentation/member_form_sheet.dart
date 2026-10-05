import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/dio_client.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/spacing.dart';
import '../application/member_controller.dart';
import '../data/member_repository.dart';
import '../domain/member.dart';

/// Add/edit-member bottom sheet. Mirrors the Figma `members_directory_v2.png`
/// sheet: drag handle, title + close, PERSONAL INFO section, MEMBERSHIP
/// section, full-width lime primary CTA.
///
/// Pass [existingMember] to edit it in place (`PUT /members/:id`) — the
/// form pre-fills from it and the Plan picker becomes a read-only display
/// of the current plan, since plan changes go through the payment/renewal
/// flow (`membershipLifecycle.ts`), not a raw member update. Leave it null
/// to create a new member (`POST /members`), which is the only mode this
/// sheet supported until now.
class MemberFormSheet extends ConsumerStatefulWidget {
  const MemberFormSheet({super.key, this.existingMember});

  final Member? existingMember;

  @override
  ConsumerState<MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends ConsumerState<MemberFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String? _selectedPlanId;
  String? _selectedPlanName;

  bool _isSubmitting = false;

  bool get _isEditing => widget.existingMember != null;

  @override
  void initState() {
    super.initState();
    final member = widget.existingMember;
    if (member == null) return;
    _nameCtrl.text = member.name;
    _phoneCtrl.text = member.phone;
    _emailCtrl.text = member.email ?? '';
    _addressCtrl.text = member.address ?? '';
    _notesCtrl.text = member.notes ?? '';
    _gender = member.gender;
    _dateOfBirth = DateTime.tryParse(member.dateOfBirth ?? '');
    // Display-only in edit mode (see class doc) — not sent on submit.
    _selectedPlanId = member.planId;
    _selectedPlanName = member.planName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? now.subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, c) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: LatoColors.primary,
            onPrimary: LatoColors.bgDark,
            surface: LatoColors.surfaceDark,
            onSurface: LatoColors.textPrimaryDark,
          ),
        ),
        child: c ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: LatoColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in const ['Male', 'Female', 'Other'])
                ListTile(
                  title: Text(value),
                  onTap: () => Navigator.of(sheetCtx).pop(value),
                ),
              const SizedBox(height: LatoSpacing.md),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _gender = selected.toLowerCase();
      });
    }
  }

  Future<void> _pickPlan() async {
    final dio = ref.read(dioProvider);
    List<_PlanOption> plans = const [];
    String? errorMessage;
    try {
      final res = await dio.get<dynamic>('/plans');
      final raw = res.data;
      List? list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['items'] is List) {
        list = raw['items'] as List;
      }
      if (list != null) {
        plans = list
            .whereType<Map>()
            .map((m) => _PlanOption(
                  id: (m['_id'] ?? m['id']).toString(),
                  name: (m['name'] ?? '').toString(),
                ))
            .toList();
      }
    } on DioException catch (e) {
      errorMessage = toApiException(e).message;
    } catch (_) {
      errorMessage = 'Could not load plans';
    }

    if (!mounted) return;

    final selected = await showModalBottomSheet<_PlanOption?>(
      context: context,
      backgroundColor: LatoColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LatoRadius.xl)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('No Plan'),
                onTap: () => Navigator.of(sheetCtx).pop(null),
              ),
              if (plans.isNotEmpty)
                const Divider(height: 1),
              for (final p in plans)
                ListTile(
                  title: Text(p.name),
                  onTap: () => Navigator.of(sheetCtx).pop(p),
                ),
              if (errorMessage != null && plans.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(LatoSpacing.lg),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: LatoColors.error),
                  ),
                ),
              const SizedBox(height: LatoSpacing.md),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedPlanId = selected.id;
        _selectedPlanName = selected.name;
      });
    } else if (selected == null && _selectedPlanId != null && mounted) {
      // "No Plan" selected
      setState(() {
        _selectedPlanId = null;
        _selectedPlanName = null;
      });
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      if (_isEditing) {
        final controller = ref.read(memberUpdateControllerProvider.notifier);
        await controller.update(
          widget.existingMember!.id,
          MemberUpdateInput(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            dateOfBirth:
                _dateOfBirth == null ? null : _formatDate(_dateOfBirth!),
            gender: _gender,
            notes: _notesCtrl.text.trim(),
          ),
        );
      } else {
        final controller = ref.read(memberCreateControllerProvider.notifier);
        await controller.create(MemberCreateInput(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          dateOfBirth: _dateOfBirth == null
              ? null
              : _formatDate(_dateOfBirth!),
          gender: _gender,
          planId: _selectedPlanId,
          notes: _notesCtrl.text.trim(),
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Member updated' : 'Member added')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create member: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: LatoColors.surfaceDark,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: LatoSpacing.md),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: LatoColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LatoSpacing.xl,
                LatoSpacing.md,
                LatoSpacing.xl,
                LatoSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Member' : 'Add Member',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: LatoColors.textSecondaryDark,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  0,
                  LatoSpacing.xl,
                  LatoSpacing.xxl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('PERSONAL INFO'),
                      const SizedBox(height: LatoSpacing.md),
                      _RequiredLabel(text: 'Full Name'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Jane Doe',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      _RequiredLabel(text: 'Phone Number'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                        ],
                        decoration: const InputDecoration(
                          hintText: '+1 555 123 4567',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      const _FieldLabel('Email'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'jane@example.com',
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return null;
                          if (!value.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Date of Birth'),
                                const SizedBox(height: LatoSpacing.sm),
                                _PickerField(
                                  hint: 'Select',
                                  value: _dateOfBirth == null
                                      ? null
                                      : _formatDate(_dateOfBirth!),
                                  icon: Icons.calendar_today_outlined,
                                  onTap: _pickDate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: LatoSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Gender'),
                                const SizedBox(height: LatoSpacing.sm),
                                _PickerField(
                                  hint: 'Select',
                                  value: _gender,
                                  icon: null,
                                  onTap: _pickGender,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      const _FieldLabel('Address'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: '12 Demo Lane, City',
                        ),
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                      const _FieldLabel('Notes'),
                      const SizedBox(height: LatoSpacing.sm),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Any extra context for this member',
                        ),
                      ),
                      const SizedBox(height: LatoSpacing.xxl),
                      const _SectionLabel('MEMBERSHIP'),
                      const SizedBox(height: LatoSpacing.md),
                      _FieldLabel(_isEditing ? 'Current Plan' : 'Plan (Optional)'),
                      const SizedBox(height: LatoSpacing.sm),
                      if (_isEditing)
                        // Plan changes go through Renew/Payment (a plan
                        // purchase), not a raw member update — see
                        // `membershipLifecycle.ts`. Show it, don't offer
                        // to edit it here.
                        _PickerField(
                          hint: 'No Plan',
                          value: _selectedPlanName,
                          icon: Icons.lock_outline,
                          onTap: () {},
                        )
                      else
                        _PickerField(
                          hint: 'No Plan',
                          value: _selectedPlanName,
                          icon: null,
                          onTap: _pickPlan,
                        ),
                      const SizedBox(height: LatoSpacing.huge),
                      LatoPrimaryButton(
                        label: _isEditing ? 'SAVE CHANGES' : 'ADD MEMBER',
                        loading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: LatoSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a [DateTime] as the YYYY-MM-DD string the backend expects for
  /// the `dateOfBirth` field.
  static String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}

class _PlanOption {
  const _PlanOption({required this.id, required this.name});
  final String id;
  final String name;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.labelLarge);
  }
}

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(text, style: theme.textTheme.labelLarge),
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

/// Read-only text-field shaped picker used for date/gender/plan dropdowns.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String hint;
  final String? value;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: LatoRadius.button,
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: value == null ? hint : null,
          prefixIcon: icon == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    icon,
                    size: 18,
                    color: LatoColors.textSecondaryDark,
                  ),
                ),
        ),
        child: Row(
          children: [
            if (value != null)
              Expanded(
                child: Text(
                  value!,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            const Icon(
              Icons.expand_more,
              size: 18,
              color: LatoColors.textSecondaryDark,
            ),
          ],
        ),
      ),
    );
  }
}