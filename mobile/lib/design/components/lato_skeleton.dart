import 'package:flutter/material.dart';

import '../colors.dart';

/// Solid placeholder block used to build skeleton screens. Skeletons mirror
/// the real layout's padding and block heights so nothing shifts when the data
/// arrives. Wrap whole skeletons in `ExcludeSemantics`.
class LatoSkeletonBlock extends StatelessWidget {
  const LatoSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  /// Null stretches to the parent's width.
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: LatoColors.surfaceRaisedDark,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
