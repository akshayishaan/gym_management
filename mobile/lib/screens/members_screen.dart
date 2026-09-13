import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_providers.dart';
import '../core/navigation.dart';
import '../core/settings/gym_settings_controller.dart';
import '../data/api_helpers.dart';
import '../data/filters.dart';
import '../data/member_providers.dart';
import '../data/query_scope.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_screen.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_surface.dart';
import '../widgets/bottom_sheet_form.dart';
import '../widgets/fab.dart';
import '../widgets/hide_scrollbar.dart';
import '../widgets/member_card.dart';
import '../widgets/member_form_sheet.dart';
import '../widgets/payment_form_sheet.dart';
import 'member_detail_screen.dart';

/// The Members tab: debounced search, status filter (shared via
/// [membersStatusProvider] so the Today dashboard can deep-link), and the
/// member card list with add/edit/delete/renew actions.
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _deferredSearch = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _deferredSearch = value.trim());
    });
  }

  Future<void> _deleteMember(MemberResponse member) async {
    final dio = ref.read(dioProvider);
    try {
      await deleteJson<SuccessResponse>(
        dio,
        '/members/${member.id}',
        fromJson: SuccessResponse.fromJson,
      );
      if (mounted) showAppSnackBar(context, 'Member deleted');
      invalidateGymScopeFromWidget(ref);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to delete member', isError: true);
      }
    }
  }

  void _openFilterSheet() {
    final String? current = ref.read(membersStatusProvider);
    BottomSheetForm.show<void>(
      context,
      title: 'Filter Members',
      body: <Widget>[
        for (final _StatusOption option in _statusOptions)
          _FilterRow(
            option: option,
            selected: option.value == current,
            onTap: () {
              ref.read(membersStatusProvider.notifier).state = option.value;
              Navigator.of(context).pop();
            },
          ),
      ],
      footer: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    );
  }

  void _openDetail(MemberResponse member) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberDetailScreen(
          memberId: member.id,
          initialMember: member,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final String currency = ref.watch(gymSettingsControllerProvider).currency;
    final String? status = ref.watch(membersStatusProvider);

    final AsyncValue<MemberListResponse> membersAsync = ref.watch(
      membersProvider(
        MemberFilters(
          search: _deferredSearch.isEmpty ? null : _deferredSearch,
          status: status,
          page: 1,
          limit: 100,
        ),
      ),
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: HideScrollBar(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: <Widget>[
                AppScreen(
                  children: <Widget>[
                    _SearchBar(
                      controller: _searchController,
                      active: status != null,
                      onChanged: _onSearchChanged,
                      onFilter: _openFilterSheet,
                    ),
                    const SizedBox(height: 20),
                    _buildHeader(t, membersAsync),
                    const SizedBox(height: 12),
                    ...membersAsync.when(
                      data: (MemberListResponse data) =>
                          _buildList(t, currency, data),
                      loading: () => _buildLoading(t),
                      error: (Object e, StackTrace st) => _buildError(t),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 16,
          child: AppFab(
            onPressed: () => MemberFormSheet.show(context, currency: currency),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeTokens t, AsyncValue<MemberListResponse> async) {
    final num total = async.value?.total ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const AppSectionLabel('Your community'),
          Text(
            '$total member${total == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: t.muted.foreground,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildList(
    ThemeTokens t,
    String currency,
    MemberListResponse data,
  ) {
    if (data.members.isEmpty) {
      return <Widget>[
        AppSurface(
          borderRadius: BorderRadius.circular(32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: withOpacity(t.primary.value, 0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(Icons.group, size: 28, color: t.primary.value),
              ),
              const SizedBox(height: 16),
              Text(
                'No members found',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: t.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different name or membership status.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: t.muted.foreground),
              ),
            ],
          ),
        ),
      ];
    }

    return <Widget>[
      for (final MemberResponse member in data.members)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MemberCard(
            member: member,
            currency: currency,
            onTap: () => _openDetail(member),
            onRenew: () => PaymentFormSheet.show(
              context,
              prefillMemberId: member.id,
              prefillMemberName: member.name,
              currency: currency,
            ),
            onEdit: () => MemberFormSheet.show(
              context,
              initialData: member,
              currency: currency,
            ),
            onDelete: () => _deleteMember(member),
          ),
        ),
    ];
  }

  List<Widget> _buildLoading(ThemeTokens t) {
    return <Widget>[
      for (int i = 0; i < 6; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 112,
            decoration: BoxDecoration(
              color: withOpacity(t.foreground, 0.08),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildError(ThemeTokens t) {
    return <Widget>[
      AppSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(Icons.error_outline, size: 32, color: t.destructive.value),
            const SizedBox(height: 12),
            Text(
              'Could not load members',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: t.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please try again.',
              style: TextStyle(fontSize: 13, color: t.muted.foreground),
            ),
          ],
        ),
      ),
    ];
  }
}

// -- filter options ----------------------------------------------------------

class _StatusOption {
  const _StatusOption(this.value, this.label);

  final String? value;
  final String label;
}

const List<_StatusOption> _statusOptions = <_StatusOption>[
  _StatusOption(null, 'All Members'),
  _StatusOption('active', 'Active'),
  _StatusOption('expiring', 'Expiring Soon'),
  _StatusOption('expiring30', 'Expiring in 30 Days'),
  _StatusOption('expired', 'Expired'),
  _StatusOption('due', 'Payment Due'),
];

// -- search bar --------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.active,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final bool active;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return AppSurface(
      borderRadius: BorderRadius.circular(t.radius * 1.33),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          Icon(Icons.search, size: 20, color: t.muted.foreground),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search members…',
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: t.muted.foreground),
              ),
              style: TextStyle(color: t.foreground, fontSize: 14),
            ),
          ),
          IconButton(
            onPressed: onFilter,
            icon: Icon(
              Icons.tune,
              size: 20,
              color: active ? t.primary.foreground : t.foreground,
            ),
            style: IconButton.styleFrom(
              backgroundColor: active ? t.primary.value : t.muted.value,
            ),
          ),
        ],
      ),
    );
  }
}

// -- filter row --------------------------------------------------------------

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _StatusOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;
    final Color foreground = selected ? t.primary.value : t.foreground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? withOpacity(t.primary.value, 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
            if (selected) Icon(Icons.check, size: 18, color: t.primary.value),
          ],
        ),
      ),
    );
  }
}
