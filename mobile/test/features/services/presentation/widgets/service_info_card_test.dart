import 'package:area/features/services/domain/value_objects/auth_kind.dart';
import 'package:area/features/services/domain/value_objects/service_category.dart';
import 'package:area/features/services/presentation/widgets/service_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  group('ServiceInfoCard', () {
    testWidgets('shows service metadata and authentication info', (tester) async {
      final provider = buildServiceProvider(
        displayName: 'Google Calendar',
        category: ServiceCategory.productivity,
        authKind: AuthKind.oauth2,
      );

      await pumpLocalizedWidget(
        tester,
        ServiceInfoCard(service: provider),
      );

      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text(ServiceCategory.productivity.displayName), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('OAuth 2.0 Required'), findsOneWidget);
      expect(find.text('OAuth'), findsOneWidget);
    });

    testWidgets('indicates inactive status and API key auth', (tester) async {
      final provider = buildServiceProvider(
        displayName: 'Custom API',
        category: ServiceCategory.communication,
        authKind: AuthKind.apikey,
        isEnabled: false,
      );

      await pumpLocalizedWidget(
        tester,
        ServiceInfoCard(service: provider),
      );

      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('API Key Required'), findsOneWidget);
      expect(find.text('API Key'), findsOneWidget);
    });
  });
}
