import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_gate_pass/core/app_theme.dart';

extension MediaQueryValues on BuildContext {
  double get mediaQueryHeight => MediaQuery.sizeOf(this).height;
  double get mediaQueryWidth => MediaQuery.sizeOf(this).width;

  TargetPlatform get os => defaultTargetPlatform;
  void removeCurrentSnackBar() {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
  }

  void showSnackBar(String message, [Color bgColor = AppColors.textPrimary]) {
    if (message.trim().isEmpty) return;
    removeCurrentSnackBar();
    if (!mounted) return;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(
            color: AppColors.surface,
            fontSize: getFontSize(14),
          ),
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 3),
        elevation: 20,
      ),
    );
  }

  // double getFontSize(double size) {
  //   if (isMobile()) {
  //     return (mediaQueryWidth <= 360) ? size - 1 : size;
  //   } else {
  //     return size + 3;
  //   }
  // }
  double getFontSize(double size) {
    final mediaQuery = MediaQuery.of(this);
    final width = mediaQueryWidth;
    final textScaler = mediaQuery.textScaler;

    // Base width for scaling — usually 375 (iPhone 11/13)
    double baseScale = width / 375;
    baseScale = baseScale.clamp(0.85, 1.2);

    return textScaler.scale(size * baseScale);
  }
}
