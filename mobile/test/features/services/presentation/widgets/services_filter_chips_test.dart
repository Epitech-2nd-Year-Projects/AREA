import 'package:area/features/services/domain/value_objects/service_category.dart';
import 'package:area/features/services/presentation/widgets/services_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  group('ServicesFilterChips', () {
    testWidgets('selects All when no category is chosen', (tester) async {
      await pumpLocalizedWidget(
        tester,
        ServicesFilterChips(
          selectedCategory: null,
          onCategorySelected: (_) {},
        ),
      );

      final FilterChip allChip =
          tester.widget(find.widgetWithText(FilterChip, 'All'));
      expect(allChip.selected, isTrue);
    });

    testWidgets('calls back with selected category', (tester) async {
      ServiceCategory? selected;

      await pumpLocalizedWidget(
        tester,
        ServicesFilterChips(
          selectedCategory: null,
          onCategorySelected: (category) => selected = category,
        ),
      );

      await tester.tap(
        find.widgetWithText(FilterChip, ServiceCategory.social.displayName),
      );
      await tester.pump();

      expect(selected, ServiceCategory.social);
    });
  });
}
