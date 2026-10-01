import 'package:flutter/material.dart';
import 'breakpoints.dart';

extension ResponsiveContext on BuildContext {
  // Safe MediaQuery getters using sizeOf, paddingOf, viewInsetsOf, textScalerOf
  // to avoid unnecessary widget rebuilds across the tree
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);
  double get safeTop => screenPadding.top;
  double get safeBottom => screenPadding.bottom;
  double get safeLeft => screenPadding.left;
  double get safeRight => screenPadding.right;

  EdgeInsets get screenViewInsets => MediaQuery.viewInsetsOf(this);
  double get keyboardHeight => screenViewInsets.bottom;
  bool get isKeyboardOpen => keyboardHeight > 0;

  TextScaler get textScaler => MediaQuery.textScalerOf(this);
  double get textScaleFactor => textScaler.scale(1.0);
  double get textScale => textScaleFactor;

  Orientation get orientation => MediaQuery.orientationOf(this);
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  DeviceClass get deviceClass => Breakpoints.getDeviceClass(screenWidth);
  bool get isCompact => deviceClass == DeviceClass.compact;
  bool get isSmall => deviceClass == DeviceClass.small;
  bool get isMedium => deviceClass == DeviceClass.medium;
  bool get isExpanded => deviceClass == DeviceClass.expanded;
  bool get isLarge => deviceClass == DeviceClass.large;

  bool get isPhone => screenWidth < Breakpoints.medium;
  bool get isTablet => screenWidth >= Breakpoints.medium;

  // Responsive value helper based on screen configuration
  T responsiveValue<T>({
    required T phone,
    T? tablet,
    T? compact,
    T? landscape,
  }) {
    if (isLandscape && landscape != null) return landscape;
    if (isCompact && compact != null) return compact;
    if (isTablet && tablet != null) return tablet;
    return phone;
  }
}
