import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_providers.dart';
import '../data/api_helpers.dart';
import '../data/gym_providers.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'app_section_label.dart';
import 'app_snackbar.dart';
import 'bottom_sheet_form.dart';

/// Add/Edit gym form rendered inside a [BottomSheetForm].
///
/// CREATE adds a gym and returns it; EDIT updates an existing gym in place.
class GymFormSheet extends ConsumerStatefulWidget {
  const GymFormSheet({super.key, this.gym});

  final GymResponse? gym;

  /// Shows the sheet as a modal bottom sheet; completes with the created or
  /// updated [GymResponse], or `null` when dismissed.
  static Future<GymResponse?> show(BuildContext context, {GymResponse? gym}) {
    return showAppBottomSheet<GymResponse>(
      context,
      builder: (_) => GymFormSheet(gym: gym),
    );
  }

  @override
  ConsumerState<GymFormSheet> createState() => _GymFormSheetState();
}

class _GymFormSheetState extends ConsumerState<GymFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _currency = TextEditingController();
  final TextEditingController _primaryColor = TextEditingController();

  String? _logo;
  String _timezone = 'Asia/Kolkata';
  String _primaryColorValue = '#6366f1';
  bool _saving = false;

  static const List<String> _presetColors = <String>[
    '#6366f1',
    '#f97316',
    '#10b981',
    '#ef4444',
    '#8b5cf6',
    '#06b6d4',
    '#f59e0b',
    '#ec4899',
    '#14b8a6',
    '#6d28d9',
  ];

  static const List<String> _timezones = <String>[
    'Asia/Kolkata',
    'Asia/Dubai',
    'Asia/Singapore',
    'Europe/London',
    'America/New_York',
    'America/Los_Angeles',
    'Australia/Sydney',
  ];

  bool get _isEdit => widget.gym != null;

  @override
  void initState() {
    super.initState();
    _primaryColor.text = _primaryColorValue;
    final GymResponse? gym = widget.gym;
    if (_isEdit && gym != null) {
      _name.text = gym.name;
      _phone.text = gym.phone ?? '';
      _email.text = gym.email ?? '';
      _address.text = gym.address ?? '';
      _currency.text = gym.currency;
      _primaryColorValue = gym.primaryColor;
      _primaryColor.text = gym.primaryColor;
      _logo = gym.logo;
      _timezone = gym.timezone;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _currency.dispose();
    _primaryColor.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Uint8List? _decodeLogo() {
    final String raw = _logo ?? '';
    if (raw.isEmpty) return null;
    try {
      final String base64 = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickLogo() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (file == null) return;

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.length > 500 * 1024) {
      if (mounted) {
        showAppSnackBar(context, 'Logo must be under 500KB', isError: true);
      }
      return;
    }

    setState(() {
      _logo = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnackBar(context, 'Gym name is required', isError: true);
      return;
    }

    final String currency = _currency.text.trim().toUpperCase();
    if (currency.length != 3) {
      showAppSnackBar(context, 'Currency must be a 3-letter code', isError: true);
      return;
    }

    final String primaryColor = _primaryColor.text.trim();
    if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(primaryColor)) {
      showAppSnackBar(context, 'Theme color must be a hex color like #6366f1',
          isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final GymResponse saved;
      if (_isEdit) {
        final GymUpdateInput input = GymUpdateInput(
          name: name,
          logo: _logo,
          primaryColor: primaryColor,
          address: _nullIfEmpty(_address.text),
          phone: _nullIfEmpty(_phone.text),
          email: _nullIfEmpty(_email.text),
          currency: currency,
          timezone: _timezone,
        );
        saved = await putJson<GymResponse>(
          dio,
          '/gyms/${widget.gym!.id}',
          data: input.toJson(),
          fromJson: GymResponse.fromJson,
        );
      } else {
        final GymCreateInput input = GymCreateInput(
          name: name,
          logo: _logo,
          primaryColor: primaryColor,
          address: _nullIfEmpty(_address.text),
          phone: _nullIfEmpty(_phone.text),
          email: _nullIfEmpty(_email.text),
          currency: currency,
          timezone: _timezone,
          expiryReminderDays: 7,
        );
        saved = await postJson<GymResponse>(
          dio,
          '/gyms',
          data: input.toJson(),
          fromJson: GymResponse.fromJson,
        );
      }

      if (mounted) {
        showAppSnackBar(context, _isEdit ? 'Gym updated' : 'Gym created');
      }
      ref.invalidate(gymsProvider);
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (mounted) showAppSnackBar(context, e.userMessage, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Something went wrong', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _submitLabel() {
    if (_saving) return _isEdit ? 'Saving…' : 'Creating…';
    return _isEdit ? 'Save Changes' : 'Create Gym';
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final Uint8List? logoBytes = _decodeLogo();

    return BottomSheetForm(
      title: _isEdit ? 'Edit Gym' : 'Add New Gym',
      body: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: t.muted.value,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: logoBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.memory(
                                    logoBytes,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.apartment, color: t.muted.foreground),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: t.primary.value,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 12,
                              color: t.primary.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(t, 'Gym Name *', hint: 'e.g. FitZone Gym'),
                style: TextStyle(color: t.foreground),
                validator: (String? v) => _required(v, 'Gym Name'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(t, 'Phone'),
                      style: TextStyle(color: t.foreground),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(t, 'Email'),
                      style: TextStyle(color: t.foreground),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(t, 'Address'),
                style: TextStyle(color: t.foreground),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _currency,
                      maxLength: 3,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration(t, 'Currency'),
                      style: TextStyle(color: t.foreground),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _hexToColor(_primaryColorValue),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: withOpacity(t.border, 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _primaryColor,
                            decoration: _inputDecoration(t, 'Theme Color'),
                            style: TextStyle(
                              color: t.foreground,
                              fontFamily: 'monospace',
                            ),
                            onChanged: (String v) {
                              if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v.trim())) {
                                setState(() => _primaryColorValue = v.trim());
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _timezone,
                decoration: _inputDecoration(t, 'Gym timezone'),
                items: <DropdownMenuItem<String>>[
                  for (final String tz in _timezones)
                    DropdownMenuItem<String>(
                      value: tz,
                      child: Text(tz.replaceAll('_', ' ')),
                    ),
                ],
                onChanged: (String? v) => setState(() => _timezone = v ?? _timezone),
              ),
              const SizedBox(height: 8),
              Text(
                'Membership dates and reports use this timezone.',
                style: TextStyle(fontSize: 11, color: t.muted.foreground),
              ),
              const SizedBox(height: 16),
              const AppSectionLabel('Theme Color'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final String c in _presetColors)
                    GestureDetector(
                      onTap: () => setState(() {
                        _primaryColorValue = c;
                        _primaryColor.text = c;
                      }),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(c),
                          shape: BoxShape.circle,
                          border: _primaryColorValue == c
                              ? Border.all(color: t.foreground, width: 2)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
      footer: _buildSubmitButton(t),
    );
  }

  Widget _buildSubmitButton(ThemeTokens t) {
    return FilledButton(
      onPressed: _saving ? null : _submit,
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
      child: _saving
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.primary.foreground,
              ),
            )
          : Text(_submitLabel()),
    );
  }
}

InputDecoration _inputDecoration(ThemeTokens t, String label, {String? hint}) {
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(t.radius),
    borderSide: BorderSide(color: withOpacity(t.border, 0.7)),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: t.card.value,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: TextStyle(color: t.muted.foreground),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(t.radius),
      borderSide: BorderSide(color: withOpacity(t.ring, 0.4), width: 2),
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

Color _hexToColor(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length == 8) {
    final int? parsed = int.tryParse(value, radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return const Color(0xFFF97316);
}
