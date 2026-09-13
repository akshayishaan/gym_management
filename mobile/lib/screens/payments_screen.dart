import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../core/api/api_exception.dart';
import '../core/api/client_request_id.dart';
import '../core/api/dio_providers.dart';
import '../core/settings/gym_settings_controller.dart';
import '../data/api_helpers.dart';
import '../data/filters.dart';
import '../data/formatters.dart';
import '../data/payment_providers.dart';
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
import '../widgets/payment_card.dart';
import '../widgets/payment_form_sheet.dart';
import 'invoice_screen.dart';

/// The Payments tab: collected hero, month/year filter, the payment card list
/// (void/refund/reverse via idempotent `requestId` actions), and the record-
/// payment FAB. Ported from the web `app/dashboard/payments/page.tsx`.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  late String _month;

  /// Pending idempotency keys, keyed by action endpoint. Mirrors the web's
  /// `actionRequestIds` ref: a retry of the same action before success reuses
  /// the same `requestId` (so a double-tap can't create a second mutation).
  final Map<String, String> _actionRequestIds = <String, String>{};

  @override
  void initState() {
    super.initState();
    _month = currentMonthKey();
  }

  Future<void> _runAction(String endpoint, String successMessage) async {
    final String requestId = _actionRequestIds[endpoint] ?? createRequestId();
    _actionRequestIds[endpoint] = requestId;
    final dio = ref.read(dioProvider);
    try {
      await postJson<LifecycleResultResponse>(
        dio,
        endpoint,
        data: PaymentActionInput(requestId: requestId).toJson(),
        fromJson: LifecycleResultResponse.fromJson,
      );
      _actionRequestIds.remove(endpoint);
      if (mounted) showAppSnackBar(context, successMessage);
      invalidateGymScopeFromWidget(ref);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Could not update payment', isError: true);
      }
    }
  }

  void _openInvoice(PaymentListResponsePaymentsInner payment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvoiceScreen(paymentId: payment.id),
      ),
    );
  }

  Future<void> _openFilter() async {
    final String? result = await showAppBottomSheet<String>(
      context,
      builder: (_) => _MonthFilterSheet(initial: _month),
    );
    if (result != null && mounted) setState(() => _month = result);
  }

  @override
  Widget build(BuildContext context) {
    // Reset the month filter to the current month when switching gyms, matching
    // the web's `useEffect([currentMonth, selectedGymId])`.
    ref.listen<String?>(selectedGymIdProvider, (String? prev, String? next) {
      if (prev != next) _month = currentMonthKey();
    });

    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final String currency = ref.watch(gymSettingsControllerProvider).currency;

    final AsyncValue<PaymentListResponse> paymentsAsync = ref.watch(
      paymentsProvider(PaymentFilters(month: _month, limit: 50)),
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
                    _CollectedHero(
                      tokens: t,
                      currency: currency,
                      amount: paymentsAsync.valueOrNull?.summary.netAmount ?? 0,
                      total: paymentsAsync.valueOrNull?.total ?? 0,
                      month: _month,
                    ),
                    const SizedBox(height: 20),
                    _HeaderRow(
                      tokens: t,
                      active: _month.isNotEmpty,
                      onFilter: _openFilter,
                    ),
                    const SizedBox(height: 12),
                    ...paymentsAsync.when(
                      data: (PaymentListResponse data) =>
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
            onPressed: () => PaymentFormSheet.show(context, currency: currency),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildList(
    ThemeTokens t,
    String currency,
    PaymentListResponse data,
  ) {
    if (data.payments.isEmpty) {
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
                  color: withOpacity(t.success.value, 0.10),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 28,
                  color: t.success.value,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No payments found',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: t.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _month.isNotEmpty
                    ? 'No payments in this month'
                    : 'Record a payment to get started',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: t.muted.foreground),
              ),
            ],
          ),
        ),
      ];
    }

    return <Widget>[
      for (final PaymentListResponsePaymentsInner payment in data.payments)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PaymentCard(
            payment: payment,
            currency: currency,
            onInvoice: () => _openInvoice(payment),
            onVoid: () =>
                _runAction('/payments/${payment.id}/void', 'Payment voided'),
            onRefund: () =>
                _runAction('/payments/${payment.id}/refund', 'Refund recorded'),
            onReverse: () => _runAction(
              '/memberships/${payment.membershipId}/reverse',
              'Plan purchase reversed',
            ),
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
            height: 94,
            decoration: BoxDecoration(
              color: withOpacity(t.foreground, 0.08),
              borderRadius: BorderRadius.circular(26),
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
              'Could not load payments',
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

// -- collected hero -----------------------------------------------------------

class _CollectedHero extends StatelessWidget {
  const _CollectedHero({
    required this.tokens,
    required this.currency,
    required this.amount,
    required this.total,
    required this.month,
  });

  final ThemeTokens tokens;
  final String currency;
  final num amount;
  final num total;
  final String month;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    final Color labelColor = withOpacity(t.primary.foreground, 0.70);

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.primary.value,
          borderRadius: BorderRadius.circular(32),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: withOpacity(t.primary.value, 0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -48,
              right: -40,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: withOpacity(t.primary.foreground, 0.10),
                    width: 22,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Collected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(amount, currency),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.05 * 32,
                    height: 1,
                    color: t.primary.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$total payment record${total == 1 ? '' : 's'} · '
                  '${monthLabel(month)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -- section header + filter --------------------------------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.tokens,
    required this.active,
    required this.onFilter,
  });

  final ThemeTokens tokens;
  final bool active;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const AppSectionLabel('Payment history'),
          TextButton.icon(
            onPressed: onFilter,
            style: TextButton.styleFrom(
              foregroundColor: active ? t.primary.value : t.foreground,
              backgroundColor: active
                  ? withOpacity(t.primary.value, 0.10)
                  : t.muted.value,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Filter'),
          ),
        ],
      ),
    );
  }
}

