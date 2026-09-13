import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';
import 'hide_scrollbar.dart';

/// Shared modal-bottom-sheet config: a card-colored, scroll-controlled sheet
/// with the app's large top corner radius.
///
/// Every bottom-sheet surface (forms, pickers) routes through this helper so
/// the radius, background and `isScrollControlled` flag stay consistent.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
  final ThemeTokens t = ext.tokens;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.card.value,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(t.radius * 1.77), // ~32px
      ),
    ),
    builder: builder,
  );
}

/// A sticky-footer bottom-sheet form scaffold, mirroring the web
/// `BottomSheetForm` (`max-h-[92svh]`).
///
/// Layout: drag handle → header (Manrope title + optional description) →
/// scrollable body → sticky footer (top border + safe-area padding).
class BottomSheetForm extends StatelessWidget {
  const BottomSheetForm({
    super.key,
    required this.title,
    this.description,
    required this.body,
    required this.footer,
    this.onClose,
  });

  final String title;
  final String? description;
  final List<Widget> body;
  final Widget footer;

  /// Optional explicit close affordance; when set, an ✕ button renders in the
  /// header and is wired to this callback.
  final VoidCallback? onClose;

  /// Shows [BottomSheetForm] as a modal bottom sheet and returns the future
  /// that completes when it is dismissed/popped.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? description,
    required List<Widget> body,
    required Widget footer,
    VoidCallback? onClose,
  }) {
    return showAppBottomSheet<T>(
      context,
      builder: (_) => BottomSheetForm(
        title: title,
        description: description,
        body: body,
        footer: footer,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens ext = Theme.of(context).extension<AppThemeTokens>()!;
    final ThemeTokens t = ext.tokens;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Drag handle.
            Center(
              child: Container(
                width: 40,
                height: 6,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: t.muted.value,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // Header.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: t.foreground,
                          ),
                        ),
                        if (description != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            description!,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: t.muted.foreground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(Icons.close, size: 20, color: t.muted.foreground),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            // Scrollable body.
            Flexible(
              child: HideScrollBar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: body,
                  ),
                ),
              ),
            ),
            // Sticky footer.
            Container(
              decoration: BoxDecoration(
                color: withOpacity(t.card.value, 0.95),
                border: Border(
                  top: BorderSide(color: withOpacity(t.border, 0.6)),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}
