import 'package:flutter/material.dart';

import '../../../design/colors.dart';

/// Activity-log-specific colors and text styles. The brand-wide tokens
/// live in `design/colors.dart`; the values here are sampled from the
/// Figma `activity_log.png` design and don't need to be shared.
class Alog {
  Alog._();

  // Surfaces
  static const Color rail = Color(0xFF31353C);
  static const Color railBg = Color(0xFF1c2026);
  static const Color railTrackBg = Color(0xFF0a0e14);
  static const Color railHeaderBg = Color(0xF810141A);
  static const Color railHeaderBorder = Color(0x66262a31);
  static const Color pillBg = Color(0xFF262a31);
  static const Color pillBorder = Color(0xFF31353c);
  static const Color cardBorder = Color(0xFF262a31);
  static const Color footerBg = Color(0xFF1c2026);
  static const Color allChipBg = Color(0xFFC3F400);
  static const Color allChipFg = Color(0xFF0a0e14);
  static const Color avatarBorder = Color(0xFF31353c);
  static const Color avatarBg = Color(0xFF262a31);
  static const Color pastDot = Color(0xFF8E9379);
  static const Color sage = Color(0xFFc4c9ac);
  static const Color titleFg = Color(0xFFdfe2eb);
  static const Color titleBg = Color(0xFFD5D9E2);

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