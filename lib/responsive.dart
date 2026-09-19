import 'package:flutter/material.dart';

import 'app_theme.dart';

abstract final class AppBreakpoints {
  /// Below this width: mobile.
  static const double mobile = 600;

  /// Up to and including this width: tablet. Wider: desktop.
  static const double tablet = 1024;

  /// Widest a page's content is allowed to grow.
  static const double maxContentWidth = 1200;
}

enum ScreenSize {
  mobile,
  tablet,
  desktop;

  static ScreenSize fromWidth(double width) {
    if (width < AppBreakpoints.mobile) return mobile;
    if (width <= AppBreakpoints.tablet) return tablet;
    return desktop;
  }

  bool get isMobile => this == mobile;
  bool get isTablet => this == tablet;
  bool get isDesktop => this == desktop;

  /// Page gutter for this size.
  double get gutter => switch (this) {
    mobile => AppSpacing.xl,
    tablet || desktop => AppSpacing.xxl,
  };
}

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize =>
      ScreenSize.fromWidth(MediaQuery.sizeOf(this).width);

  /// Picks a value by screen size. Unspecified sizes fall back to the next
  /// smaller one.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    return switch (screenSize) {
      ScreenSize.mobile => mobile,
      ScreenSize.tablet => tablet ?? mobile,
      ScreenSize.desktop => desktop ?? tablet ?? mobile,
    };
  }
}

/// Centres page content, caps its width and applies the size's gutter.
class AppContentFrame extends StatelessWidget {
  const AppContentFrame({
    super.key,
    required this.child,
    this.verticalPadding = AppSpacing.xl,
    this.bottomInset = 0,
  });

  final Widget child;
  final double verticalPadding;

  /// Extra space below the content, e.g. to clear a floating action button.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.maxContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.screenSize.gutter,
            verticalPadding,
            context.screenSize.gutter,
            verticalPadding + bottomInset,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A non-scrolling grid whose column count follows the screen size.
/// Meant to sit inside a page that already scrolls.
class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = AppSpacing.lg,
    this.childAspectRatio = 1,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );
    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
