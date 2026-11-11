import 'package:flutter/widgets.dart';

/// Shared animation timings. When the OS asks for reduced motion
/// (MediaQuery.disableAnimations), animations collapse to zero duration and
/// looping effects don't start.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
