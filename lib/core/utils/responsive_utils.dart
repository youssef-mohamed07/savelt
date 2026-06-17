// Responsive Utils - أدوات التصميم المتجاوب
// Utilities for responsive design across different screen sizes

import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Get screen type
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  // Check if mobile
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.mobile;
  }

  // Check if tablet
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  // Check if desktop
  static bool isDesktop(BuildContext context) {
    return getScreenType(context) == ScreenType.desktop;
  }

  // Get responsive value based on screen width percentage
  static double wp(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }

  // Get responsive value based on screen height percentage
  static double hp(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final width = screenWidth(context);
    final scale = (width / 375).clamp(0.8, 1.5); // Base width 375 (iPhone)
    
    return EdgeInsets.only(
      top: (top ?? vertical ?? all ?? 0) * scale,
      bottom: (bottom ?? vertical ?? all ?? 0) * scale,
      left: (left ?? horizontal ?? all ?? 0) * scale,
      right: (right ?? horizontal ?? all ?? 0) * scale,
    );
  }

  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = screenWidth(context);
    final scale = (width / 375).clamp(0.85, 1.3); // Prevent too small or too large text
    return baseFontSize * scale;
  }

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final width = screenWidth(context);
    final scale = (width / 375).clamp(0.8, 1.5);
    return baseSpacing * scale;
  }

  // Get responsive width
  static double getResponsiveWidth(BuildContext context, double percentage) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * percentage;
  }

  // Get responsive height
  static double getResponsiveHeight(BuildContext context, double percentage) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * percentage;
  }

  // Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final width = screenWidth(context);
    final scale = (width / 375).clamp(0.85, 1.4);
    return baseSize * scale;
  }

  // Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final width = screenWidth(context);
    final scale = (width / 375).clamp(0.9, 1.3);
    return baseRadius * scale;
  }

  // Get responsive card elevation
  static double getResponsiveElevation(BuildContext context, double baseElevation) {
    return baseElevation; // Keep elevation consistent
  }

  // Get responsive grid count
  static int getResponsiveGridCount(BuildContext context, {
    int mobileCount = 2,
    int tabletCount = 3,
    int desktopCount = 4,
  }) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobileCount;
      case ScreenType.tablet:
        return tabletCount;
      case ScreenType.desktop:
        return desktopCount;
    }
  }

  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  // Get screen size info
  static ScreenSizeInfo getScreenSizeInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    return ScreenSizeInfo(
      width: size.width,
      height: size.height,
      devicePixelRatio: devicePixelRatio,
      screenType: getScreenType(context),
    );
  }

  // Responsive Container - prevents overflow
  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Decoration? decoration,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      constraints: BoxConstraints(
        maxWidth: screenWidth(context),
        maxHeight: screenHeight(context),
      ),
      child: child,
    );
  }
}

// Screen type enum
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

// Screen size info class
class ScreenSizeInfo {
  final double width;
  final double height;
  final double devicePixelRatio;
  final ScreenType screenType;

  const ScreenSizeInfo({
    required this.width,
    required this.height,
    required this.devicePixelRatio,
    required this.screenType,
  });

  // Get aspect ratio
  double get aspectRatio => width / height;

  // Check if landscape
  bool get isLandscape => width > height;

  // Check if portrait
  bool get isPortrait => height > width;

  // Get diagonal size in inches (approximate)
  double get diagonalInches {
    final diagonal = (width * width + height * height) / (devicePixelRatio * devicePixelRatio);
    return diagonal / 160; // Approximate conversion
  }

  @override
  String toString() {
    return 'ScreenSizeInfo(width: $width, height: $height, type: $screenType)';
  }
}