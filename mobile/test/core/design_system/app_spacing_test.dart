import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/design_system/app_spacing.dart';

void main() {
  group('AppSpacing', () {
    test('constants should have expected values', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
      expect(AppSpacing.xxxl, 64);
    });
  });
}