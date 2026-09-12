# GYM MANAGER — Flutter Client

Mobile-only gym management SaaS client (Material 3 + Riverpod + dio +
freezed/json_serializable). This is issue-13 scope: **scaffold + design system
+ navigation shell** with placeholder screens for the issues that follow.

## Structure

```
lib/
  main.dart                     entry point (ProviderScope + GymManagerApp)
  app.dart                      MaterialApp + tab-root index selection
  theme/
    tokens.dart                 semantic design tokens (light/dark as data)
    colors.dart                 hex → Color + alpha helpers
    theme.dart                  buildAppTheme() + AppThemeTokens extension
  widgets/
    app_canvas.dart             radial-gradient background stack
    app_screen.dart             staggered rise animation (reduced-motion aware)
    app_surface.dart            card + border + double shadow (.app-surface)
    app_section_label.dart      uppercase 11px section label
    hide_scrollbar.dart         hide scrollbars on all platforms
  layout/
    top_app_bar.dart            translucent blurred app bar + brand row + title
    bottom_tab_bar.dart         floating dock (Today/Members/Payments/More)
    stack_header.dart           drill-in header (back + title + actions)
    shell.dart                  AppShell (tab-root vs. stack modes)
  core/settings/
    gym_theme.dart              GymTheme model + per-gym primaryColor parsing
    theme_controller.dart       Riverpod Notifier + theme providers
  screens/
    today_screen.dart           placeholder (issue 15)
    members_screen.dart         placeholder (issue 15)
    payments_screen.dart        placeholder (issue 16)
    more_screen.dart            placeholder (issues 17-18)
```

## Design tokens

Light/dark palettes live in `lib/theme/tokens.dart` as `const ThemeTokens`
(ported verbatim from the web `app/globals.css` HSL values, converted to hex
with CSS's `hsl()` algorithm). `buildAppTheme({brightness, primary})` resolves
the `ColorScheme` and exposes the token set as a `ThemeExtension` so widgets
read `tokens.primary`, `tokens.dock`, etc. — **no hardcoded colors**.

Per-gym theming: `ThemeController.setGym({primaryColor})` swaps the resolved
primary; dark mode follows `ThemeMode.system`.

## Fonts

Inter (body) and Manrope (display) are bundled as variable TTFs under
`assets/fonts/` (OFL licensed) and declared in `pubspec.yaml`.

> The variable TTFs were fetched from Google Fonts at scaffold time. If they
> are ever removed from the repo, re-download them:
>
> ```
> Inter    → ofl/inter/Inter[opsz,wght].ttf
> Manrope  → ofl/manrope/Manrope[wght].ttf
> ```

## Development

The Flutter/Dart SDK is **not required to vendor this code**, but is needed to
build/run. With the SDK installed:

```sh
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run        # pick a device/emulator
```

The app is mobile-only; run on a phone/emulator, not a desktop browser.
