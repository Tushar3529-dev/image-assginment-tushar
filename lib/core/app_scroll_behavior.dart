import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Lets every pointer kind drag-scroll, including a mouse.
///
/// Flutter's default only drag-scrolls with touch, stylus and trackpad, so
/// clicking and dragging with a mouse (iOS Simulator / Android emulator with
/// a pointer, desktop, web) wouldn't move the Images grid at all.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}