// -- month/year filter sheet --------------------------------------------------

class _MonthFilterSheet extends StatefulWidget {
  const _MonthFilterSheet({required this.initial});

  final String? initial;

  @override
  State<_MonthFilterSheet> createState() => _MonthFilterSheetState();
}

class _MonthFilterSheetState extends State<_MonthFilterSheet> {
  late String _monthNum;
  late String _year;

  @override
  void initState() {
    super.initState();
    final String init = widget.initial ?? '';
    if (init.length == 7) {
      final List<String> parts = init.split('-');
      _year = parts[0];
      _monthNum = parts[1];
    } else {
      _year = '';
      _monthNum = '';
    }
  }

  int get _currentYear => DateTime.now().year;

  /// A `YYYY-MM` key only when both a month and a year are chosen (the backend
  /// month filter needs the full key); otherwise empty ("All months").
  String get _result =>
      (_monthNum.isNotEmpty && _year.isNotEmpty) ? '$_year-$_monthNum' : '';

  void _onMonth(String value) {
    setState(() {
      _monthNum = value;
      // Selecting a month before a year defaults the year to the current one so
      // the Apply result is always a complete `YYYY-MM` key.
      if (value.isNotEmpty && _year.isEmpty) _year = _currentYear.toString();
    });
  }

  void _onYear(String value) {
    setState(() => _year = value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return BottomSheetForm(
      title: 'Filter by Month',
      body: <Widget>[
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: _Picker(
                tokens: t,
                value: _monthNum,
                hint: 'Month',
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Month'),
                  ),
                  for (int m = 1; m <= 12; m++)
                    DropdownMenuItem<String>(
                      value: m.toString().padLeft(2, '0'),
                      child: Text(monthName(m)),
                    ),
                ],
                onChanged: _onMonth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Picker(
                tokens: t,
                value: _year,
                hint: 'Year',
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Year'),
                  ),
                  for (int i = 0; i < 5; i++)
                    DropdownMenuItem<String>(
                      value: (_currentYear - i).toString(),
                      child: Text((_currentYear - i).toString()),
                    ),
                ],
                onChanged: _onYear,
              ),
            ),
          ],
        ),
      ],
      footer: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(''),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.foreground,
                side: BorderSide(color: t.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.radius),
                ),
              ),
              child: const Text('Clear'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_result),
              style: FilledButton.styleFrom(
                backgroundColor: t.primary.value,
                foregroundColor: t.primary.foreground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.radius),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    required this.tokens,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final ThemeTokens tokens;
  final String value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokens;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.card.value,
        borderRadius: BorderRadius.circular(t.radius),
        border: Border.all(color: withOpacity(t.border, 0.7)),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: t.muted.foreground)),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(t.radius),
        style: TextStyle(
          color: t.foreground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        icon: Icon(Icons.keyboard_arrow_down, color: t.muted.foreground),
        items: items,
        onChanged: (String? v) => onChanged(v ?? ''),
      ),
    );
  }
}
