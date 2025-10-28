import 'package:area/features/dashboard/presentation/widgets/quick_actions_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  testWidgets('QuickActionsRow triggers callbacks for each action', (tester) async {
    var newAreaTapped = false;
    var connectTapped = false;
    var browseTapped = false;

    await pumpLocalizedWidget(
      tester,
      SizedBox(
        width: 640,
        child: QuickActionsRow(
          onNewArea: () => newAreaTapped = true,
          onConnectService: () => connectTapped = true,
          onBrowseTemplates: () => browseTapped = true,
        ),
      ),
    );

    await tester.tap(find.text('New Area'));
    await tester.pump();
    await tester.tap(find.text('Connect a service'));
    await tester.pump();
    await tester.tap(find.text('Browse templates'));
    await tester.pump();

    expect(newAreaTapped, isTrue);
    expect(connectTapped, isTrue);
    expect(browseTapped, isTrue);
  });
}
