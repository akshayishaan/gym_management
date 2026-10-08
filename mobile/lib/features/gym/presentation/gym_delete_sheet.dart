import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_exception.dart';
import '../../../design/colors.dart';
import '../../../design/components/lato_card.dart';
import '../../../design/components/lato_sheet.dart';
import '../../../design/spacing.dart';
import '../data/gym_repository.dart';
import '../domain/gym.dart';
import '../domain/gym_deletion_summary.dart';

/// Counts of what deleting a gym would erase.
final gymDeletionSummaryProvider = FutureProvider.autoDispose
    .family<GymDeletionSummary, String>(
      (ref, gymId) => ref.watch(gymRepositoryProvider).deletionSummary(gymId),
    );

/// Opens the two-step delete flow. Resolves to true once the gym is gone.
Future<bool?> showGymDeleteSheet(BuildContext context, Gym gym) {
  return showLatoFormSheet<bool>(
    context: context,
    builder: (_) => GymDeleteSheet(gym: gym),
  );
}

/// Deleting a gym erases all of its data for good, so it takes two steps:
/// 1. Review exactly what will be erased and acknowledge it.
/// 2. Type the gym's name and re-enter the account password.
class GymDeleteSheet extends ConsumerStatefulWidget {
  const GymDeleteSheet({super.key, required this.gym});

  final Gym gym;

  @override
  ConsumerState<GymDeleteSheet> createState() => _GymDeleteSheetState();
}

class _GymDeleteSheetState extends ConsumerState<GymDeleteSheet> {
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  int _step = 0;
  bool _acknowledged = false;
  bool _showPassword = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _nameMatches => _nameCtrl.text.trim() == widget.gym.name;
  bool get _canDelete =>
      _nameMatches && _passwordCtrl.text.isNotEmpty && !_deleting;

  Future<void> _delete() async {
    if (!_canDelete) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(gymRepositoryProvider)
          .deleteGym(
            widget.gym.id,
            confirmName: _nameCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not delete the gym. Try again.');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(gymDeletionSummaryProvider(widget.gym.id));
    final summaryReady = summaryAsync.hasValue;
    return LatoFormSheetScaffold(
      title: _step == 0 ? 'Delete gym?' : 'Confirm deletion',
      footer: _step == 0
          ? _DangerButton(
              label: 'CONTINUE',
              onPressed: _acknowledged && summaryReady
                  ? () => setState(() => _step = 1)
                  : null,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DangerButton(
                  label: 'DELETE GYM PERMANENTLY',
                  loading: _deleting,
                  onPressed: _canDelete ? _delete : null,
                ),
                const SizedBox(height: LatoSpacing.xs),
                TextButton(
                  onPressed: _deleting
                      ? null
                      : () => setState(() {
                          _step = 0;
                          _error = null;
                        }),
                  child: const Text('Back'),
                ),
              ],
            ),
      body: _step == 0 ? _review(summaryAsync) : _confirm(),
    );
  }

  Widget _review(AsyncValue<GymDeletionSummary> summaryAsync) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This permanently deletes ${widget.gym.name} and everything in it:',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: LatoSpacing.lg),
        summaryAsync.when(
          loading: () => const _SummarySkeleton(),
          error: (e, _) => LatoCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e is ApiException
                        ? e.message
                        : 'Could not load what will be deleted.',
                    style: const TextStyle(color: LatoColors.error),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(gymDeletionSummaryProvider(widget.gym.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LatoCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: LatoSpacing.lg,
                  vertical: LatoSpacing.sm,
                ),
                child: Column(
                  children: [
                    _CountRow('Members', s.members),
                    _CountRow('Payments', s.payments),
                    _CountRow('Plans', s.plans),
                    _CountRow('Membership periods', s.memberships),
                    _CountRow('Activity entries', s.activity, last: true),
                  ],
                ),
              ),
              if (s.otherStaff > 0) ...[
                const SizedBox(height: LatoSpacing.md),
                Text(
                  s.otherStaff == 1
                      ? '1 other staff member will lose access to this gym.'
                      : '${s.otherStaff} other staff members will lose '
                            'access to this gym.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: LatoSpacing.lg),
        Text(
          'This cannot be undone.',
          style: theme.textTheme.titleSmall?.copyWith(color: LatoColors.error),
        ),
        const SizedBox(height: LatoSpacing.sm),
        InkWell(
          borderRadius: LatoRadius.button,
          onTap: () => setState(() => _acknowledged = !_acknowledged),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: LatoSizes.button),
            child: Row(
              children: [
                Checkbox(
                  key: const Key('gym-delete-ack'),
                  value: _acknowledged,
                  onChanged: (v) => setState(() => _acknowledged = v ?? false),
                ),
                Expanded(
                  child: Text(
                    'I understand all of this data will be erased for good.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirm() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type the gym name to confirm:',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: LatoSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: LatoSpacing.md,
            vertical: LatoSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: LatoColors.surfaceRaisedDark,
            borderRadius: LatoRadius.button,
            border: Border.all(color: LatoColors.borderDark),
          ),
          child: SelectableText(
            widget.gym.name,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: LatoSpacing.md),
        TextField(
          key: const Key('gym-delete-name'),
          controller: _nameCtrl,
          enabled: !_deleting,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Gym name'),
        ),
        const SizedBox(height: LatoSpacing.xl),
        Text('Enter your password', style: theme.textTheme.labelLarge),
        const SizedBox(height: LatoSpacing.sm),
        TextField(
          key: const Key('gym-delete-password'),
          controller: _passwordCtrl,
          enabled: !_deleting,
          obscureText: !_showPassword,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'Password',
            suffixIcon: IconButton(
              tooltip: _showPassword ? 'Hide password' : 'Show password',
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: LatoSpacing.md),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(color: LatoColors.error),
          ),
        ],
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow(this.label, this.count, {this.last = false});

  final String label;
  final int count;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: LatoColors.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            NumberFormat.decimalPattern('en_IN').format(count),
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LatoCard(
        child: Column(
          children: [
            for (var i = 0; i < 5; i++)
              Container(
                height: 40,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: LatoColors.surfaceRaisedDark,
                    borderRadius: BorderRadius.circular(LatoRadius.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Red, full-width primary action. Used only inside this flow.
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(LatoSizes.button),
          backgroundColor: LatoColors.error,
          foregroundColor: Colors.white,
          disabledBackgroundColor: LatoColors.error.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
