import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/design_system/app_typography.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppTypography', () {
    test('Should have valid text styles', () {
      expect(AppTypography.displayLarge.fontSize, 32);
      expect(AppTypography.displayMedium.fontWeight, FontWeight.w700);
      expect(AppTypography.bodyMedium.fontFamily, 'Inter');
      expect(AppTypography.labelMedium.letterSpacing, 0.01);
    });
  });
}