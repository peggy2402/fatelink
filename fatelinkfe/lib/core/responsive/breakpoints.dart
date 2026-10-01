enum DeviceClass {
  compact,  // < 360 (Folded phones ~280px, iPhone SE 1st gen 320px)
  small,    // 360 - 399 (Standard Android 360-393px, iPhone Mini 375px)
  medium,   // 400 - 599 (iPhone Pro Max 430px, Galaxy Ultra 412px)
  expanded, // 600 - 839 (Foldable inner ~700px, Small tablets, Landscape phones)
  large,    // >= 840 (Large tablets 1024px+, iPad Pro)
}

class Breakpoints {
  static const double compact = 360.0;
  static const double small = 400.0;
  static const double medium = 600.0;
  static const double expanded = 840.0;

  static DeviceClass getDeviceClass(double width) {
    if (width < compact) return DeviceClass.compact;
    if (width < small) return DeviceClass.small;
    if (width < medium) return DeviceClass.medium;
    if (width < expanded) return DeviceClass.expanded;
    return DeviceClass.large;
  }
}
