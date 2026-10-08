import 'package:flutter/material.dart';

import '../colors.dart';
import '../spacing.dart';

/// Shared modal bottom sheets. Use these instead of calling
/// `showModalBottomSheet` directly so every sheet has the same surface,
/// rounded top corners, drag handle, safe-area handling and navigation
/// behaviour.
///
/// Sheets close by swiping down, tapping the dimmed area, or the system back
/// button, so they do not need a close (X) button. Give every sheet a short
/// title with [LatoSheetTitle]; it is the accessible name for the sheet.
///
/// Both variants open on the root navigator, so the sheet and its scrim cover
/// the bottom navigation bar, and clip their content to the rounded top
/// corners (a child that paints its own opaque background would otherwise
/// show square corners).

/// Content-height sheet, capped by the screen. Use for short pick-lists and
/// confirmations. The content should size itself and keep its height stable
/// while data loads.
Future<T?> showLatoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: LatoColors.surfaceDark,
    shape: const RoundedRectangleBorder(borderRadius: LatoRadius.sheet),
    clipBehavior: Clip.antiAlias,
    builder: builder,
  );
}

/// Fixed-height (92%) sheet for long forms. The child starts with a
/// [LatoSheetTitle] and scrolls its own body.
Future<T?> showLatoFormSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: LatoColors.surfaceDark,
    shape: const RoundedRectangleBorder(borderRadius: LatoRadius.sheet),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) =>
        FractionallySizedBox(heightFactor: 0.92, child: builder(ctx)),
  );
}

/// Title row for the top of a sheet, below the drag handle that
/// [showLatoSheet] and [showLatoFormSheet] draw. Marked as a header so screen
/// readers announce it when the sheet opens.
class LatoSheetTitle extends StatelessWidget {
  const LatoSheetTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LatoSpacing.xl,
        0,
        LatoSpacing.xl,
        LatoSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
      ),
    );
  }
}

/// Layout for a long form inside [showLatoFormSheet]: a pinned [LatoSheetTitle],
/// a [body] that scrolls, and a [footer] (the one primary button) pinned at
/// the bottom so it is always visible.
///
/// The footer is a sibling of the scroll area, not an overlay, so the body
/// simply gets shorter and a focused field is never hidden behind it. The
/// whole sheet rides above the keyboard.
class LatoFormSheetScaffold extends StatelessWidget {
  const LatoFormSheetScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.footer,
  });

  final String title;
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Material(
        color: LatoColors.surfaceDark,
        child: Column(
          children: [
            LatoSheetTitle(title),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  LatoSpacing.xl,
                  0,
                  LatoSpacing.xl,
                  LatoSpacing.xxl,
                ),
                child: body,
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: LatoColors.borderDark)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LatoSpacing.xl,
                    LatoSpacing.md,
                    LatoSpacing.xl,
                    LatoSpacing.lg,
                  ),
                  child: footer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
