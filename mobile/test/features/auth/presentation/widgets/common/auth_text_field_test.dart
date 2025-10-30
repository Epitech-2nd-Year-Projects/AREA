import 'package:area/features/auth/presentation/widgets/common/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  testWidgets('AuthTextField handles input and visibility toggle', (tester) async {
    final controller = TextEditingController();
    final values = <String>[];

    await pumpLocalizedWidget(
      tester,
      AuthTextField(
        label: 'Password',
        hintText: 'Enter password',
        controller: controller,
        obscureText: true,
        onChanged: values.add,
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'secret123');
    await tester.pump();

    expect(controller.text, 'secret123');
    expect(values, contains('secret123'));

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });
}
