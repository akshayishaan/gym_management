import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_controller.dart';
import '../core/auth/auth_state.dart';
import '../layout/shell.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../widgets/app_section_label.dart';
import '../widgets/app_surface.dart';
import '../widgets/hide_scrollbar.dart';
import '../widgets/theme_toggle.dart';

/// The Settings drill-in screen: signed-in identity, account details, theme
/// preference, and sign-out. Ported from the web
/// `app/dashboard/settings/page.tsx`.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;
    final AuthUser? user = ref.watch(authControllerProvider).user;

    final String name = user?.name ?? '—';
    final String email = user?.email ?? '—';

    return AppShell(
      mode: ShellMode.stack,
      title: 'Settings',
      selectedIndex: 3,
      onSelectTab: (_) {},
      onBack: () => Navigator.of(context).maybePop(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HideScrollBar(
              child: ListView(
                padding: const EdgeInsets.only(top: 20, bottom: 24),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: t.foreground,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: withOpacity(t.background, 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.person, color: t.background),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                name,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: t.background,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: withOpacity(t.background, 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const AppSectionLabel('Account details'),
                  const SizedBox(height: 12),
                  AppSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      children: <Widget>[
                        _AccountRow(
                          icon: Icons.person_outline,
                          tone: withOpacity(t.primary.value, 0.10),
                          iconColor: t.primary.value,
                          label: 'Name',
                          value: name,
                          t: t,
                        ),
                        Container(height: 1, color: withOpacity(t.border, 0.58)),
                        _AccountRow(
                          icon: Icons.mail_outline,
                          tone: withOpacity(t.accent.value, 0.10),
                          iconColor: t.accent.foreground,
                          label: 'Email',
                          value: email,
                          t: t,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const AppSectionLabel('Preferences'),
                  const SizedBox(height: 12),
                  AppSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(32),
                    child: const ThemeToggle(),
                  ),
                  const SizedBox(height: 20),
                  AppSurface(
                    color: withOpacity(t.destructive.value, 0.10),
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onTap: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.logout, color: t.destructive.value),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: t.destructive.value,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.tone,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.t,
  });

  final IconData icon;
  final Color tone;
  final Color iconColor;
  final String label;
  final String value;
  final ThemeTokens t;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: t.muted.foreground),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: t.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
