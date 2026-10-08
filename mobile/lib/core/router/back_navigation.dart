import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Back-arrow behaviour for screens that are reached with `context.go` (which
/// replaces the stack, so there is nothing to pop) as well as with `push`.
/// Pops when it can, otherwise goes to [fallback].
void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// The More menu, where Plans, Reports, Activity and My Gyms are listed.
const kMoreMenuRoute = '/operations';
