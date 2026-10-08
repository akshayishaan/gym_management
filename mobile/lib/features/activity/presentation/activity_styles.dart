import 'package:flutter/material.dart';

import '../../../design/colors.dart';

/// Activity-log text styles and the few surface aliases the timeline uses.
/// Every colour comes from the app palette in `design/colors.dart`.
class Alog {
  Alog._();

  // Surfaces
  static const Color rail = LatoColors.borderStrongDark;
  static const Color railBg = LatoColors.bgDark;
  static const Color railHeaderBg = LatoColors.bgDark;
  static const Color railHeaderBorder = LatoColors.borderDark;
  static const Color pillBg = LatoColors.surfaceRaisedDark;
  static const Color pillBorder = LatoColors.borderDark;
  static const Color cardBorder = LatoColors.borderDark;
  static const Color footerBg = LatoColors.surfaceRaisedDark;
  static const Color avatarBorder = LatoColors.borderDark;
  static const Color avatarBg = LatoColors.surfaceRaisedDark;
  static const Color pastDot = LatoColors.textTertiaryDark;
  static const Color sage = LatoColors.textSecondaryDark;
  static const Color titleFg = LatoColors.textPrimaryDark;

  // Reusable text styles for the timeline / chips
  static const TextStyle eyebrow = TextStyle(
    color: sage,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.55,
  );
  static const TextStyle sage12 = TextStyle(
    color: sage,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle sage13 = TextStyle(
    color: sage,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle bigNumber = TextStyle(
    color: LatoColors.textPrimaryDark,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
  );
  static const TextStyle dateHeader = TextStyle(
    color: titleFg,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.45,
  );
  static const TextStyle cardTitle = TextStyle(
    color: LatoColors.textPrimaryDark,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
  );
  static const TextStyle staffName = TextStyle(
    color: titleFg,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle bodyCopy = TextStyle(
    color: sage,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 19.5 / 12,
  );
  static const TextStyle loadMore = TextStyle(
    color: titleFg,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle loadMoreDim = TextStyle(
    color: LatoColors.textTertiaryDark,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle showingCount = TextStyle(
    color: sage,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}
