import 'breakpoints.dart';

class AppSpacing {
  static double xs(DeviceClass deviceClass) {
    switch (deviceClass) {
      case DeviceClass.compact:
        return 3.0;
      case DeviceClass.small:
        return 4.0;
      case DeviceClass.medium:
      case DeviceClass.expanded:
      case DeviceClass.large:
        return 6.0;
    }
  }

  static double sm(DeviceClass deviceClass) {
    switch (deviceClass) {
      case DeviceClass.compact:
        return 6.0;
      case DeviceClass.small:
        return 8.0;
      case DeviceClass.medium:
      case DeviceClass.expanded:
      case DeviceClass.large:
        return 10.0;
    }
  }

  static double md(DeviceClass deviceClass) {
    switch (deviceClass) {
      case DeviceClass.compact:
        return 10.0;
      case DeviceClass.small:
        return 12.0;
      case DeviceClass.medium:
      case DeviceClass.expanded:
      case DeviceClass.large:
        return 16.0;
    }
  }

  static double lg(DeviceClass deviceClass) {
    switch (deviceClass) {
      case DeviceClass.compact:
        return 14.0;
      case DeviceClass.small:
        return 16.0;
      case DeviceClass.medium:
      case DeviceClass.expanded:
      case DeviceClass.large:
        return 20.0;
    }
  }

  static double xl(DeviceClass deviceClass) {
    switch (deviceClass) {
      case DeviceClass.compact:
        return 18.0;
      case DeviceClass.small:
        return 20.0;
      case DeviceClass.medium:
      case DeviceClass.expanded:
      case DeviceClass.large:
        return 24.0;
    }
  }

  static double xxl(DeviceClass deviceClass) {
    switch (deviceClass) {
      case DeviceClass.compact:
        return 22.0;
      case DeviceClass.small:
        return 24.0;
      case DeviceClass.medium:
      case DeviceClass.expanded:
      case DeviceClass.large:
        return 32.0;
    }
  }

  // Minimum touch target dimension (iOS: 44, Android: 48)
  static const double minTouchTarget = 48.0;
}
