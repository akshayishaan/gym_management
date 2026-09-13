# 13 — Flutter scaffold + design system + nav shell

**What to build:** Flutter 3.x Mobile app scaffold with a Material 3 ThemeData builder reading the exact CSS token values (primary hsl(15 91% 57%), success, warning, destructive, accent, muted, background hsl(34 33% 96%), foreground hsl(222 42% 11%), card white, dock dark navy; radius 1.125rem), fonts Inter (body) + Manrope (display) bundled. Custom widgets: AppCanvas (radial gradient), AppScreen (staggered rise animation), AppSurface (card+border+shadow), AppSectionLabel (uppercase 11px bold), HideScrollBar. Semantic tokens only so per-gym primaryColor + dark mode work. Navigation shell: bottom nav dock (Today/Members/Payments/More) + TopAppBar + StackHeader (back).

**Blocked by:** 11

**Status:** ready-for-agent

- [ ] Theme matches CSS tokens (verify colors/radius/fonts visually against the web app)
- [ ] Dark mode + per-gym primaryColor theming works
- [ ] AppCanvas/AppScreen/AppSurface/AppSectionLabel widgets reproduce the current look
- [ ] Bottom dock + TopAppBar + StackHeader navigation shell functional
