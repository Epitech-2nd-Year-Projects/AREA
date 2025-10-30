import 'package:area/features/auth/presentation/widgets/dialogs/auth_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_app.dart';

void main() {
  testWidgets('AuthConfirmationDialog handles confirm and cancel', (tester) async {
    var confirmed = false;
    var cancelled = false;

    await pumpLocalizedWidget(
      tester,
      Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => AuthConfirmationDialog(
                  title: 'Remove item',
                  message: 'Are you sure?',
                  confirmText: 'Delete',
                  cancelText: 'Nevermind',
                  onConfirm: () => confirmed = true,
                  onCancel: () {
                    cancelled = true;
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
            child: const Text('Open dialog'),
          );
        },
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Remove item'), findsOneWidget);

    await tester.tap(find.text('Nevermind'));
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });
}
