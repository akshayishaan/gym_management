import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/colors.dart';
import '../../theme/theme.dart';
import 'gym_settings_controller.dart';
import 'gym_settings_state.dart';

/// Overlays a "Discard changes and switch Gym?" confirmation dialog whenever a
/// gym switch is blocked on a dirty form ([GymSettingsState.hasPendingSwitch]).
///
/// The [child] is always rendered underneath; the dialog is purely an overlay
/// driven by state, so no navigation or `showDialog` is involved.
class GymSwitchGuard extends ConsumerWidget {
  const GymSwitchGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GymSettingsState settings = ref.watch(gymSettingsControllerProvider);
    final ThemeTokens t = Theme.of(context).extension<AppThemeTokens>()!.tokens;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        if (settings.hasPendingSwitch) ...<Widget>[
          AbsorbPointer(
            child: ColoredBox(color: withOpacity(t.foreground, 0.4)),
          ),
          Center(
            child: AlertDialog(
              title: const Text('Discard changes and switch Gym?'),
              content: const Text(
                'You have unsaved changes. Switching gyms will discard them.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => ref
                      .read(gymSettingsControllerProvider.notifier)
                      .cancelPendingSwitch(),
                  child: Text(
                    'Keep editing',
                    style: TextStyle(color: t.muted.foreground),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(gymSettingsControllerProvider.notifier)
                      .confirmPendingSwitch(),
                  child: Text(
                    'Discard and switch',
                    style: TextStyle(color: t.destructive.value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
