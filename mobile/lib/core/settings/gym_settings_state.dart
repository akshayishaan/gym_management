/// Default settings applied when no gym is selected (mirrors the web app's
/// `DEFAULT_SETTINGS` in `lib/useGymSettings.tsx`).
const String kDefaultGymName = 'My Gym';
const String kDefaultCurrency = 'INR';
const String kDefaultTimezone = 'Asia/Kolkata';
const String kDefaultPrimaryColor = '#6366f1';

/// The resolved settings for the currently selected gym, plus the selection
/// and pending-switch bookkeeping.
///
/// [selectedGymId] is a mirror of `selectedGymIdProvider` (the single source of
/// truth) for convenient widget reads; [pendingGymId] is non-null while a
/// dirty-form switch is awaiting confirmation (the dialog is phase 3b).
///
/// A plain immutable class (no `freezed` codegen) so the scaffold analyzes and
/// runs standalone, matching [GymTheme] and [AuthState].
class GymSettingsState {
  const GymSettingsState({
    this.selectedGymId,
    this.gymName = kDefaultGymName,
    this.currency = kDefaultCurrency,
    this.timezone = kDefaultTimezone,
    this.primaryColor = kDefaultPrimaryColor,
    this.address,
    this.phone,
    this.email,
    this.pendingGymId,
  });

  /// The id of the currently selected gym, or `null` when none is selected.
  final String? selectedGymId;

  final String gymName;
  final String currency;
  final String timezone;
  final String primaryColor;
  final String? address;
  final String? phone;
  final String? email;

  /// The gym awaiting a dirty-form switch confirmation, or `null`.
  final String? pendingGymId;

  /// Whether a gym switch is blocked on a "Discard changes and switch?"
  /// confirmation.
  bool get hasPendingSwitch => pendingGymId != null;

  /// Sentinel marking an absent argument in [copyWith], so `null` can be used
  /// to explicitly clear a nullable field.
  static const Object _unset = Object();

  GymSettingsState copyWith({
    Object? selectedGymId = _unset,
    String? gymName,
    String? currency,
    String? timezone,
    String? primaryColor,
    Object? address = _unset,
    Object? phone = _unset,
    Object? email = _unset,
    Object? pendingGymId = _unset,
  }) {
    return GymSettingsState(
      selectedGymId: identical(selectedGymId, _unset)
          ? this.selectedGymId
          : selectedGymId as String?,
      gymName: gymName ?? this.gymName,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      primaryColor: primaryColor ?? this.primaryColor,
      address: identical(address, _unset) ? this.address : address as String?,
      phone: identical(phone, _unset) ? this.phone : phone as String?,
      email: identical(email, _unset) ? this.email : email as String?,
      pendingGymId: identical(pendingGymId, _unset)
          ? this.pendingGymId
          : pendingGymId as String?,
    );
  }
}

/// The display symbol for a currency [code] (INR→₹, USD→$, EUR→€, GBP→£),
/// falling back to the raw code for anything unknown.
String currencySymbol(String code) => switch (code) {
      'INR' => '₹',
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      _ => code,
    };
