import 'package:flutter/material.dart';

/// A staggered-rise reveal container mirroring the `.app-screen` CSS utility.
///
/// Each direct child animates in with `opacity 0→1` and `translateY(8px→0)`
/// over 420ms using an ease-out cubic-bezier `(0.22, 1, 0.36, 1)`, with a
/// per-index delay of 0 / 45 / 90 / 135 / 180ms.
///
/// Respects reduced motion: when `MediaQuery.disableAnimations` is true (or
/// the platform requests reduced motion) children render at their final state
/// with no animation.
class AppScreen extends StatelessWidget {
  const AppScreen({super.key, required this.children});

  final List<Widget> children;

  static const Duration _duration = Duration(milliseconds: 420);
  static const List<Duration> _delays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 45),
    Duration(milliseconds: 90),
    Duration(milliseconds: 135),
    Duration(milliseconds: 180),
  ];

  /// The CSS `cubic-bezier(0.22, 1, 0.36, 1)` curve mapped to Flutter's
  /// [Cubic] parameters (x1, y1, x2, y2).
  static const Cubic _riseCurve = Cubic(0.22, 1, 0.36, 1);

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < children.length; i++)
          _RiseChild(
            index: i,
            reduceMotion: reduceMotion,
            child: children[i],
          ),
      ],
    );
  }
}

class _RiseChild extends StatefulWidget {
  const _RiseChild({
    required this.index,
    required this.reduceMotion,
    required this.child,
  });

  final int index;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_RiseChild> createState() => _RiseChildState();
}

class _RiseChildState extends State<_RiseChild>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppScreen._duration,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: AppScreen._riseCurve,
    reverseCurve: AppScreen._riseCurve,
  );

  late final Animation<Offset> _offset = _opacity.drive(
    Tween<Offset>(
      begin: const Offset(0, 8),
      end: Offset.zero,
    ),
  );

  @override
  void initState() {
    super.initState();
    final Duration delay =
        widget.index < AppScreen._delays.length
            ? AppScreen._delays[widget.index]
            : AppScreen._delays.last;

    if (widget.reduceMotion) {
      _controller.value = 1;
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
