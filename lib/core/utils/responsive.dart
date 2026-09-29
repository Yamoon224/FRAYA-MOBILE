library;

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

enum LayoutTier { compact, phone, largePhone, tablet }

extension ResponsiveContextExtensions on BuildContext {
  LayoutTier get layoutTier {
    final width = MediaQuery.sizeOf(this).width;
    if (width < 360) return LayoutTier.compact;
    if (width < 480) return LayoutTier.phone;
    if (width < 840) return LayoutTier.largePhone;
    return LayoutTier.tablet;
  }

  bool get isTablet => layoutTier == LayoutTier.tablet;
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;
  bool get isLandscapePhone => isLandscape && !isTablet;

  double get contentMaxWidth => responsiveValue<double>(
    compact: double.infinity,
    phone: double.infinity,
    largePhone: 640,
    tablet: 760,
  );

  double get contentMaxWidthForOrientation {
    if (isLandscape && layoutTier == LayoutTier.largePhone) return 560;
    if (isLandscape && layoutTier == LayoutTier.phone) return 480;
    return contentMaxWidth;
  }

  double get horizontalPagePadding => responsiveValue<double>(
    compact: 16,
    phone: 20,
    largePhone: 24,
    tablet: 32,
  );

  EdgeInsets get screenPadding =>
      EdgeInsets.symmetric(horizontal: horizontalPagePadding, vertical: 16);

  TextStyle get textH1 => AppTextStyles.h1.copyWith(
    fontSize: responsiveValue<double>(
      compact: 18,
      phone: 20,
      largePhone: 22,
      tablet: 26,
    ),
  );

  TextStyle get textH2 => AppTextStyles.h2.copyWith(
    fontSize: responsiveValue<double>(
      compact: 14,
      phone: 16,
      largePhone: 17,
      tablet: 20,
    ),
  );

  TextStyle get textH3 => AppTextStyles.h3.copyWith(
    fontSize: responsiveValue<double>(
      compact: 13,
      phone: 14,
      largePhone: 15,
      tablet: 18,
    ),
  );

  TextStyle get textBody => AppTextStyles.body.copyWith(
    fontSize: responsiveValue<double>(
      compact: 14,
      phone: 16,
      largePhone: 16,
      tablet: 18,
    ),
  );

  TextStyle get textSmall => AppTextStyles.small.copyWith(
    fontSize: responsiveValue<double>(
      compact: 12,
      phone: 14,
      largePhone: 14,
      tablet: 16,
    ),
  );

  TextStyle get textButton => AppTextStyles.button.copyWith(
    fontSize: responsiveValue<double>(
      compact: 14,
      phone: 16,
      largePhone: 16,
      tablet: 18,
    ),
  );

  TextStyle get textButtonSmall => AppTextStyles.buttonSmall.copyWith(
    fontSize: responsiveValue<double>(
      compact: 12,
      phone: 14,
      largePhone: 14,
      tablet: 16,
    ),
  );

  Widget responsiveBody(Widget child) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: contentMaxWidthForOrientation),
      child: child,
    ),
  );

  EdgeInsets get listViewPadding => EdgeInsets.symmetric(
    horizontal: horizontalPagePadding,
    vertical: 12,
  );

  EdgeInsets get overlayPadding => EdgeInsets.fromLTRB(
    horizontalPagePadding,
    12,
    horizontalPagePadding,
    0,
  );

  T responsiveValue<T>({
    required T compact,
    T? phone,
    T? largePhone,
    T? tablet,
  }) {
    switch (layoutTier) {
      case LayoutTier.compact:
        return compact;
      case LayoutTier.phone:
        return phone ?? compact;
      case LayoutTier.largePhone:
        return largePhone ?? phone ?? compact;
      case LayoutTier.tablet:
        return tablet ?? largePhone ?? phone ?? compact;
    }
  }
}
