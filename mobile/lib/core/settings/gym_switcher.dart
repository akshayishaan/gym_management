import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_api/gym_api.dart';

import '../../data/gym_providers.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../widgets/app_section_label.dart';
import '../../widgets/app_surface.dart';
import 'gym_settings_controller.dart';
import 'gym_settings_state.dart';

/// The top-bar gym picker: a tappable pill showing the current gym name that
/// opens a bottom sheet listing every gym the user belongs to.
class GymSwitcher extends ConsumerWidget {
  const GymSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GymSettingsState settings = ref.watch(gymSettingsControllerProvider);
    final AsyncValue<List<GymResponse>> gyms = ref.watch(gymsProvider);
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    final List<GymResponse>? list = gyms.valueOrNull;
    final bool enabled =
        list != null && list.isNotEmpty && settings.selectedGymId != null;
    final String label =
        settings.selectedGymId == null ? 'Choose gym' : settings.gymName;

    return Material(
      color: Colors.transparent,
      child: Ink(
        height: 36,
        decoration: BoxDecoration(
          color: t.card.value,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: withOpacity(t.border, 0.6)),
        ),
        child: InkWell(
          onTap: enabled ? () => _openSheet(context) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.home_work_outlined,
                  size: 14,
                  color: t.muted.foreground,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: t.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: t.muted.foreground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _GymListSheet(),
    );
  }
}

/// The gym-list bottom sheet: one row per gym, with a checkmark on the current
/// selection. Tapping a row switches to that gym and closes the sheet.
class _GymListSheet extends ConsumerWidget {
  const _GymListSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GymSettingsState settings = ref.watch(gymSettingsControllerProvider);
    final AsyncValue<List<GymResponse>> gyms = ref.watch(gymsProvider);
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: t.muted.value,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const AppSectionLabel('Your gyms'),
            const SizedBox(height: 12),
            gyms.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: t.primary.value),
                ),
              ),
              error: (Object error, StackTrace stackTrace) => Text(
                'Could not load gyms.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: t.muted.foreground,
                ),
              ),
              data: (List<GymResponse> list) => Column(
                children: <Widget>[
                  for (int i = 0; i < list.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 8),
                    _GymTile(
                      gym: list[i],
                      selected: list[i].id == settings.selectedGymId,
                      onTap: () {
                        ref
                            .read(gymSettingsControllerProvider.notifier)
                            .switchGym(list[i].id);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GymTile extends StatelessWidget {
  const _GymTile({
    required this.gym,
    required this.selected,
    required this.onTap,
  });

  final GymResponse gym;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return AppSurface(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              gym.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: t.foreground,
              ),
            ),
          ),
          if (selected) Icon(Icons.check, size: 18, color: t.primary.value),
        ],
      ),
    );
  }
}
